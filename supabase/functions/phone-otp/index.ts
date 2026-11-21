// phone-otp — real SMS OTP through the owner's httpSMS gateway.
//
// Two actions, both unauthenticated by design (registration happens
// before a session exists):
//   { action: 'send',   phone, purpose }  -> sends a 6-digit code
//   { action: 'verify', phone, purpose, code } -> { ok: true }
//
// Only the HASH is stored (phone_otps, migration 023); the code
// itself never touches the database or any log. Rate limits are
// enforced server-side: 60s between sends, 5 sends/24h per phone,
// 5 wrong guesses per code, 5-minute expiry.
//
// Secrets (never in code): HTTPSMS_API_KEY, HTTPSMS_FROM_NUMBER,
// OTP_PEPPER. The app never sees the key.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/// Digits only, with the Bangladesh country code applied.
function normalisePhone(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  let d = raw.replace(/[^0-9]/g, '');
  if (d.startsWith('880')) d = d.slice(3);
  else if (d.startsWith('88')) d = d.slice(2);
  d = d.replace(/^0+/, '');
  if (d.length !== 10) return null; // 1XXXXXXXXX (BD mobile)
  return '+880' + d;
}

function toHex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function hashOtp(pepper: string, phone: string, code: string) {
  const data = new TextEncoder().encode(`${pepper}:${phone}:${code}`);
  return toHex(await crypto.subtle.digest('SHA-256', data));
}

function sixDigits(): string {
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  return String(buf[0] % 1000000).padStart(6, '0');
}

function purposeOf(raw: unknown): 'register' | 'login' | 'reset' {
  return raw === 'login' || raw === 'reset' ? raw : 'register';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') return json({ error: 'POST only' }, 405);

  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const apiKey = Deno.env.get('HTTPSMS_API_KEY');
  const fromNumber = Deno.env.get('HTTPSMS_FROM_NUMBER');
  const pepper = Deno.env.get('OTP_PEPPER') ?? 'ys-otp-v1';
  if (!url || !serviceKey) return json({ error: 'not-configured' }, 500);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'bad-request' }, 400);
  }

  const action = body.action;
  const phone = normalisePhone(body.phone);
  if (phone == null) return json({ error: 'bad-phone' }, 400);
  const purpose = purposeOf(body.purpose);
  const db = createClient(url, serviceKey);

  if (action === 'send') {
    if (!apiKey || !fromNumber) {
      return json({ error: 'sms-not-configured' }, 503);
    }
    // 60s cooldown.
    const { data: recent, error: recentErr } = await db
      .from('phone_otps')
      .select('created_at')
      .eq('phone', phone)
      .order('created_at', { ascending: false })
      .limit(1);
    if (recentErr) return json({ error: 'query-failed' }, 500);
    const last = recent?.[0]?.created_at;
    if (last) {
      const age = Date.now() - new Date(String(last)).getTime();
      if (age < 60_000) {
        return json({ error: 'cooldown', retryAfter: Math.ceil((60_000 - age) / 1000) }, 429);
      }
    }
    // 5 sends per phone per 24h.
    const since = new Date(Date.now() - 24 * 3600_000).toISOString();
    const { count, error: countErr } = await db
      .from('phone_otps')
      .select('id', { count: 'exact', head: true })
      .eq('phone', phone)
      .gte('created_at', since);
    if (countErr) return json({ error: 'query-failed' }, 500);
    if ((count ?? 0) >= 5) return json({ error: 'daily-limit' }, 429);

    const code = sixDigits();
    const otpHash = await hashOtp(pepper, phone, code);
    const expiresAt = new Date(Date.now() + 5 * 60_000).toISOString();
    // Housekeeping: expired rows for this phone are useless.
    await db.from('phone_otps').delete().eq('phone', phone).lt('expires_at', new Date().toISOString());
    const ins = await db.from('phone_otps').insert({
      phone,
      otp_hash: otpHash,
      purpose,
      expires_at: expiresAt,
    });
    if (ins.error) return json({ error: 'query-failed' }, 500);

    const sms = await fetch('https://api.httpsms.com/v1/messages/send', {
      method: 'POST',
      headers: { 'x-api-key': apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        content: `Yes Sir AI verification code: ${code}. It expires in 5 minutes. Do not share it. / যাচাই কোড: ${code} (৫ মিনিট)।`,
        from: fromNumber,
        to: phone,
      }),
    });
    if (!sms.ok) {
      // The row must not survive a send that never happened.
      await db.from('phone_otps').delete().eq('otp_hash', otpHash);
      return json({ error: 'sms-failed', status: sms.status }, 502);
    }
    return json({ ok: true, expiresIn: 300 });
  }

  if (action === 'verify') {
    const code = typeof body.code === 'string' ? body.code.trim() : '';
    if (!/^[0-9]{6}$/.test(code)) return json({ error: 'bad-code' }, 400);
    const { data: rows, error } = await db
      .from('phone_otps')
      .select('id, otp_hash, attempts, expires_at')
      .eq('phone', phone)
      .eq('purpose', purpose)
      .order('created_at', { ascending: false })
      .limit(1);
    if (error) return json({ error: 'query-failed' }, 500);
    const row = rows?.[0];
    if (!row) return json({ ok: false, error: 'expired' }, 400);
    if (new Date(String(row.expires_at)).getTime() < Date.now()) {
      await db.from('phone_otps').delete().eq('id', row.id);
      return json({ ok: false, error: 'expired' }, 400);
    }
    if (Number(row.attempts) >= 5) {
      await db.from('phone_otps').delete().eq('id', row.id);
      return json({ ok: false, error: 'too-many' }, 429);
    }
    const expected = await hashOtp(pepper, phone, code);
    if (expected !== String(row.otp_hash)) {
      const next = Number(row.attempts) + 1;
      await db.from('phone_otps').update({ attempts: next }).eq('id', row.id);
      if (next >= 5) await db.from('phone_otps').delete().eq('id', row.id);
      return json({ ok: false, error: 'wrong', attemptsLeft: 5 - next }, 400);
    }
    await db.from('phone_otps').delete().eq('phone', phone).eq('purpose', purpose);
    return json({ ok: true });
  }

  return json({ error: 'bad-request' }, 400);
});

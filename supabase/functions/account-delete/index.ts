// account-delete — deletes the CALLING user's account (Play User Data
// policy). Auth: the platform verify_jwt gate plus a real session check
// here; the service role performs the delete. Profile/progress rows
// cascade from auth.users via their FKs. No secret is logged.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function jwtRole(token: string): string | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  try {
    const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
    const payload = JSON.parse(atob(padded)) as Record<string, unknown>;
    return typeof payload.role === 'string' ? payload.role : null;
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') return json({ error: 'POST only' }, 405);
  const origin = req.headers.get('origin');
  const allowedOrigins = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s !== '');
  if (origin && allowedOrigins.length > 0 && !allowedOrigins.includes(origin)) {
    return new Response('forbidden', { status: 403, headers: corsHeaders });
  }
  const token = (req.headers.get('Authorization') ?? '')
    .replace(/^Bearer\s+/i, '')
    .trim();
  if (!token) return json({ error: 'Authorization required' }, 401);
  if (jwtRole(token) === 'anon') return json({ error: 'sign-in-required' }, 401);
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceKey) {
    return json({ error: 'Function is not configured' }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });
  const { data: authData, error: authError } = await supabase.auth.getUser(
    token,
  );
  if (authError || !authData.user) {
    return json({ error: 'invalid-session' }, 401);
  }
  // Body must explicitly confirm; a stray POST can never delete.
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }
  if (body.confirm !== true) {
    return json({ error: 'confirm-required' }, 400);
  }
  const { error: delError } = await supabase.auth.admin.deleteUser(
    authData.user.id,
  );
  if (delError) return json({ error: 'delete-failed' }, 500);
  return json({ deleted: true });
});

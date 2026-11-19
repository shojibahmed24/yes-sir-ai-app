// Gemini path for Mode GEN (explain-question Edge Function).
//
// Kept separate from index.ts on purpose: the OpenRouter branch
// there stays untouched, and this file owns only the Gemini
// request/response mapping. The client never calls Gemini
// directly and never holds the key: index.ts reads the
// GEMINI_API_KEY function secret (server-side only) and passes
// it here through the env getter. The key is NEVER logged,
// NEVER echoed in an error body, and NEVER returned.
//
// Models: gemini-3.8-flash first. On HTTP 429 or 503 only, retry ONCE
// with gemini-3.5-flash-lite, then give up. Any other upstream
// failure (other status, bad JSON, network error) is a single
// 502 'gemini-failed' with no upstream detail leaked.
//
// Mapping: systemPrompt -> system_instruction.parts, userPrompt
// -> contents[0] (role 'user'). The reply text is the joined
// text parts of candidates[0].content.parts, and the body also
// carries attribution: { generated: true, text,
// provider: 'gemini', model } where model is the model that
// ACTUALLY answered (primary or fallback). The client must
// show this, never the provider the user merely selected:
// a stale Edge deploy that ignores `provider` still answers
// via OpenRouter, and only its response can say so.
// Missing secret => 500 'gemini-key-missing' (same honest-error
// pattern as OpenRouter's 'openrouter-key-missing'), with
// provider: 'gemini' attached; upstream failure => 502
// 'gemini-failed', also with provider: 'gemini'.
//
// Testability: no Deno import and no Supabase import here, so
// the function takes its env getter and fetch implementation
// as arguments. index.ts passes Deno.env and global fetch;
// tests pass fakes. No key, token or password is stored here.

export const geminiModels = [
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
] as const;

export type GeminiEnv = {
  get: (key: string) => string | undefined;
};

export type GeminiResult = {
  status: number;
  body: Record<string, unknown>;
};

type GeminiPart = { text?: unknown };
type GeminiCandidate = { content?: { parts?: GeminiPart[] } };
type GeminiResponse = { candidates?: GeminiCandidate[] };

function extractText(data: unknown): string {
  const res = data as GeminiResponse | null;
  const candidates = res?.candidates;
  if (!candidates || candidates.length === 0) return '';
  const parts = candidates[0].content?.parts ?? [];
  let out = '';
  for (const part of parts) {
    if (typeof part.text === 'string') out += part.text;
  }
  return out;
}

async function callGeminiModel(
  model: string,
  systemPrompt: string,
  userPrompt: string,
  apiKey: string,
  fetchFn: typeof fetch,
): Promise<{ status: number; text: string } | { failed: true }> {
  let res: Response;
  try {
    res = await fetchFn(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: systemPrompt }] },
          contents: [{ role: 'user', parts: [{ text: userPrompt }] }],
        }),
      },
    );
  } catch {
    return { failed: true };
  }
  if (res.status === 429) return { status: 429, text: '' };
  if (!res.ok) return { status: res.status, text: '' };
  let data: unknown;
  try {
    data = await res.json();
  } catch {
    return { failed: true };
  }
  return { status: 200, text: extractText(data) };
}

/// Run one Gemini generation. Returns an HTTP status + body in
/// the same shape index.ts returns for Mode GEN.
export async function generateWithGemini(
  systemPrompt: string,
  userPrompt: string,
  env: GeminiEnv,
  fetchFn: typeof fetch = fetch,
): Promise<GeminiResult> {
  const apiKey = env.get('GEMINI_API_KEY');
  if (!apiKey) {
    return {
      status: 500,
      body: { error: 'gemini-key-missing', provider: 'gemini' },
    };
  }
  const first = await callGeminiModel(
    geminiModels[0],
    systemPrompt,
    userPrompt,
    apiKey,
    fetchFn,
  );
  if (!('failed' in first) && first.status === 200) {
    return {
      status: 200,
      body: {
        generated: true,
        text: first.text,
        provider: 'gemini',
        model: geminiModels[0],
      },
    };
  }
  // 429 or 503 on the primary model: one fallback attempt.
  // 503 is Google's per-model overload signal (documented remedy:
  // retry + fall back to another model); without this, a saturated
  // primary fails outright even when the fallback has capacity.
  // upstreamStatus is diagnostic only (an HTTP status number or
  // 'network'); it never carries the key or the error body.
  let upstreamStatus: number | 'network' =
    'failed' in first ? 'network' : first.status;
  if (
    !('failed' in first) && (first.status === 429 || first.status === 503)
  ) {
    const fallback = await callGeminiModel(
      geminiModels[1],
      systemPrompt,
      userPrompt,
      apiKey,
      fetchFn,
    );
    if (!('failed' in fallback) && fallback.status === 200) {
      return {
        status: 200,
        body: {
          generated: true,
          text: fallback.text,
          provider: 'gemini',
          model: geminiModels[1],
        },
      };
    }
    upstreamStatus = 'failed' in fallback ? 'network' : fallback.status;
  }
  return {
    status: 502,
    body: { error: 'gemini-failed', provider: 'gemini', upstreamStatus },
  };
}

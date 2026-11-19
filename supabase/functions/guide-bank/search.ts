// Pure helpers for the guide-bank `search` action (whole-guide,
// server-side search). Kept import-free so search.test.ts runs
// fully offline under `deno test`, no live DB needed.
//
// PAYLOAD SAFETY (same as `list`): a shaped row carries id,
// questionText, questionType, options, marks, chapterNumber,
// hasKey and guideError — NEVER answer_key, NEVER
// guide_solution. Options are QUESTION CONTENT (as in `list`),
// not a key: hasKey is the only key-related field, a boolean.

const BENGALI_OPTION_ORDER = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];

export function optionsToArray(raw: unknown): string[] {
  if (Array.isArray(raw)) {
    return raw.map((e) => String(e));
  }
  if (raw !== null && typeof raw === 'object') {
    const obj = raw as Record<string, unknown>;
    const ordered: string[] = [];
    for (const key of BENGALI_OPTION_ORDER) {
      if (typeof obj[key] === 'string') ordered.push(obj[key] as string);
    }
    if (ordered.length > 0) return ordered;
    return Object.values(obj).map((e) => String(e));
  }
  return [];
}

/// Escape LIKE wildcards so a user's query is matched literally:
/// `%` and `_` in the query must not act as wildcards, and a
/// literal backslash must not escape the next character.
/// Postgres LIKE treats backslash as the default escape
/// character, so these escapes survive the PostgREST ilike call.
export function escapeLikePattern(query: string): string {
  return query
    .replace(/\\/g, '\\\\')
    .replace(/%/g, '\\%')
    .replace(/_/g, '\\_');
}

/// Search page size: default 50, clamped to 1..50 server-side.
/// A search never dumps the whole guide — 50 rows maximum.
export function clampSearchLimit(raw: unknown): number {
  if (typeof raw === 'number' && Number.isInteger(raw)) {
    return Math.min(Math.max(raw, 1), 50);
  }
  return 50;
}

export type SearchRow = Record<string, unknown>;

/// Shape one DB row into the safe client payload. Any key or
/// solution column present on the row is dropped here, never
/// copied through — the returned object has no such keys.
export function shapeSearchRow(
  r: SearchRow,
  guideErrorKnown: boolean,
): Record<string, unknown> {
  const key = r.answer_key as string | null;
  return {
    id: r.id as string,
    questionText: r.question_text as string,
    questionType: r.question_type as string,
    options: optionsToArray(r.options),
    marks: (r.marks as number | null) ?? null,
    chapterNumber: (r.chapter_number as number | null) ?? null,
    // Creative part marks, raw (object or list; the app normalises
    // it). null when absent, and on the pre-migration retry path
    // where marks_parts is not selected.
    marksParts: (r.marks_parts as unknown) ?? null,
    // The ONLY key-related field: a boolean, never the key.
    hasKey: key !== null && key !== '',
    guideError: guideErrorKnown
      ? (r.guide_error as boolean | null) ?? false
      : false,
  };
}

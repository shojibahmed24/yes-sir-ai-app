// Exact per-lesson counts for the guide-bank `guideLessons` action.
//
// WHY THIS EXISTS: chapter-less books (Bangla 1st Paper) have no
// chapter numbers to browse by — their rows are tagged by lesson
// (guide_questions.lesson, migration 013). The app's lesson picker
// needs the distinct lesson values with exact counts, and the same
// PostgREST max-rows trap applies as for chapters: grouping a
// capped row fetch would give sample counts, not true totals.
// This module mirrors chapters.ts: it pages lesson values to learn
// the distinct lessons, then asks PostgREST for one exact
// head-count per lesson (total + keyed). Counts are exact at any
// guide size. Bank rows only (set_id NULL), like guideChapters.
//
// GROUPING IS VERBATIM: a lesson value groups under its exact
// stored string (no trim). The app sends the returned string back
// as the list lesson filter, and the list .eq() matches it
// exactly — trimming here would merge values the list filter
// cannot reproduce with a single equality. NULL and blank
// (empty/whitespace-only) values carry no lesson and are
// excluded, matching normalizeListLesson (blank = no filter).
// ORDER: book order is not stored, so lessons sort in code-unit
// order (JS default string sort) — documented, not meaningful.
//
// TESTABILITY: the Supabase calls arrive as injected closures,
// so `deno test` proves the logic offline — including a mocked
// dataset larger than 1000 rows. Only relative imports here,
// like chapters.ts.

export type LessonPage = {
  data: { lesson: unknown }[] | null;
  error: { code?: string } | null;
};

export type LessonCount = {
  count: number | null;
  error: { code?: string } | null;
};

export type LessonCountsDeps = {
  fetchLessonPage: (from: number, to: number) => Promise<LessonPage>;
  countTotal: (lesson: string) => Promise<LessonCount>;
  countKeyed: (lesson: string) => Promise<LessonCount>;
};

export type LessonCountEntry = {
  lesson: string;
  totalCount: number;
  keyedCount: number;
};

export type NativeLessonCounts =
  | { kind: "ok"; lessons: LessonCountEntry[] }
  | { kind: "fallback" } // lesson column missing (42703)
  | { kind: "missing-table" } // 42P01
  | { kind: "failed" };

// PostgREST max-rows per response. Paging in units of this size
// is what makes the distinct-lesson scan exact, not capped.
export const LESSON_PAGE_SIZE = 1000;

// Safety cap: 100 pages = 100k rows, far above any real subject
// guide. Hitting it returns an honest failure, never a partial
// (wrong) count set.
const MAX_PAGES = 100;

// Pure: non-blank string lessons only, deduped, code-unit order.
// Non-strings, nulls and blank strings are ignored, never crash.
export function distinctSortedLessons(values: unknown[]): string[] {
  const seen = new Set<string>();
  for (const v of values) {
    if (typeof v === "string" && v.trim() !== "") seen.add(v);
  }
  return [...seen].sort();
}

export function shapeLessonCounts(
  entries: { lesson: string; total: number; keyed: number }[],
): LessonCountEntry[] {
  return [...entries]
    .sort((a, b) => (a.lesson < b.lesson ? -1 : a.lesson > b.lesson ? 1 : 0))
    .map((e) => ({
      lesson: e.lesson,
      totalCount: e.total,
      keyedCount: e.keyed,
    }));
}

type PageCollect =
  | { ok: true; lessons: string[] }
  | { ok: false; code?: string };

async function collectDistinctLessons(
  fetchPage: LessonCountsDeps["fetchLessonPage"],
): Promise<PageCollect> {
  const seen = new Set<string>();
  for (let page = 0; page < MAX_PAGES; page++) {
    const from = page * LESSON_PAGE_SIZE;
    const to = from + LESSON_PAGE_SIZE - 1;
    const res = await fetchPage(from, to);
    if (res.error) return { ok: false, code: res.error.code };
    const rows = res.data ?? [];
    for (const r of rows) {
      const v = (r as { lesson?: unknown }).lesson;
      if (typeof v === "string" && v.trim() !== "") seen.add(v);
    }
    if (rows.length < LESSON_PAGE_SIZE) {
      return { ok: true, lessons: [...seen].sort() };
    }
  }
  return { ok: false }; // page cap hit: refuse a partial answer
}

// Orchestrator: distinct lessons first, then one exact
// head-count per lesson (total + keyed), all in parallel.
// Any failure maps to an honest outcome — never a wrong count.
export async function fetchNativeGuideLessonCounts(
  deps: LessonCountsDeps,
): Promise<NativeLessonCounts> {
  const collected = await collectDistinctLessons(deps.fetchLessonPage);
  if (!collected.ok) {
    if (collected.code === "42703") return { kind: "fallback" };
    if (collected.code === "42P01") return { kind: "missing-table" };
    return { kind: "failed" };
  }
  if (collected.lessons.length === 0) {
    return { kind: "ok", lessons: [] };
  }
  const counted = await Promise.all(
    collected.lessons.map(async (lesson) => {
      const total = await deps.countTotal(lesson);
      const keyed = await deps.countKeyed(lesson);
      return { lesson, total, keyed };
    }),
  );
  for (const c of counted) {
    if (
      c.total.error?.code === "42P01" || c.keyed.error?.code === "42P01"
    ) {
      return { kind: "missing-table" };
    }
    if (
      c.total.error || c.keyed.error ||
      typeof c.total.count !== "number" ||
      typeof c.keyed.count !== "number"
    ) {
      return { kind: "failed" };
    }
  }
  return {
    kind: "ok",
    lessons: shapeLessonCounts(
      counted.map((c) => ({
        lesson: c.lesson,
        total: c.total.count as number,
        keyed: c.keyed.count as number,
      })),
    ),
  };
}

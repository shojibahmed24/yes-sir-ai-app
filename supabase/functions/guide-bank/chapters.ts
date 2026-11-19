// Exact per-chapter counts for the guide-bank `guideChapters` action.
//
// WHY THIS EXISTS: the old code fetched guide rows (limit 5000)
// and grouped them in JS, but PostgREST max-rows clamps every
// response to 1000 rows, so totals were sample counts (class 9
// math summed to exactly 1000), not true totals. This module
// never groups a row fetch: it pages chapter_number values to
// learn the distinct chapters, then asks PostgREST for one exact
// head-count per chapter (total + keyed). Counts are exact at
// any guide size. No DB migration, no client change: only this
// function changes. The pre-migration fallback (chapter_number
// absent) stays in index.ts, untouched.
//
// TESTABILITY: the Supabase calls arrive as injected closures,
// so `deno test` proves the logic offline — including a mocked
// dataset larger than 1000 rows, which is exactly the case the
// old code got wrong. Only relative imports here, like search.ts.

export type ChapterNumberPage = {
  data: { chapter_number: unknown }[] | null;
  error: { code?: string } | null;
};

export type ChapterCount = {
  count: number | null;
  error: { code?: string } | null;
};

export type ChapterCountsDeps = {
  fetchChapterNumberPage: (
    from: number,
    to: number,
  ) => Promise<ChapterNumberPage>;
  countTotal: (chapter: number) => Promise<ChapterCount>;
  countKeyed: (chapter: number) => Promise<ChapterCount>;
};

export type ChapterCountEntry = {
  chapter: number;
  totalCount: number;
  keyedCount: number;
};

export type NativeChapterCounts =
  | { kind: "ok"; chapters: ChapterCountEntry[] }
  | { kind: "fallback" } // chapter_number column missing (42703)
  | { kind: "missing-table" } // 42P01
  | { kind: "failed" };

// PostgREST max-rows per response. Paging in units of this size
// is what makes the distinct-chapter scan exact, not capped.
export const CHAPTER_NUMBER_PAGE_SIZE = 1000;

// Safety cap: 100 pages = 100k rows, far above any real subject
// guide. Hitting it returns an honest failure, never a partial
// (wrong) count set.
const MAX_PAGES = 100;

// Pure: finite integer chapter numbers only, deduped, ascending.
// Non-numbers, nulls, NaN and fractions are ignored, never crash.
export function distinctSortedChapterNumbers(
  values: unknown[],
): number[] {
  const seen = new Set<number>();
  for (const v of values) {
    if (typeof v === "number" && Number.isInteger(v)) seen.add(v);
  }
  return [...seen].sort((a, b) => a - b);
}

export function shapeChapterCounts(
  entries: { chapter: number; total: number; keyed: number }[],
): ChapterCountEntry[] {
  return [...entries]
    .sort((a, b) => a.chapter - b.chapter)
    .map((e) => ({
      chapter: e.chapter,
      totalCount: e.total,
      keyedCount: e.keyed,
    }));
}

type PageCollect =
  | { ok: true; numbers: number[] }
  | { ok: false; code?: string };

async function collectDistinctChapterNumbers(
  fetchPage: ChapterCountsDeps["fetchChapterNumberPage"],
): Promise<PageCollect> {
  const seen = new Set<number>();
  for (let page = 0; page < MAX_PAGES; page++) {
    const from = page * CHAPTER_NUMBER_PAGE_SIZE;
    const to = from + CHAPTER_NUMBER_PAGE_SIZE - 1;
    const res = await fetchPage(from, to);
    if (res.error) return { ok: false, code: res.error.code };
    const rows = res.data ?? [];
    for (const r of rows) {
      const n = (r as { chapter_number?: unknown }).chapter_number;
      if (typeof n === "number" && Number.isInteger(n)) seen.add(n);
    }
    if (rows.length < CHAPTER_NUMBER_PAGE_SIZE) {
      return { ok: true, numbers: [...seen].sort((a, b) => a - b) };
    }
  }
  return { ok: false }; // page cap hit: refuse a partial answer
}

// Orchestrator: distinct chapters first, then one exact
// head-count per chapter (total + keyed), all in parallel.
// Any failure maps to an honest outcome — never a wrong count.
export async function fetchNativeGuideChapterCounts(
  deps: ChapterCountsDeps,
): Promise<NativeChapterCounts> {
  const collected = await collectDistinctChapterNumbers(
    deps.fetchChapterNumberPage,
  );
  if (!collected.ok) {
    if (collected.code === "42703") return { kind: "fallback" };
    if (collected.code === "42P01") return { kind: "missing-table" };
    return { kind: "failed" };
  }
  if (collected.numbers.length === 0) {
    return { kind: "ok", chapters: [] };
  }
  const counted = await Promise.all(
    collected.numbers.map(async (chapter) => {
      const total = await deps.countTotal(chapter);
      const keyed = await deps.countKeyed(chapter);
      return { chapter, total, keyed };
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
    chapters: shapeChapterCounts(
      counted.map((c) => ({
        chapter: c.chapter,
        total: c.total.count as number,
        keyed: c.keyed.count as number,
      })),
    ),
  };
}

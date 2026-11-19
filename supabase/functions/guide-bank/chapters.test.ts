// Tests for the guide-bank `guideChapters` exact-count helpers.
// No external imports on purpose: `deno test` runs this file
// fully offline (only the relative chapters import), no live DB.
// The key regression test builds a mocked guide larger than the
// 1000-row PostgREST cap — the exact case the old capped-fetch
// grouping got wrong (class 9 math summed to exactly 1000).
import {
  CHAPTER_NUMBER_PAGE_SIZE,
  distinctSortedChapterNumbers,
  fetchNativeGuideChapterCounts,
  shapeChapterCounts,
  type ChapterCountsDeps,
} from "./chapters.ts";

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

// Mock pager over an in-memory chapter_number array. Range is
// inclusive, like PostgREST .range(from, to).
function makePager(values: unknown[]) {
  let calls = 0;
  const fetchPage: ChapterCountsDeps["fetchChapterNumberPage"] = async (
    from,
    to,
  ) => {
    calls++;
    return {
      data: values.slice(from, to + 1).map((chapter_number) => ({
        chapter_number,
      })),
      error: null,
    };
  };
  return { fetchPage, calls: () => calls };
}

function makeCounter(
  totals: Record<number, number>,
  keyed: Record<number, number>,
): Pick<ChapterCountsDeps, "countTotal" | "countKeyed"> {
  return {
    countTotal: async (ch) => ({ count: totals[ch] ?? 0, error: null }),
    countKeyed: async (ch) => ({ count: keyed[ch] ?? 0, error: null }),
  };
}

Deno.test("distinct: filters junk, dedupes, sorts ascending", () => {
  assertEquals(
    distinctSortedChapterNumbers([3, 2, null, 3, "2", 2.5, NaN, 7, 2]),
    [2, 3, 7],
    "distinct",
  );
  assertEquals(distinctSortedChapterNumbers([]), [], "empty");
});

Deno.test("shape: sorts by chapter, renames to total/keyed", () => {
  assertEquals(
    shapeChapterCounts([
      { chapter: 7, total: 10, keyed: 3 },
      { chapter: 2, total: 624, keyed: 300 },
    ]),
    [
      { chapter: 2, totalCount: 624, keyedCount: 300 },
      { chapter: 7, totalCount: 10, keyedCount: 3 },
    ],
    "shape",
  );
});

Deno.test("exact: 3749 mocked rows across 4 pages give true totals", async () => {
  // Mirrors the real class 9 shape (ch2 624 after the 2.1 pilot
  // import) at a scale past the 1000-row cap: the old code
  // would have returned a 1000-row sample here, not these.
  const totals: Record<number, number> = {
    2: 624,
    3: 474,
    7: 430,
    8: 768,
    9: 319,
    11: 235,
    16: 532,
    17: 367,
  };
  const keyed: Record<number, number> = {
    2: 300,
    3: 200,
    7: 150,
    8: 100,
    9: 50,
    11: 40,
    16: 30,
    17: 20,
  };
  const rows: number[] = [];
  for (const ch of [2, 3, 7, 8, 9, 11, 16, 17]) {
    for (let i = 0; i < totals[ch]; i++) rows.push(ch);
  }
  assertEquals(rows.length, 3749, "fixture size");
  assert(
    rows.length > 3 * CHAPTER_NUMBER_PAGE_SIZE,
    "fixture spans 4 pages",
  );
  const pager = makePager(rows);
  const res = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: pager.fetchPage,
    ...makeCounter(totals, keyed),
  });
  assertEquals(res.kind, "ok", "kind");
  if (res.kind === "ok") {
    assertEquals(res.chapters, [
      { chapter: 2, totalCount: 624, keyedCount: 300 },
      { chapter: 3, totalCount: 474, keyedCount: 200 },
      { chapter: 7, totalCount: 430, keyedCount: 150 },
      { chapter: 8, totalCount: 768, keyedCount: 100 },
      { chapter: 9, totalCount: 319, keyedCount: 50 },
      { chapter: 11, totalCount: 235, keyedCount: 40 },
      { chapter: 16, totalCount: 532, keyedCount: 30 },
      { chapter: 17, totalCount: 367, keyedCount: 20 },
    ], "exact totals");
  }
  assertEquals(pager.calls(), 4, "four pages fetched");
});

Deno.test("empty guide: no chapters, ok with empty list", async () => {
  const pager = makePager([]);
  const res = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: pager.fetchPage,
    ...makeCounter({}, {}),
  });
  assertEquals(res, { kind: "ok", chapters: [] }, "empty");
});

Deno.test("nulls in pages are ignored, not chapters", async () => {
  const pager = makePager([2, null, 2, "x", 3, undefined]);
  const res = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: pager.fetchPage,
    ...makeCounter({ 2: 2, 3: 1 }, { 2: 1, 3: 0 }),
  });
  assertEquals(res.kind, "ok", "kind");
  if (res.kind === "ok") {
    assertEquals(res.chapters, [
      { chapter: 2, totalCount: 2, keyedCount: 1 },
      { chapter: 3, totalCount: 1, keyedCount: 0 },
    ], "nulls ignored");
  }
});

Deno.test("42703 on the first page means pre-migration fallback", async () => {
  const res = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: async () => ({
      data: null,
      error: { code: "42703" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(res.kind, "fallback", "fallback");
});

Deno.test("42P01 maps to missing-table, other errors to failed", async () => {
  const missing = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: async () => ({
      data: null,
      error: { code: "42P01" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(missing.kind, "missing-table", "missing table");
  const failed = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: async () => ({
      data: null,
      error: { code: "500" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(failed.kind, "failed", "generic failure");
});

Deno.test("count failure or null count fails honestly, never partial", async () => {
  const pager = makePager([2, 3]);
  const errRes = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: pager.fetchPage,
    countTotal: async () => ({ count: 5, error: null }),
    countKeyed: async () => ({ count: null, error: { code: "500" } }),
  });
  assertEquals(errRes.kind, "failed", "count error");
  const nullRes = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: pager.fetchPage,
    countTotal: async () => ({ count: null, error: null }),
    countKeyed: async () => ({ count: 1, error: null }),
  });
  assertEquals(nullRes.kind, "failed", "null count");
});

Deno.test("endless full pages hit the cap and fail, never loop", async () => {
  let calls = 0;
  const res = await fetchNativeGuideChapterCounts({
    fetchChapterNumberPage: async () => {
      calls++;
      return {
        data: Array.from({ length: CHAPTER_NUMBER_PAGE_SIZE }, () => ({
          chapter_number: 2,
        })),
        error: null,
      };
    },
    ...makeCounter({}, {}),
  });
  assertEquals(res.kind, "failed", "cap failure");
  assert(calls <= 100, "bounded calls");
});

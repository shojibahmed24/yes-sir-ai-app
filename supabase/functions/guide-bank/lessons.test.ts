// Tests for the guide-bank `guideLessons` exact-count helpers.
// No external imports on purpose: `deno test` runs this file
// fully offline (only the relative lessons import), no live DB.
// Mirrors chapters.test.ts, including a mocked guide larger than
// the 1000-row PostgREST cap — the exact case a capped-fetch
// grouping would get wrong.
import {
  distinctSortedLessons,
  fetchNativeGuideLessonCounts,
  LESSON_PAGE_SIZE,
  shapeLessonCounts,
  type LessonCountsDeps,
} from "./lessons.ts";

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

// Mock pager over an in-memory lesson array. Range is
// inclusive, like PostgREST .range(from, to).
function makePager(values: unknown[]) {
  let calls = 0;
  const fetchPage: LessonCountsDeps["fetchLessonPage"] = async (
    from,
    to,
  ) => {
    calls++;
    return {
      data: values.slice(from, to + 1).map((lesson) => ({ lesson })),
      error: null,
    };
  };
  return { fetchPage, calls: () => calls };
}

function makeCounter(
  totals: Record<string, number>,
  keyed: Record<string, number>,
): Pick<LessonCountsDeps, "countTotal" | "countKeyed"> {
  return {
    countTotal: async (l) => ({ count: totals[l] ?? 0, error: null }),
    countKeyed: async (l) => ({ count: keyed[l] ?? 0, error: null }),
  };
}

Deno.test("distinct: filters junk, dedupes, sorts code-unit order", () => {
  assertEquals(
    distinctSortedLessons([
      "গ",
      "ক",
      null,
      "গ",
      "",
      "   ",
      3,
      undefined,
      "খ",
    ]),
    ["ক", "খ", "গ"],
    "distinct",
  );
  assertEquals(distinctSortedLessons([]), [], "empty");
});

Deno.test("distinct: verbatim grouping keeps spaced variants apart", () => {
  // The list filter is an exact .eq(), so 'ক' and ' ক ' are
  // different filters; grouping must not merge them.
  assertEquals(
    distinctSortedLessons([" ক ", "ক"]),
    [" ক ", "ক"],
    "verbatim",
  );
});

Deno.test("shape: sorts by lesson, renames to total/keyed", () => {
  assertEquals(
    shapeLessonCounts([
      { lesson: "গ", total: 10, keyed: 3 },
      { lesson: "ক", total: 624, keyed: 300 },
    ]),
    [
      { lesson: "ক", totalCount: 624, keyedCount: 300 },
      { lesson: "গ", totalCount: 10, keyedCount: 3 },
    ],
    "shape",
  );
});

Deno.test("exact: 2400 mocked rows across 3 pages give true totals", async () => {
  const totals: Record<string, number> = {
    "একুশের গল্প": 1200,
    "সাহিত্যের রূপ": 800,
    "কবিতা": 400,
  };
  const keyed: Record<string, number> = {
    "একুশের গল্প": 900,
    "সাহিত্যের রূপ": 100,
    "কবিতা": 0,
  };
  const rows: string[] = [];
  for (const l of ["একুশের গল্প", "সাহিত্যের রূপ", "কবিতা"]) {
    for (let i = 0; i < totals[l]; i++) rows.push(l);
  }
  assertEquals(rows.length, 2400, "fixture size");
  assert(rows.length > 2 * LESSON_PAGE_SIZE, "fixture spans 3 pages");
  const pager = makePager(rows);
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    ...makeCounter(totals, keyed),
  });
  assertEquals(res.kind, "ok", "kind");
  if (res.kind === "ok") {
    assertEquals(res.lessons, [
      { lesson: "একুশের গল্প", totalCount: 1200, keyedCount: 900 },
      { lesson: "কবিতা", totalCount: 400, keyedCount: 0 },
      { lesson: "সাহিত্যের রূপ", totalCount: 800, keyedCount: 100 },
    ], "exact totals");
  }
  assertEquals(pager.calls(), 3, "three pages fetched");
});

Deno.test("empty guide: no lessons, ok with empty list", async () => {
  const pager = makePager([]);
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    ...makeCounter({}, {}),
  });
  assertEquals(res, { kind: "ok", lessons: [] }, "empty");
});

// Bangla chapter mapping (2026-11-02): Bangla guide rows carry
// no chapter_number, so the app's chapter picker surfaces the
// lessons themselves as chapter entries. This test pins the
// server side of that mapping: a chapter-less book still yields
// its lessons as browsable entries, with no chapter number
// involved anywhere in the lessons path.
Deno.test("chapter-less book: lessons listed as browsable entries", async () => {
  const pager = makePager(["পাঠ-ক", "পাঠ-খ", "পাঠ-ক"]);
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    ...makeCounter({ "পাঠ-ক": 2, "পাঠ-খ": 1 }, { "পাঠ-ক": 1, "পাঠ-খ": 0 }),
  });
  assertEquals(res.kind, "ok", "kind");
  if (res.kind === "ok") {
    assertEquals(res.lessons, [
      { lesson: "পাঠ-ক", totalCount: 2, keyedCount: 1 },
      { lesson: "পাঠ-খ", totalCount: 1, keyedCount: 0 },
    ], "lessons are the chapter entries");
  }
});

Deno.test("nulls and blanks in pages are ignored, not lessons", async () => {
  const pager = makePager(["ক", null, "ক", "", "   ", "খ", undefined]);
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    ...makeCounter({ "ক": 2, "খ": 1 }, { "ক": 1, "খ": 0 }),
  });
  assertEquals(res.kind, "ok", "kind");
  if (res.kind === "ok") {
    assertEquals(res.lessons, [
      { lesson: "ক", totalCount: 2, keyedCount: 1 },
      { lesson: "খ", totalCount: 1, keyedCount: 0 },
    ], "nulls ignored");
  }
});

Deno.test("42703 on the first page means pre-migration fallback", async () => {
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: async () => ({
      data: null,
      error: { code: "42703" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(res.kind, "fallback", "fallback");
});

Deno.test("42P01 maps to missing-table, other errors to failed", async () => {
  const missing = await fetchNativeGuideLessonCounts({
    fetchLessonPage: async () => ({
      data: null,
      error: { code: "42P01" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(missing.kind, "missing-table", "missing table");
  const failed = await fetchNativeGuideLessonCounts({
    fetchLessonPage: async () => ({
      data: null,
      error: { code: "500" },
    }),
    ...makeCounter({}, {}),
  });
  assertEquals(failed.kind, "failed", "generic failure");
});

Deno.test("count failure or null count fails honestly, never partial", async () => {
  const pager = makePager(["ক", "খ"]);
  const errRes = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    countTotal: async () => ({ count: 5, error: null }),
    countKeyed: async () => ({ count: null, error: { code: "500" } }),
  });
  assertEquals(errRes.kind, "failed", "count error");
  const nullRes = await fetchNativeGuideLessonCounts({
    fetchLessonPage: pager.fetchPage,
    countTotal: async () => ({ count: null, error: null }),
    countKeyed: async () => ({ count: 1, error: null }),
  });
  assertEquals(nullRes.kind, "failed", "null count");
});

Deno.test("endless full pages hit the cap and fail, never loop", async () => {
  let calls = 0;
  const res = await fetchNativeGuideLessonCounts({
    fetchLessonPage: async () => {
      calls++;
      return {
        data: Array.from({ length: LESSON_PAGE_SIZE }, () => ({
          lesson: "ক",
        })),
        error: null,
      };
    },
    ...makeCounter({}, {}),
  });
  assertEquals(res.kind, "failed", "cap failure");
  assert(calls <= 100, "bounded calls");
});

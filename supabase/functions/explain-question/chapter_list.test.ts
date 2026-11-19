// Tests for the second-step chapter list (2026-10-30):
// listByChapter + by-question-id handlers in chapter_list.ts.
// Offline on purpose: no supabase-js import, only the relative
// chapter_list import — same pattern as grounding.test.ts.
// The fakes implement the ChapterListDb surface with canned rows.

import {
  type BookRow,
  type ChapterListDb,
  type ChapterRow,
  type GroundedChunk,
  type ListQueryResult,
  type QuestionRow,
  handleByQuestionId,
  handleListByChapter,
  sortQuestions,
  toListItem,
} from "./chapter_list.ts";

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

const BOOK: BookRow = { id: "class6-math-bn", title: "Math BN" };
const CHAPTER: ChapterRow = { id: "class6-math-bn-ch3", number: 3, title: "Ch3" };

// Deliberately UNSORTED, with a null-problem row, to prove the
// handler sorts (page asc, problem asc, nulls last) itself.
function listRows(): QuestionRow[] {
  return [
    { id: "q3", page: 45, problem: null, questionText: "unnumbered", questionType: "short" },
    { id: "q1", page: 45, problem: 2, questionText: "second", questionType: "mcq" },
    { id: "q2", page: 44, problem: 5, questionText: "earlier page", questionType: null },
    { id: "q0", page: 45, problem: 1, questionText: "first", questionType: "creative" },
  ];
}

function makeDb(opts: {
  book?: BookRow | null;
  chapter?: ChapterRow | null;
  rows?: QuestionRow[] | null;
  // First withType=true call fails with this code ('' = no error).
  listErrorCode?: string;
  byId?: { row: QuestionRow; book: BookRow; chapter: ChapterRow | null } | null;
  chunks?: GroundedChunk[];
  seenFetch?: { bookId: string; chapterId: string | null; page: number }[];
} = {}): ChapterListDb {
  const rows = opts.rows === undefined ? listRows() : opts.rows;
  return {
    findBook: async () => opts.book === undefined ? BOOK : opts.book,
    findChapter: async () => opts.chapter === undefined ? CHAPTER : opts.chapter,
    listQuestions: async (_b, _c, withType) => {
      if (withType && opts.listErrorCode) {
        return { errorCode: opts.listErrorCode } as ListQueryResult;
      }
      // Pre-009 retry path: rows arrive WITHOUT question_type.
      const out = (rows ?? []).map((r) => withType ? r : { ...r, questionType: undefined });
      return { rows: out };
    },
    findQuestionById: async (id) => {
      if (opts.byId !== undefined) return opts.byId;
      const row = (rows ?? []).find((r) => r.id === id);
      if (!row) return null;
      return { row, book: BOOK, chapter: CHAPTER };
    },
    fetchChunks: async (bookId, chapterId, page) => {
      opts.seenFetch?.push({ bookId, chapterId, page });
      return opts.chunks ?? [];
    },
  };
}

const LIST_INPUT = { subject: "math", classId: 6, chapter: 3, language: "bn" };
const FORBIDDEN = ["chunk", "chunks", "solution", "answer", "key", "answerKey"];

Deno.test("list response shape: exactly the five public fields, nothing else", async () => {
  const res = await handleListByChapter(makeDb(), LIST_INPUT);
  assertEquals(res.status, 200, "status");
  const body = res.body as Record<string, unknown>;
  assertEquals(body.found, true, "found");
  assertEquals(body.bookId, "class6-math-bn", "bookId");
  assertEquals(body.bookTitle, "Math BN", "bookTitle");
  assertEquals(body.language, "bn", "language");
  assertEquals(body.chapterNumber, 3, "chapterNumber");
  assertEquals(body.chapterTitle, "Ch3", "chapterTitle");
  const qs = body.questions as Array<Record<string, unknown>>;
  assertEquals(qs.length, 4, "four rows");
  for (const q of qs) {
    assertEquals(Object.keys(q).sort(), ["id", "page", "problem", "questionText", "questionType"], "list item keys");
    for (const f of FORBIDDEN) {
      assert(!(f in q), `forbidden field ${f} must not appear`);
    }
  }
});

Deno.test("list ordering: page asc, then problem asc, nulls last", async () => {
  const res = await handleListByChapter(makeDb(), LIST_INPUT);
  const qs = (res.body as Record<string, unknown>).questions as Array<{ id: string }>;
  assertEquals(qs.map((q) => q.id), ["q2", "q0", "q1", "q3"], "page-then-problem-nulls-last");
});

Deno.test("sortQuestions + toListItem pure helpers agree with the handler", () => {
  assertEquals(
    sortQuestions(listRows()).map((r) => r.id),
    ["q2", "q0", "q1", "q3"],
    "pure sort",
  );
  assertEquals(Object.keys(toListItem(listRows()[0])).sort(), ["id", "page", "problem", "questionText", "questionType"], "pure item keys");
});

Deno.test("empty chapter is an honest empty list, not not-indexed", async () => {
  const res = await handleListByChapter(makeDb({ rows: [] }), LIST_INPUT);
  assertEquals(res.body, {
    found: true,
    bookId: "class6-math-bn",
    bookTitle: "Math BN",
    language: "bn",
    chapterNumber: 3,
    chapterTitle: "Ch3",
    questions: [],
  }, "empty list body");
});

Deno.test("missing book => no-book; missing chapter => not-indexed", async () => {
  const noBook = await handleListByChapter(makeDb({ book: null }), LIST_INPUT);
  assertEquals(noBook.body, { found: false, reason: "no-book" }, "no-book");
  const noCh = await handleListByChapter(makeDb({ chapter: null }), LIST_INPUT);
  assertEquals(noCh.body, { found: false, reason: "not-indexed" }, "no-chapter maps to not-indexed");
});

Deno.test("question_type column absent (42703): retry without it, questionType null for all", async () => {
  const res = await handleListByChapter(makeDb({ listErrorCode: "42703" }), LIST_INPUT);
  assertEquals(res.status, 200, "status stays 200 on pre-009 fallback");
  const qs = (res.body as Record<string, unknown>).questions as Array<{ questionType: unknown }>;
  assertEquals(qs.length, 4, "rows still listed");
  assert(qs.every((q) => q.questionType === null), "every questionType null pre-009");
});

Deno.test("non-42703 list error is a 500, never a silent empty list", async () => {
  const res = await handleListByChapter(makeDb({ listErrorCode: "42501" }), LIST_INPUT);
  assertEquals(res.status, 500, "500 on other errors");
  assertEquals(res.body, { error: "Question lookup failed" }, "error body");
});

Deno.test("by-id resolves a null-problem row by id, not by page/problem match", async () => {
  // Two rows share page 45; the target has problem null. A
  // page/problem lookup could never pick it out — id lookup can.
  const res = await handleByQuestionId(makeDb(), { questionId: "q3", language: "bn" });
  const body = res.body as Record<string, unknown>;
  assertEquals(body.found, true, "found");
  assertEquals(body.questionText, "unnumbered", "null-problem row by id");
  assertEquals(body.page, 45, "page");
  assertEquals(body.problem, 0, "Mode-A-shaped: null problem coerced to 0");
  assertEquals(body.bookTitle, "Math BN", "bookTitle");
  assertEquals(body.chapterNumber, 3, "chapterNumber");
  for (const f of FORBIDDEN) {
    assert(!(f in body) || f === "chunks", `forbidden field ${f} must not appear`);
  }
  assert(!("answerKey" in body), "no answerKey");
  assert(!("solution" in body), "no solution");
});

Deno.test("by-id asks chunks for the same book+chapter+page only", async () => {
  const seen: { bookId: string; chapterId: string | null; page: number }[] = [];
  const chunks: GroundedChunk[] = [{ text: "unit", pageStart: 45, pageEnd: 45 }];
  const res = await handleByQuestionId(
    makeDb({ chunks, seenFetch: seen }),
    { questionId: "q0", language: "bn" },
  );
  assertEquals(seen, [{ bookId: "class6-math-bn", chapterId: "class6-math-bn-ch3", page: 45 }], "chunk scope");
  const body = res.body as Record<string, unknown>;
  assertEquals(body.chunks, chunks, "chunks passed through");
  assertEquals(body.chunkReason, "chunks-found", "chunkReason");
});

Deno.test("by-id missing row => not-indexed; chunk failure degrades to no-chunks", async () => {
  const missing = await handleByQuestionId(makeDb({ byId: null }), { questionId: "nope", language: "bn" });
  assertEquals(missing.body, { found: false, reason: "not-indexed" }, "missing row");
  const failing: ChapterListDb = {
    ...makeDb(),
    fetchChunks: async () => { throw new Error("db down"); },
  };
  const degraded = await handleByQuestionId(failing, { questionId: "q0", language: "bn" });
  const body = degraded.body as Record<string, unknown>;
  assertEquals(body.found, true, "row still returned on chunk failure");
  assertEquals(body.chunks, [], "chunks []");
  assertEquals(body.chunkReason, "no-chunks", "chunkReason");
});

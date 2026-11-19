// Yes Sir AI — Edge chapter-list helpers: listByChapter + by-question-id.
//
// Extracted from explain-question/index.ts so the response shapes,
// ordering, and pre-migration-009 fallback are unit-testable
// (chapter_list.test.ts). No supabase-js import here on purpose:
// the caller (index.ts) passes a small Db adapter, so this module
// (and its tests) run offline with `deno test`.
//
// MODES (2026-10-30, second-step chapter list):
//   listByChapter — { listByChapter: true, subject, classId,
//     chapter, language } => { found: true, bookId, bookTitle,
//     language, chapterNumber, chapterTitle, questions: [{ id,
//     questionText, page, problem, questionType }] }.
//     Ordered by page asc, then problem asc with nulls last.
//     Public fields ONLY: no chunks, no solutions, no keys, no
//     answers — the list is a picker, not an explanation.
//     Empty chapter => found: true with questions: [] (an honest
//     empty list, NOT 'not-indexed' — the client shows it).
//     Missing book => found: false, reason 'no-book'; missing
//     chapter => found: false, reason 'not-indexed'.
//   by-question-id — { questionId, language } => Mode-A-shaped
//     { found: true, bookTitle, chapterTitle, chapterNumber,
//     page, problem, questionText, chunks, chunkReason }.
//     Resolved by row id ONLY (never by page/problem match), so
//     a null-problem (unnumbered) row resolves exactly. Chunks
//     are the page-overlapping book_chunks for the SAME book +
//     chapter only, max 3, in reading order, NEVER neighbours
//     (same rule as Mode A, via grounding.ts fetchChunks).
//     Missing row => found: false, reason 'not-indexed'.
//     This mode selects NO question_type column, so it works
//     even before migration 009 lands.
//
// PRE-009 BEHAVIOUR (question_type column absent): listByChapter
// first selects WITH question_type; a 42703 (undefined column)
// error retries WITHOUT it, and every row returns
// questionType: null. The list still works; the client shows
// such rows under অন্যান্য (other) until migration 009 +
// backfill are live. Any other query error is a 500, never a
// silent empty list. DEPLOY ORDERING: the WITH-question_type
// select must deploy only AFTER migration 009 + backfill are
// live — before that, every list call pays one failed select
// and returns questionType: null for all rows (correct but
// unfiltered); by-id mode does not depend on 009 at all and
// may deploy earlier. See 009_book_question_type.sql header.

import type { GroundedChunk } from "./grounding.ts";

export type { GroundedChunk } from "./grounding.ts";

export interface BookRow {
  id: string;
  title: string;
}

export interface ChapterRow {
  id: string;
  number: number;
  title: string;
}

export interface QuestionRow {
  id: string;
  page: number;
  problem: number | null;
  questionText: string;
  // Absent (undefined) when the column was not selected — i.e.
  // the pre-009 fallback path. Null means the row itself has no
  // type stored. Both surface as questionType: null.
  questionType?: string | null;
}

export interface ListItem {
  id: string;
  questionText: string;
  page: number;
  problem: number | null;
  questionType: string | null;
}

export type ListQueryResult =
  | { rows: QuestionRow[] }
  | { errorCode: string };

// Minimal Db surface the two handlers need. index.ts adapts the
// real Supabase client onto this; tests use canned fakes.
export interface ChapterListDb {
  findBook(
    classId: number,
    subject: string,
    language: string,
  ): Promise<BookRow | null>;
  findChapter(bookId: string, chapterNumber: number): Promise<ChapterRow | null>;
  // withType=true selects question_type; the handler retries with
  // withType=false when the result carries errorCode '42703'.
  listQuestions(
    bookId: string,
    chapterId: string,
    withType: boolean,
  ): Promise<ListQueryResult>;
  findQuestionById(id: string, language: string): Promise<{
    row: QuestionRow;
    book: BookRow;
    chapter: ChapterRow | null;
  } | null>;
  fetchChunks(
    bookId: string,
    chapterId: string | null,
    page: number,
  ): Promise<GroundedChunk[]>;
}

export interface HandlerResult {
  status: number;
  body: Record<string, unknown>;
}

// Page asc, then problem asc with nulls last. Applied in the
// handler even though the SQL orders the same way, so the
// contract holds regardless of query order.
export function sortQuestions<T extends { page: number; problem: number | null }>(
  rows: T[],
): T[] {
  return [...rows].sort((a, b) => {
    if (a.page !== b.page) return a.page - b.page;
    if (a.problem === null && b.problem === null) return 0;
    if (a.problem === null) return 1;
    if (b.problem === null) return -1;
    return a.problem - b.problem;
  });
}

// List mapping: exactly the five public fields, nothing else.
// In particular: no chunks, no solution, no answer, no key.
export function toListItem(row: QuestionRow): ListItem {
  return {
    id: row.id,
    questionText: row.questionText,
    page: row.page,
    problem: row.problem,
    questionType: row.questionType ?? null,
  };
}

export async function handleListByChapter(
  db: ChapterListDb,
  input: { subject: string; classId: number; chapter: number; language: string },
): Promise<HandlerResult> {
  const language = input.language === "en" ? "en" : "bn";
  let book: BookRow | null;
  try {
    book = await db.findBook(input.classId, input.subject, language);
  } catch {
    return { status: 500, body: { error: "Book lookup failed" } };
  }
  if (!book) return { status: 200, body: { found: false, reason: "no-book" } };
  let chapter: ChapterRow | null;
  try {
    chapter = await db.findChapter(book.id, input.chapter);
  } catch {
    return { status: 500, body: { error: "Chapter lookup failed" } };
  }
  if (!chapter) {
    return { status: 200, body: { found: false, reason: "not-indexed" } };
  }
  let result: ListQueryResult;
  try {
    result = await db.listQuestions(book.id, chapter.id, true);
  } catch {
    return { status: 500, body: { error: "Question lookup failed" } };
  }
  // Pre-009 fallback: question_type column does not exist yet.
  // Retry without it; every row then carries questionType: null.
  if ("errorCode" in result && result.errorCode === "42703") {
    try {
      result = await db.listQuestions(book.id, chapter.id, false);
    } catch {
      return { status: 500, body: { error: "Question lookup failed" } };
    }
  }
  if ("errorCode" in result) {
    return { status: 500, body: { error: "Question lookup failed" } };
  }
  const questions = sortQuestions(result.rows).map(toListItem);
  return {
    status: 200,
    body: {
      found: true,
      bookId: book.id,
      bookTitle: book.title,
      language,
      chapterNumber: chapter.number,
      chapterTitle: chapter.title,
      questions,
    },
  };
}

export async function handleByQuestionId(
  db: ChapterListDb,
  input: { questionId: string; language: string },
): Promise<HandlerResult> {
  const language = input.language === "en" ? "en" : "bn";
  let found;
  try {
    found = await db.findQuestionById(input.questionId, language);
  } catch {
    return { status: 500, body: { error: "Question lookup failed" } };
  }
  if (!found) {
    return { status: 200, body: { found: false, reason: "not-indexed" } };
  }
  const { row, book, chapter } = found;
  // Same-book+chapter page-overlap grounding as Mode A; a chunk
  // failure degrades to [] + 'no-chunks', never hides the row.
  let chunks: GroundedChunk[] = [];
  try {
    chunks = await db.fetchChunks(
      book.id,
      chapter ? chapter.id : null,
      row.page,
    );
  } catch {
    chunks = [];
  }
  return {
    status: 200,
    body: {
      found: true,
      bookTitle: book.title,
      chapterTitle: chapter ? chapter.title : "",
      chapterNumber: chapter ? chapter.number : 0,
      page: row.page,
      // Mode-A-shaped: Mode A coerces a null problem to 0, and
      // this mode matches it exactly.
      problem: row.problem ?? 0,
      questionText: row.questionText,
      chunks,
      chunkReason: chunks.length > 0 ? "chunks-found" : "no-chunks",
    },
  };
}

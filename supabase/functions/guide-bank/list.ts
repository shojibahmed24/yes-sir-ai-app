// Pure helper for the guide-bank `list` action payload shaping.
// Kept offline-friendly (only the relative search import, which
// is itself import-free) so list.test.ts runs fully offline
// under `deno test`, no live DB needed.
//
// PAYLOAD SAFETY (same as `search`): a shaped row carries id,
// questionText, questionType, options, marks, important, setId,
// hasKey, guideError, lesson, section, mcq_group, stimulusId,
// stimulusText, stimulusRef, flagNote, hasSolution, modelQuestionId,
// suggestionKind, suggestionStar, suggestionPoricched,
// suggestionShironam, linkedDirectiveIds — NEVER
// answer_key, NEVER guide_solution.
// hasSolution is a BOOLEAN derived from guide_solution presence
// (non-null and non-empty); the solution text itself never
// leaves the server in a list response. guide_solution is
// selected only to compute that boolean.
// On pre-migration servers (pilot columns absent, 42703 retry),
// lesson/section/stimulus fields report null and hasSolution
// reports null (unknown, NOT "no solution"); guideError keeps
// its existing retry semantics (false, "not known bad").

import { optionsToArray } from "./search.ts";

// NEW SEARCH-FLOW LIST PARAMS (Step 1): server-side lesson /
// section filtering + offset/limit pagination. The helpers below
// are pure and offline-testable; index.ts wires them to the real
// Supabase query (exact .eq() on the DB columns, same semantics
// as filterListRows here: a non-null filter never matches a NULL
// row value, exactly like SQL `=`, so untagged rows are excluded
// from a filtered list, never silently included).

export type ListRow = Record<string, unknown>;

// Allowed `section` values (DB guide_questions.section, migration
// 013, extended 2026-11-02 for the new subjects). Any other
// non-empty string is a client error (400), never silently
// treated as "all sections". Values are exact-match and
// case-sensitive; near-identical values are DISTINCT sections:
// 'mcq' (Bangla) vs 'mcq_bank' (Math) vs 'mcq-bank' (Biology),
// 'short' (Math/Bangla) vs 'short-qa' (Biology), 'creative'
// (Math/Bangla) vs 'model-creative' / 'board-creative'.
// Union = 76 values: Math 5 + Bangla 6 new + Paper-II 15 new +
// Biology 15 new + Islam 3 new + Physics 6 new + English 13 new
// + Bangla 2nd 5 new + Chemistry 4 new + Higher Math 4 new
// (shared values counted once).
export const LIST_SECTION_VALUES = [
  // Math (original 5).
  "practice_work",
  "textbook_exercise",
  "mcq_bank",
  "short",
  "creative",
  // Bangla 1st Paper (short, creative already listed).
  "quiz",
  "mcq",
  "model-mcq",
  "descriptive",
  "model-creative",
  "bank",
  // English Paper-II (prefix is its own section per the tagging
  // spec and the Paper-II dry-run audit counts 67 prefix rows).
  "gapbox",
  "table",
  "verbs",
  "transform",
  "tag",
  "suffix",
  "prefix",
  "preposition",
  "connector",
  "punctuation",
  "writing-paragraph",
  "writing-email",
  "writing-letter",
  "writing-application",
  "writing-composition",
  // Biology (quiz, descriptive, model-mcq, model-creative,
  // creative already listed; 20 sections per its dry-run §3).
  "mcq-bank",
  "short-qa",
  "model-short",
  "board-mcq",
  "board-creative",
  "knowledge-qa",
  "viva",
  "conceptual",
  "rapid-qa",
  "knowledge",
  "gyanmulok",
  "anudhabanmulok",
  "activity",
  "comprehension",
  "general-qa",
  // Islam (2026-11-03 import prep; quiz, mcq-bank, short-qa,
  // knowledge-qa, creative, model-mcq, model-creative,
  // model-short, board-mcq, board-creative, activity already
  // listed). comprehension-qa is ch2's SPLIT section (ch1/ch3/
  // ch4/ch5 combine knowledge+comprehension under knowledge-qa);
  // qb-creative / qb-short are the answer-null question-bank
  // rows (owner decision §9.7 pending — listed so they are
  // filterable, never silently dropped from list responses).
  "comprehension-qa",
  "qb-creative",
  "qb-short",
  // Physics (2026-11-03 import; sections kept as collected, never
  // folded — 875 rows across these 6 values would fail
  // section-filtered list queries until listed here).
  "formula-math",
  "exercise-qa",
  "practice-math",
  "type-bank",
  "applied-math",
  "conceptual-creative",
  // English Paper-I (2026-11-03 quick-load; live DB sections for
  // class9-english-1st-bn-guide). Without these, the generic
  // flow client-scanned them page by page because the server
  // section parameter rejected them. mcq/short/table were
  // already listed by earlier subjects. 'story' (generic story
  // bucket, 604 rows) vs 'writing-story' (writing entries, 98
  // rows) are DISTINCT sections, never folded.
  "gapfill",
  "matching",
  "poem",
  "rearranging",
  "story",
  "summary",
  "true-false",
  "writing-composition",
  "writing-dialogue",
  "writing-graph",
  "writing-letter",
  "writing-paragraph",
  "writing-story",
  // Bangla 2nd Paper (2026-11-04 import; sections kept as
  // collected, never folded — bank and board-mcq were already
  // listed by earlier subjects). byakoron-assessment is the
  // 90-row grammar-assessment block; appendix-model-test is
  // the 718-row appendix model-test block; board-written is
  // the 108-row board written block (board-mcq already
  // listed); nirmiti is the 300-row composition block;
  // suggestion is the 68-row appendix suggestion block
  // (suggestion rows, not question-answer rows).
  "board-written",
  "byakoron-assessment",
  "nirmiti",
  "appendix-model-test",
  "suggestion",
  // Chemistry (2026-11-04 import; sections kept as collected,
  // never folded — all other 15 Chemistry sections were already
  // listed by earlier subjects). topic-math is the 216-row
  // topic-math block; topic-math-bank is the 38-row topic-math
  // bank block; understanding-qa is the 23-row understanding
  // block; practical-chunk is the 28-row practical-chunk block.
  "topic-math",
  "topic-math-bank",
  "understanding-qa",
  "practical-chunk",
  // Higher Math (Newton, 2026-11-05 import; sections kept as
  // collected, never folded — all other 7 Higher Math sections
  // were already listed by earlier subjects). exercise is the
  // 144-row textbook-exercise block; exercise-mcq is the 50-row
  // exercise MCQ block; exercise-creative is the 9-row exercise
  // creative block; model-written is the 7-row model written
  // block. Without these, section-filtered list queries for
  // those 210 rows would be rejected with 400.
  "exercise-mcq",
  "exercise",
  "exercise-creative",
  "model-written",
  // BGS + General Science + Economics (2026-11-06 joint import;
  // sections kept as collected, never folded — all other sections
  // were already listed by earlier subjects). knowledge-comprehension
  // is the 1,135-row knowledge+comprehension block (BGS 562, GS 215,
  // Econ 358); model is the 839-row model block (BGS 203, GS 318,
  // Econ 318); special-model is the 2,490-row special model-test
  // block (BGS 795, GS 794, Econ 901); super-quiz is the 476-row
  // GS super-quiz block; board is the 1,774-row board block
  // (GS 1,096, Econ 678). Without these, section-filtered list
  // queries for those 6,714 rows would be rejected with 400.
  "knowledge-comprehension",
  "model",
  "special-model",
  "super-quiz",
  "board",
  // Exam-kind groups (see SECTION_GROUPS below): the app asks for
  // these names; they expand to exact raw section lists.
  "grp_one_word",
  "grp_knowledge",
  "grp_comprehension",
  "grp_math_problem",
  "grp_other_practice",
  "grp_exercise",
  "grp_activity",
  "grp_exercise_mcq",
] as const;

export type ListSection = (typeof LIST_SECTION_VALUES)[number];

export function isValidListSection(value: unknown): value is ListSection {
  return typeof value === "string" &&
    (LIST_SECTION_VALUES as readonly string[]).includes(value);
}

// Sentinel lesson filter: rows whose lesson is NULL or blank.
// The app sends it to list rows that carry no lesson value.
export const NO_LESSON_FILTER = "__none__";

// Type sections are stored under different raw names per subject:
// Math 'mcq_bank'/'short', Biology/Physics/Chemistry/Accounting/...
// 'mcq-bank' (+ 'mcq-bank-top-graded'), 'mcq', 'short-qa'. The app
// always asks for the Math name, so every other subject listed 0.
// The filter now matches the raw names that state the SAME kind.
// Only exact, explicit names are grouped: board-*, model-*,
// special-model, exercise-*, qb-*, quiz, knowledge-* are NOT
// folded (different products / editorial calls). 'creative' is the
// same raw name everywhere, so it needs no group.
const SECTION_GROUPS: Record<string, readonly string[]> = {
  mcq_bank: ["mcq_bank", "mcq-bank", "mcq", "mcq-bank-top-graded", "extra-mcq"],
  short: ["short", "short-qa"],
  // Exam-kind groups for subjects that keep these under their own
  // section names (class 9 Chemistry, Civics). 'grp_' names never
  // clash with a raw section value; each is an exact list of raw
  // names, nothing matched by pattern. Checked against the rows:
  // quiz = one-word / one-line answers (1 mark), knowledge-qa =
  // "কাকে বলে?" questions, comprehension-qa = "ব্যাখ্যা কর".
  grp_one_word: ["quiz"],
  grp_knowledge: ["knowledge-qa", "knowledge"],
  grp_comprehension: ["comprehension-qa", "understanding-qa", "comprehension"],
  grp_math_problem: ["topic-math", "topic-math-bank", "applied-math"],
  grp_other_practice: ["viva", "activity", "practical-chunk"],
  // Class 9 Higher Math: textbook exercise, activity (অনুশীলনমূলক
  // কাজ) and the exercise MCQs, each its own type (never mixed into
  // the বহুনির্বাচনি bank).
  grp_exercise: ["exercise"],
  grp_activity: ["activity"],
  grp_exercise_mcq: ["exercise-mcq"],
};

// Raw section values a list filter matches (null = no filter).
export function expandListSection(section: string | null): string[] | null {
  if (section === null) return null;
  const group = SECTION_GROUPS[section];
  return group ? [...group] : [section];
}

// Lesson: trimmed non-empty string, or null (= all lessons).
// null / undefined / "" / whitespace-only all mean "no filter".
// A non-string, non-null value is NOT normalised here — index.ts
// rejects it with 400 instead of silently dropping the filter.
export function normalizeListLesson(raw: unknown): string | null {
  if (raw === null || raw === undefined) return null;
  if (typeof raw !== "string") return null;
  const trimmed = raw.trim();
  return trimmed === "" ? null : trimmed;
}

// List scope resolution (chapterless bank lists, 2026-11-01).
// A `list` request serves exactly one scope, by precedence:
// board wins over setId, setId wins over chapterless,
// chapterless wins over chapter, and none of them is a client
// error (400) in index.ts.
// - 'board': flagged BOARD rows ONLY (migration 018
//   out_of_syllabus = true AND section IN (board-mcq,
//   board-creative)), across sets and chapters. The flag is the
//   identifier; the presentation is Board sub-sections, not an
//   "Others" bucket (revised 2026-11-02: the Others scope was
//   removed, its rows re-framed as board questions). Normal
//   scopes exclude flagged rows (index.ts, withNewCols query
//   only), so no row is ever shown twice — once under Board,
//   it leaves its set/chapter list. On a pre-migration server
//   a board request returns pilot-columns-missing, never a
//   retry (the retry query cannot express the flag filter).
//   A legacy `others=true` request is rejected with 400 in
//   index.ts, never silently re-routed.
// - 'set': one model-test set (book_id + set_id, chapter-free).
// - 'chapterless': a book's bank rows (set_id NULL) with NO
//   guide-native chapter number (chapter_number IS NULL).
//   This is the scope that makes chapter-free books browsable:
//   English guide rows carry chapter_number NULL (English has
//   no numbered chapters), so no chapter filter can ever match
//   them, and practice rows additionally carry set_id NULL, so
//   no set filter can match them either. The scope is
//   book-scoped, so rows from other books never leak in; for
//   the English book it is exact (both chapter fields NULL).
//   Rows linked only via textbook chapter_id but lacking a
//   guide-native number (e.g. old class-7 rows) are included
//   too — harmless overlap, since the caller scopes by book.
// - 'chapter': a chapter's bank rows (the original behaviour).
export type ListScope = "set" | "chapterless" | "chapter" | "board";

export function resolveListScope(
  setIdGiven: boolean,
  chapterless: boolean,
  chapterGiven: boolean,
  boardGiven = false,
): ListScope | null {
  if (boardGiven) return "board";
  if (setIdGiven) return "set";
  if (chapterless) return "chapterless";
  if (chapterGiven) return "chapter";
  return null;
}

// Offset: integer >= 0, default 0. Non-integers and negatives
// clamp to 0 (same forgiving style as the old page/pageSize).
export function clampListOffset(raw: unknown): number {
  if (typeof raw === "number" && Number.isInteger(raw) && raw >= 0) {
    return raw;
  }
  return 0;
}

// Limit: integer clamped to 1..50, default 20. Non-integers fall
// back to the default (same forgiving style as page/pageSize).
export function clampListLimit(raw: unknown): number {
  if (typeof raw === "number" && Number.isInteger(raw)) {
    return Math.min(Math.max(raw, 1), 50);
  }
  return 20;
}

// True when the request asks for a pilot-column filter. Used for
// the pre-migration (42703) decision: filtered requests must NOT
// fall back to an unfiltered retry.
export function isFilteredListRequest(
  lesson: string | null,
  section: string | null,
): boolean {
  return lesson !== null || section !== null;
}

// Pre-migration (42703) outcome for a `list` request.
// - Unfiltered: 'retry' — the old retry-without-pilot-fields.
// - Filtered: 'pilot-columns-missing' — the client must show an
//   honest unavailable state, never unfiltered rows.
export const PILOT_COLUMNS_MISSING_REASON = "pilot-columns-missing";

export type ListPreMigrationOutcome = "retry" | "pilot-columns-missing";

export function listPreMigrationOutcome(
  filtered: boolean,
): ListPreMigrationOutcome {
  return filtered ? "pilot-columns-missing" : "retry";
}

// Mirror of the DB-side filtering (index.ts .eq() calls), for
// offline tests: exact equality, null filter = no filter, a
// non-null filter never matches a null row value.
export function filterListRows(
  rows: ListRow[],
  lesson: string | null,
  section: string | null,
): ListRow[] {
  return rows.filter((r) => {
    if (lesson === NO_LESSON_FILTER) {
      const v = r.lesson as string | null;
      if (v !== null && v !== undefined && v.trim() !== "") return false;
    } else if (lesson !== null && (r.lesson as string | null) !== lesson) {
      return false;
    }
    if (section !== null) {
      const raw = r.section as string | null;
      if (raw === null || !(expandListSection(section) as string[]).includes(raw)) {
        return false;
      }
    }
    return true;
  });
}

// Mirror of the DB-side pagination (index.ts .range()): total is
// the FULL filtered count, never the page length — this is the
// property the "আরো দেখুন" client depends on.
export function paginateListRows(
  filteredRows: ListRow[],
  offset: number,
  limit: number,
): { total: number; pageRows: ListRow[] } {
  return {
    total: filteredRows.length,
    pageRows: filteredRows.slice(offset, offset + limit),
  };
}

export function shapeListRow(
  r: ListRow,
  pilotFieldsKnown: boolean,
): Record<string, unknown> {
  const key = r.answer_key as string | null;
  const sol = r.guide_solution as string | null;
  return {
    id: r.id as string,
    questionText: r.question_text as string,
    questionType: r.question_type as string,
    options: optionsToArray(r.options),
    marks: (r.marks as number | null) ?? null,
    important: (r.important as boolean) ?? false,
    setId: (r.set_id as string | null) ?? null,
    // The ONLY key-related field: a boolean, never the key.
    hasKey: key !== null && key !== "",
    guideError: pilotFieldsKnown
      ? (r.guide_error as boolean | null) ?? false
      : false,
    lesson: pilotFieldsKnown ? (r.lesson as string | null) ?? null : null,
    section: pilotFieldsKnown ? (r.section as string | null) ?? null : null,
    mcq_group: pilotFieldsKnown ? (r.mcq_group as string | null) ?? null : null,
    stimulusId: pilotFieldsKnown
      ? (r.stimulus_id as string | null) ?? null
      : null,
    stimulusText: pilotFieldsKnown
      ? (r.stimulus_text as string | null) ?? null
      : null,
    // Passage/stimulus reference (e.g. English passage refs),
    // verbatim; null when absent/old server. Same gating as
    // stimulusText: never a guessed reference.
    stimulusRef: pilotFieldsKnown
      ? (r.stimulus_ref as string | null) ?? null
      : null,
    // Pilot (013) print note, verbatim; null when absent/old server.
    flagNote: pilotFieldsKnown
      ? (r.flag_note as string | null) ?? null
      : null,
    // Creative part marks, raw (object or list; the app normalises
    // it). null when absent or on pre-migration servers.
    marksParts: pilotFieldsKnown ? (r.marks_parts ?? null) : null,
    // Phase 3 model link: the bank model row id for a Q10-12
    // test row (NULL = no link); null on pre-migration servers.
    modelQuestionId: pilotFieldsKnown
      ? (r.model_question_id as string | null) ?? null
      : null,
    // Suggestion block (2026-11-04 backfill): appendix
    // suggestion rows only; null for every other row and on
    // pre-migration servers. linkedDirectiveIds are live bank
    // row ids (verified at backfill: 616 distinct, all live);
    // dropped directives are never served as questions.
    suggestionKind: pilotFieldsKnown
      ? (r.suggestion_kind as string | null) ?? null
      : null,
    suggestionStar: pilotFieldsKnown
      ? (r.suggestion_star as string | null) ?? null
      : null,
    suggestionPoricched: pilotFieldsKnown
      ? (r.suggestion_poricched as string | null) ?? null
      : null,
    suggestionShironam: pilotFieldsKnown
      ? (r.suggestion_shironam as string | null) ?? null
      : null,
    linkedDirectiveIds: pilotFieldsKnown
      ? (r.linked_directive_ids as string[] | null) ?? null
      : null,
    // Boolean only: true iff a solution is stored (non-null and
    // non-empty). Null on pre-migration servers (unknown).
    hasSolution: pilotFieldsKnown ? sol !== null && sol !== "" : null,
    // Board metadata (round 4): printed board + year for a board row,
    // null elsewhere and on pre-migration servers. The client labels
    // rows from these, never from a guessed set id.
    boardName: pilotFieldsKnown
      ? (r.board_name as string | null) ?? null
      : null,
    boardYear: pilotFieldsKnown
      ? (r.board_year as number | null) ?? null
      : null,
  };
}

// Slim list row (quick-load Phase 3): list screens show only
// these fields. Options and stimulus text are the payload bulk
// and arrive with the full row on open (action 'get') instead.
// slim: true marks the row so the client never mistakes it for
// a genuinely option-less row (short/creative rows are option-
// less by nature, but never slim-flagged).
export function shapeSlimListRow(
  r: ListRow,
  pilotFieldsKnown: boolean,
): Record<string, unknown> {
  const key = r.answer_key as string | null;
  const sol = r.guide_solution as string | null;
  return {
    id: r.id as string,
    questionText: r.question_text as string,
    questionType: r.question_type as string,
    marks: (r.marks as number | null) ?? null,
    important: (r.important as boolean) ?? false,
    setId: (r.set_id as string | null) ?? null,
    // The ONLY key-related field: a boolean, never the key.
    hasKey: key !== null && key !== "",
    guideError: pilotFieldsKnown
      ? (r.guide_error as boolean | null) ?? false
      : false,
    lesson: pilotFieldsKnown ? (r.lesson as string | null) ?? null : null,
    section: pilotFieldsKnown ? (r.section as string | null) ?? null : null,
    mcq_group: pilotFieldsKnown ? (r.mcq_group as string | null) ?? null : null,
    // Creative part marks, raw and tiny; lets a list group show them.
    marksParts: pilotFieldsKnown ? (r.marks_parts ?? null) : null,
    suggestionKind: pilotFieldsKnown
      ? (r.suggestion_kind as string | null) ?? null
      : null,
    suggestionStar: pilotFieldsKnown
      ? (r.suggestion_star as string | null) ?? null
      : null,
    suggestionPoricched: pilotFieldsKnown
      ? (r.suggestion_poricched as string | null) ?? null
      : null,
    suggestionShironam: pilotFieldsKnown
      ? (r.suggestion_shironam as string | null) ?? null
      : null,
    linkedDirectiveIds: pilotFieldsKnown
      ? (r.linked_directive_ids as string[] | null) ?? null
      : null,
    hasSolution: pilotFieldsKnown ? sol !== null && sol !== "" : null,
    // Board metadata travels with slim rows too: the board list shows
    // "ঢাকা বোর্ড ২০২৩" without a second call (round 4).
    boardName: pilotFieldsKnown
      ? (r.board_name as string | null) ?? null
      : null,
    boardYear: pilotFieldsKnown
      ? (r.board_year as number | null) ?? null
      : null,
    slim: true,
  };
}

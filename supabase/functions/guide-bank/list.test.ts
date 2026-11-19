// Tests for the guide-bank `list` action payload shaping:
// pilot fields present, key/solution never leaked, hasSolution
// derivation rules, and pre-migration null behaviour. No
// external imports on purpose: `deno test` runs this file
// fully offline (only relative imports), no live DB.
import {
  clampListLimit,
  clampListOffset,
  filterListRows,
  isFilteredListRequest,
  isValidListSection,
  LIST_SECTION_VALUES,
  listPreMigrationOutcome,
  NO_LESSON_FILTER,
  normalizeListLesson,
  paginateListRows,
  PILOT_COLUMNS_MISSING_REASON,
  resolveListScope,
  shapeListRow,
  shapeSlimListRow,
} from "./list.ts";

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

const baseRow = {
  id: "pilot21-mcq_bank-001",
  question_text: "নিচের কোনটি সেট প্রকাশ করে?",
  question_type: "mcq",
  options: { "ক": "এক", "খ": "দুই", "গ": "তিন", "ঘ": "চার" },
  marks: 1,
  important: false,
  set_id: null,
  answer_key: "ঘ",
  guide_error: false,
  lesson: "2.1",
  section: "mcq_bank",
  stimulus_id: "pilot21-mcq_bank-001",
  stimulus_text: null,
  stimulus_ref: "test-ref-001",
  flag_note: "ছাপার নোট",
  guide_solution: "তথ্য-ব্যাখ্যা : ...",
};

Deno.test("shape: pilot fields present, key/solution never leak", () => {
  const shaped = shapeListRow(baseRow, true);
  assertEquals(shaped["lesson"], "2.1", "lesson");
  assertEquals(shaped["section"], "mcq_bank", "section");
  assertEquals(shapeListRow(baseRow, true)["mcq_group"], null, "mcq_group null when absent");
  assertEquals(shapeListRow({ ...baseRow, mcq_group: "writer" }, true)["mcq_group"], "writer", "mcq_group writer");
  assertEquals(shapeSlimListRow({ ...baseRow, mcq_group: "lesson" }, true)["mcq_group"], "lesson", "slim mcq_group lesson");
  assertEquals(shaped["stimulusId"], "pilot21-mcq_bank-001", "stimulusId");
  assertEquals(shaped["stimulusText"], null, "null stimulus text");
  assertEquals(shaped["stimulusRef"], "test-ref-001", "stimulusRef");
  assertEquals(shaped["flagNote"], "ছাপার নোট", "flagNote");
  assertEquals(shaped["hasSolution"], true, "hasSolution true");
  assertEquals(shaped["hasKey"], true, "hasKey boolean");
  assertEquals(shaped["options"], ["এক", "দুই", "তিন", "চার"], "options");
  assert(!("answer_key" in shaped), "no answer_key key");
  assert(!("guide_solution" in shaped), "no guide_solution key");
  assertEquals(JSON.stringify(shaped).includes("তথ্য-ব্যাখ্যা"), false, "no leak");
});

Deno.test("shape: suggestion fields served, null when absent or pre-migration", () => {
  const sugRow = {
    ...baseRow,
    question_type: "suggestion",
    section: "suggestion",
    suggestion_kind: "suggestion-mcq",
    suggestion_star: "★★",
    suggestion_poricched: "৫",
    suggestion_shironam: "পরিচ্ছেদ ৫: ধ্বনি ও বর্ণ",
    linked_directive_ids: ["ban2-ch05-mcq-bank-002", "ban2-ch05-mcq-bank-004"],
  };
  const shaped = shapeListRow(sugRow, true);
  assertEquals(shaped["suggestionKind"], "suggestion-mcq", "kind");
  assertEquals(shaped["suggestionStar"], "★★", "star");
  assertEquals(shaped["suggestionPoricched"], "৫", "poricched");
  assertEquals(shaped["suggestionShironam"], "পরিচ্ছেদ ৫: ধ্বনি ও বর্ণ", "shironam");
  assertEquals(shaped["linkedDirectiveIds"], ["ban2-ch05-mcq-bank-002", "ban2-ch05-mcq-bank-004"], "linked ids");
  const slim = shapeSlimListRow(sugRow, true);
  assertEquals(slim["suggestionShironam"], "পরিচ্ছেদ ৫: ধ্বনি ও বর্ণ", "slim shironam");
  assertEquals(slim["linkedDirectiveIds"], ["ban2-ch05-mcq-bank-002", "ban2-ch05-mcq-bank-004"], "slim linked ids");
  const plain = shapeListRow(baseRow, true);
  assertEquals(plain["suggestionKind"], null, "non-suggestion kind null");
  assertEquals(plain["linkedDirectiveIds"], null, "non-suggestion links null");
  const old = shapeListRow(sugRow, false);
  assertEquals(old["suggestionKind"], null, "pre-migration kind unknown");
  assertEquals(old["linkedDirectiveIds"], null, "pre-migration links unknown");
});

Deno.test("shape: hasSolution false on null and empty solution", () => {
  assertEquals(
    shapeListRow({ ...baseRow, guide_solution: null }, true)["hasSolution"],
    false,
    "null solution",
  );
  assertEquals(
    shapeListRow({ ...baseRow, guide_solution: "" }, true)["hasSolution"],
    false,
    "empty solution",
  );
  assertEquals(
    shapeListRow({ ...baseRow, guide_solution: "x" }, true)["hasSolution"],
    true,
    "non-empty solution",
  );
});

Deno.test("shape: untagged row reports null pilot fields", () => {
  const row = {
    ...baseRow,
    lesson: null,
    section: null,
    stimulus_id: null,
    stimulus_text: null,
    stimulus_ref: null,
  };
  const shaped = shapeListRow(row, true);
  assertEquals(shaped["lesson"], null, "lesson null");
  assertEquals(shaped["section"], null, "section null");
  assertEquals(shaped["stimulusId"], null, "stimulusId null");
  assertEquals(shaped["stimulusText"], null, "stimulusText null");
  assertEquals(shaped["stimulusRef"], null, "stimulusRef null");
  assertEquals(shaped["hasSolution"], true, "solution still true");
});

Deno.test("shape: pre-migration server reports null pilot fields", () => {
  const shaped = shapeListRow(baseRow, false);
  assertEquals(shaped["lesson"], null, "lesson unknown");
  assertEquals(shaped["section"], null, "section unknown");
  assertEquals(shaped["stimulusId"], null, "stimulusId unknown");
  assertEquals(shaped["stimulusText"], null, "stimulusText unknown");
  assertEquals(shaped["stimulusRef"], null, "stimulusRef unknown");
  assertEquals(shaped["flagNote"], null, "flagNote unknown");
  assertEquals(shaped["hasSolution"], null, "hasSolution unknown, not false");
  assertEquals(shaped["guideError"], false, "guideError retry semantics");
});

// ---- Step 1: lesson/section filters + offset/limit pagination ----
// Mocked DB rows (raw column names, as filterListRows expects).
// Mirrors the DB .eq() semantics: exact match, NULL never matches
// a non-null filter, null filter means "all".
const mockRows = [
  { ...baseRow, id: "r1", lesson: "2.1", section: "mcq_bank" },
  { ...baseRow, id: "r2", lesson: "2.1", section: "short" },
  { ...baseRow, id: "r3", lesson: "2.2", section: "mcq_bank" },
  { ...baseRow, id: "r4", lesson: "2.2", section: "creative" },
  { ...baseRow, id: "r5", lesson: null, section: null },
  { ...baseRow, id: "r6", lesson: "2.1", section: "mcq_bank" },
];

function mockIds(rows: Record<string, unknown>[]): string[] {
  return rows.map((r) => r["id"] as string);
}

Deno.test("filter: lesson filter is exact, untagged rows excluded", () => {
  assertEquals(
    mockIds(filterListRows(mockRows, "2.1", null)),
    ["r1", "r2", "r6"],
    "lesson 2.1",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, "2.2", null)),
    ["r3", "r4"],
    "lesson 2.2",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, "2.10", null)),
    [],
    "2.10 must not match 2.1 (exact, not prefix)",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, null, null)),
    ["r1", "r2", "r3", "r4", "r5", "r6"],
    "null lesson = all, including untagged",
  );
});

Deno.test("filter: NO_LESSON_FILTER keeps only NULL/blank-lesson rows", () => {
  assertEquals(
    mockIds(filterListRows(mockRows, NO_LESSON_FILTER, null)),
    ["r5"],
    "sentinel keeps only the NULL-lesson row",
  );
  assertEquals(
    mockIds(filterListRows(
      [...mockRows, { ...baseRow, id: "r7", lesson: "   ", section: "mcq_bank" }],
      NO_LESSON_FILTER,
      null,
    )),
    ["r5", "r7"],
    "sentinel keeps whitespace-only lesson too",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, NO_LESSON_FILTER, "mcq_bank")),
    [],
    "sentinel + section: NULL-lesson row has NULL section, so none",
  );
});

Deno.test("filter: section filter is exact", () => {
  assertEquals(
    mockIds(filterListRows(mockRows, null, "mcq_bank")),
    ["r1", "r3", "r6"],
    "mcq_bank",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, null, "creative")),
    ["r4"],
    "creative",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, null, "practice_work")),
    [],
    "no practice_work rows in mock",
  );
});

Deno.test("filter: combined lesson + section filter", () => {
  assertEquals(
    mockIds(filterListRows(mockRows, "2.1", "mcq_bank")),
    ["r1", "r6"],
    "2.1 AND mcq_bank",
  );
  assertEquals(
    mockIds(filterListRows(mockRows, "2.2", "short")),
    [],
    "2.2 has no short rows",
  );
});

Deno.test("pagination: offset slices, total stays the full filtered count", () => {
  const filtered = filterListRows(mockRows, "2.1", null);
  const page1 = paginateListRows(filtered, 0, 2);
  assertEquals(page1.total, 3, "total is filtered count, not page size");
  assertEquals(mockIds(page1.pageRows), ["r1", "r2"], "first page");
  const page2 = paginateListRows(filtered, 2, 2);
  assertEquals(page2.total, 3, "total unchanged on page 2");
  assertEquals(mockIds(page2.pageRows), ["r6"], "second page remainder");
  const beyond = paginateListRows(filtered, 10, 2);
  assertEquals(beyond.total, 3, "total unchanged past the end");
  assertEquals(beyond.pageRows.length, 0, "empty page past the end");
  // "আরো দেখুন" honesty: hasMore = offset + page.length < total.
  assertEquals(0 + page1.pageRows.length < page1.total, true, "hasMore p1");
  assertEquals(2 + page2.pageRows.length < page2.total, false, "no more p2");
});

Deno.test("pagination: offset/limit clamping", () => {
  assertEquals(clampListOffset(0), 0, "offset 0");
  assertEquals(clampListOffset(5), 5, "offset 5");
  assertEquals(clampListOffset(-3), 0, "negative offset -> 0");
  assertEquals(clampListOffset(1.5), 0, "non-integer offset -> 0");
  assertEquals(clampListOffset("10"), 0, "string offset -> 0");
  assertEquals(clampListOffset(undefined), 0, "missing offset -> 0");
  assertEquals(clampListLimit(20), 20, "limit default value");
  assertEquals(clampListLimit(1), 1, "limit min");
  assertEquals(clampListLimit(50), 50, "limit max");
  assertEquals(clampListLimit(0), 1, "limit 0 -> 1");
  assertEquals(clampListLimit(51), 50, "limit 51 -> 50");
  assertEquals(clampListLimit(1000), 50, "limit huge -> 50");
  assertEquals(clampListLimit(-5), 1, "negative limit -> 1");
  assertEquals(clampListLimit(undefined), 20, "missing limit -> 20");
  assertEquals(clampListLimit(2.5), 20, "non-integer limit -> 20");
});

Deno.test("params: lesson normalisation and section validation", () => {
  assertEquals(normalizeListLesson("2.1"), "2.1", "plain lesson");
  assertEquals(normalizeListLesson("  2.1  "), "2.1", "trimmed lesson");
  assertEquals(normalizeListLesson(null), null, "null lesson");
  assertEquals(normalizeListLesson(undefined), null, "missing lesson");
  assertEquals(normalizeListLesson(""), null, "empty lesson = all");
  assertEquals(normalizeListLesson("   "), null, "blank lesson = all");
  for (const s of LIST_SECTION_VALUES) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
  // CONFLICT RESOLUTION (2026-11-02): the old negative example
  // "mcq" is no longer invalid — Bangla genuinely uses section
  // 'mcq' (2,351 rows), distinct by exact match from Math
  // 'mcq_bank' and Biology 'mcq-bank'. The negative example is
  // now a string no subject uses; 'mcq' is asserted valid below.
  assertEquals(isValidListSection("mcq"), true, "Bangla mcq is a section");
  assertEquals(
    isValidListSection("not_a_section"),
    false,
    "unknown string is not a section",
  );
  assertEquals(isValidListSection(""), false, "empty is not a section");
  assertEquals(isValidListSection("MCQ_BANK"), false, "case-sensitive");
  assertEquals(isValidListSection(42), false, "non-string rejected");
});

Deno.test("sections: Bangla/Paper-II/Biology values are valid", () => {
  // New values added 2026-11-02 (36 = 6 Bangla + 15 Paper-II +
  // 15 Biology); shared values (short, creative, quiz,
  // descriptive, model-mcq, model-creative) are covered by the
  // LIST_SECTION_VALUES loop above. Prefix is its own Paper-II
  // section per the tagging spec (67 rows in the dry-run audit).
  const added = [
    "quiz",
    "mcq",
    "model-mcq",
    "descriptive",
    "model-creative",
    "bank",
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
  ];
  assertEquals(added.length, 36, "36 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
  assertEquals(
    LIST_SECTION_VALUES.length,
    89,
    "union: 5 Math + 36 new + 3 Islam + 6 Physics + 13 English + 5 Bangla 2nd + 4 Chemistry + 4 Higher Math + 5 BGS/GS/Econ + 8 exam-kind groups (grp_*) = 89 (shared values counted once)",
  );
  // The three mcq spellings are distinct exact-match values.
  assert(
    new Set(["mcq", "mcq_bank", "mcq-bank"]).size === 3,
    "mcq variants distinct",
  );
});

Deno.test("sections: Islam values are valid", () => {
  // Added 2026-11-03 for the Islam import (class9-islam-bn-guide).
  // All other Islam sections (quiz, mcq-bank, short-qa,
  // knowledge-qa, creative, model-mcq, model-creative,
  // model-short, board-mcq, board-creative, activity) were
  // already listed by earlier subjects. comprehension-qa is
  // ch2's split section; qb-creative / qb-short are the
  // answer-null question-bank rows.
  const added = ["comprehension-qa", "qb-creative", "qb-short"];
  assertEquals(added.length, 3, "3 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: Physics values are valid", () => {
  // Added 2026-11-03 for the Physics import
  // (class9-physics-bn-guide). All other Physics sections were
  // already listed by earlier subjects. These 6 values are kept
  // as collected, never folded — 875 rows across them.
  const added = [
    "formula-math",
    "exercise-qa",
    "practice-math",
    "type-bank",
    "applied-math",
    "conceptual-creative",
  ];
  assertEquals(added.length, 6, "6 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: English Paper-I values are valid", () => {
  // Added 2026-11-03 for quick-load: without these, the generic
  // flow client-scanned English sections page by page because
  // the server section parameter rejected them. mcq, short and
  // table were already listed by earlier subjects. 'story'
  // (generic story bucket) vs 'writing-story' (writing entries)
  // are distinct sections, never folded.
  const added = [
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
  ];
  assertEquals(added.length, 13, "13 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: Bangla 2nd Paper values are valid", () => {
  // Added 2026-11-04 for the Bangla 2nd import
  // (class10-bangla-2nd-bn-guide). bank and board-mcq were
  // already listed by earlier subjects. Sections are kept as
  // collected, never folded.
  const added = [
    "board-written",
    "byakoron-assessment",
    "nirmiti",
    "appendix-model-test",
    "suggestion",
  ];
  assertEquals(added.length, 5, "5 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: Chemistry values are valid", () => {
  // Added 2026-11-04 for the Chemistry import
  // (class9-chemistry-bn-guide). All other 15 Chemistry sections
  // were already listed by earlier subjects. Sections are kept as
  // collected, never folded.
  const added = [
    "topic-math",
    "topic-math-bank",
    "understanding-qa",
    "practical-chunk",
  ];
  assertEquals(added.length, 4, "4 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: Higher Math values are valid", () => {
  // Added 2026-11-05 for the Higher Math import
  // (class9-higher-math-bn-guide). All other 7 Higher Math
  // sections were already listed by earlier subjects. Sections
  // are kept as collected, never folded.
  const added = [
    "exercise-mcq",
    "exercise",
    "exercise-creative",
    "model-written",
  ];
  assertEquals(added.length, 4, "4 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("sections: BGS/GS/Econ values are valid", () => {
  // Added 2026-11-06 for the BGS + General Science + Economics
  // joint import (class9-10-bgs-bn-guide,
  // class9-10-general-science-bn-guide, class9-10-economics-bn-guide).
  // All other sections were already listed by earlier subjects.
  // Sections are kept as collected, never folded.
  const added = [
    "knowledge-comprehension",
    "model",
    "special-model",
    "super-quiz",
    "board",
  ];
  assertEquals(added.length, 5, "5 newly listed values");
  for (const s of added) {
    assert(isValidListSection(s), `valid section ${s}`);
  }
});

Deno.test("slim: shaped slim row carries list fields only", () => {
  const filtered = filterListRows(mockRows, null, null);
  const { pageRows } = paginateListRows(filtered, 0, 50);
  assert(pageRows.length === mockRows.length, "full mock page");
  for (const row of pageRows) {
    const shaped = shapeSlimListRow(row, true) as Record<string, unknown>;
    assert(shaped["slim"] === true, "slim flag set");
    assert(typeof shaped["id"] === "string", "slim id");
    assert(typeof shaped["questionText"] === "string", "slim text");
    assert("hasKey" in shaped, "slim hasKey");
    assert(!("options" in shaped), "slim omits options");
    assert(!("stimulusText" in shaped), "slim omits stimulus");
    assert(!("stimulusRef" in shaped), "slim omits stimulusRef");
    assert(!("flagNote" in shaped), "slim omits flagNote");
    assert(!("modelQuestionId" in shaped), "slim omits model link");
    assert(!("answer_key" in shaped), "slim never leaks key");
    assert(!("guide_solution" in shaped), "slim never leaks solution");
  }
});

Deno.test("payload: no answer_key/guide_solution in any shaped page row", () => {
  const filtered = filterListRows(mockRows, null, null);
  const { pageRows } = paginateListRows(filtered, 0, 50);
  assert(pageRows.length === mockRows.length, "full mock page");
  for (const row of pageRows) {
    const shaped = shapeListRow(row, true);
    assert(!("answer_key" in shaped), `no answer_key in ${row.id}`);
    assert(!("guide_solution" in shaped), `no guide_solution in ${row.id}`);
    assertEquals(
      JSON.stringify(shaped).includes("তথ্য-ব্যাখ্যা"),
      false,
      `no solution text in ${row.id}`,
    );
  }
});

Deno.test("pre-migration 42703: filtered requests must not retry unfiltered", () => {
  assertEquals(
    isFilteredListRequest("2.1", null),
    true,
    "lesson alone counts as filtered",
  );
  assertEquals(
    isFilteredListRequest(null, "mcq_bank"),
    true,
    "section alone counts as filtered",
  );
  assertEquals(
    isFilteredListRequest("2.1", "mcq_bank"),
    true,
    "combined counts as filtered",
  );
  assertEquals(
    isFilteredListRequest(null, null),
    false,
    "unfiltered when both null",
  );
  assertEquals(
    listPreMigrationOutcome(true),
    "pilot-columns-missing",
    "filtered -> error path, never retry",
  );
  assertEquals(
    listPreMigrationOutcome(false),
    "retry",
    "unfiltered -> old retry preserved",
  );
  assertEquals(
    PILOT_COLUMNS_MISSING_REASON,
    "pilot-columns-missing",
    "reason code the client checks",
  );
});

Deno.test("shape: creative part carries stimulus text and marks", () => {
  const row = {
    ...baseRow,
    id: "pilot21-creative-001",
    question_type: "creative",
    options: null,
    marks: 2,
    section: "creative",
    stimulus_id: "cr-01",
    stimulus_text: "f(a) = ... হলে ...",
  };
  const shaped = shapeListRow(row, true);
  assertEquals(shaped["stimulusId"], "cr-01", "group id");
  assertEquals(shaped["stimulusText"], "f(a) = ... হলে ...", "stimulus");
  assertEquals(shaped["marks"], 2, "part marks");
});

Deno.test("scope: set wins over chapterless wins over chapter", () => {
  assertEquals(resolveListScope(true, true, true), "set", "set wins");
  assertEquals(
    resolveListScope(false, true, true),
    "chapterless",
    "chapterless wins over chapter",
  );
  assertEquals(resolveListScope(false, false, true), "chapter", "chapter");
  assertEquals(resolveListScope(true, false, false), "set", "set alone");
  assertEquals(
    resolveListScope(false, true, false),
    "chapterless",
    "chapterless alone",
  );
  assertEquals(resolveListScope(false, false, false), null, "none is null");
  assertEquals(
    resolveListScope(true, true, true, true),
    "board",
    "board wins over set",
  );
  assertEquals(
    resolveListScope(false, false, false, true),
    "board",
    "board alone",
  );
});

Deno.test("scope: board section filter narrows to one sub-section", () => {
  // The board scope is flagged rows with a board section; the
  // existing section filter then picks exactly one sub-section.
  // filterListRows mirrors the DB .eq() semantics in index.ts.
  const rows = [
    { id: "b1", section: "board-mcq" },
    { id: "b2", section: "board-creative" },
    { id: "b3", section: "board-mcq" },
    { id: "b4", section: "mcq-bank" },
  ];
  const mcq = filterListRows(rows, null, "board-mcq");
  assertEquals(
    mcq.map((r) => r.id),
    ["b1", "b3"],
    "board-mcq sub-section only",
  );
  const creative = filterListRows(rows, null, "board-creative");
  assertEquals(
    creative.map((r) => r.id),
    ["b2"],
    "board-creative sub-section only",
  );
  // A flagged non-board section is never a board sub-section:
  // the board scope's section-IN filter excludes it upstream.
  assertEquals(
    filterListRows(rows, null, "mcq-bank").map((r) => r.id),
    ["b4"],
    "non-board section stays out of board lists",
  );
});

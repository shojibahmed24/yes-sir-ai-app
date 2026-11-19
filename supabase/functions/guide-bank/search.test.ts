// Tests for the guide-bank `search` action helpers: LIKE
// escaping, limit clamping, and safe payload shaping. No
// external imports on purpose: `deno test` runs this file
// fully offline (only the relative search import), no live DB.
import {
  clampSearchLimit,
  escapeLikePattern,
  shapeSearchRow,
} from "./search.ts";

function assertEquals<T>(actual: T, expected: T, label: string): void {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function assert(cond: boolean, label: string): void {
  if (!cond) throw new Error(`assertion failed: ${label}`);
}

Deno.test("escape: plain text passes through", () => {
  assertEquals(escapeLikePattern("সেট কাকে বলে"), "সেট কাকে বলে", "plain");
});

Deno.test("escape: % and _ become literals, not wildcards", () => {
  assertEquals(escapeLikePattern("20% ছাড়"), "20\\% ছাড়", "percent");
  assertEquals(escapeLikePattern("ক_খ"), "ক\\_খ", "underscore");
});

Deno.test("escape: backslash is doubled first", () => {
  assertEquals(escapeLikePattern("a\\b"), "a\\\\b", "backslash");
  assertEquals(escapeLikePattern("100\\%"), "100\\\\\\%", "mixed");
});

Deno.test("clamp: default 50, valid kept, bounds enforced", () => {
  assertEquals(clampSearchLimit(undefined), 50, "default");
  assertEquals(clampSearchLimit(10), 10, "valid");
  assertEquals(clampSearchLimit(0), 1, "zero floors to 1");
  assertEquals(clampSearchLimit(500), 50, "over-cap to 50");
  assertEquals(clampSearchLimit(2.5), 50, "non-integer defaults");
  assertEquals(clampSearchLimit("20"), 50, "non-number defaults");
});

Deno.test("shape: full row maps, key becomes boolean only", () => {
  const row = {
    id: "q1",
    question_text: "সেট কাকে বলে?",
    question_type: "short",
    options: null,
    marks: 2,
    chapter_number: 2,
    answer_key: "ক",
    guide_solution: "SECRET SOLUTION TEXT",
    guide_error: false,
  };
  const shaped = shapeSearchRow(row, true);
  assertEquals(shaped["id"], "q1", "id");
  assertEquals(shaped["questionText"], "সেট কাকে বলে?", "text");
  assertEquals(shaped["marks"], 2, "marks");
  assertEquals(shaped["chapterNumber"], 2, "chapter");
  assertEquals(shaped["hasKey"], true, "hasKey");
  assertEquals(shaped["guideError"], false, "guideError");
  assert(!("answer_key" in shaped), "no answer_key key");
  assert(!("guide_solution" in shaped), "no guide_solution key");
  assertEquals(JSON.stringify(shaped).includes("SECRET"), false, "no leak");
});

Deno.test("shape: no key, null chapter, object options", () => {
  const row = {
    id: "q2",
    question_text: "MCQ?",
    question_type: "mcq",
    options: { "ক": "এক", "খ": "দুই" },
    marks: null,
    chapter_number: null,
    answer_key: "",
    guide_error: true,
  };
  const shaped = shapeSearchRow(row, true);
  assertEquals(shaped["hasKey"], false, "empty key");
  assertEquals(shaped["chapterNumber"], null, "null chapter");
  assertEquals(shaped["guideError"], true, "error flag");
  assertEquals(shaped["options"], ["এক", "দুই"], "object options ordered");
});

Deno.test("shape: pre-migration server reports guideError false", () => {
  const row = {
    id: "q3",
    question_text: "x",
    question_type: "short",
    options: [],
    marks: null,
    chapter_number: null,
    answer_key: null,
    guide_error: true,
  };
  assertEquals(shapeSearchRow(row, false)["guideError"], false, "unknown");
});

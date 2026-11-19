// Section groups: the app's Math names match every raw name of the
// same kind; nothing else is folded. Run: deno test (next to list.ts).
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  expandListSection,
  filterListRows,
  isValidListSection,
} from "./list.ts";

Deno.test("mcq_bank matches the raw MCQ names of other subjects", () => {
  const got = expandListSection("mcq_bank")!;
  for (const raw of ["mcq_bank", "mcq-bank", "mcq", "mcq-bank-top-graded"]) {
    assertEquals(got.includes(raw), true);
  }
});

Deno.test("short matches short and short-qa only", () => {
  assertEquals(expandListSection("short"), ["short", "short-qa"]);
});

Deno.test("other sections stay exact; board/model/quiz are not folded", () => {
  assertEquals(expandListSection("creative"), ["creative"]);
  assertEquals(expandListSection("textbook_exercise"), ["textbook_exercise"]);
  const mcq = expandListSection("mcq_bank")!;
  for (const raw of ["board-mcq", "model-mcq", "exercise-mcq", "quiz"]) {
    assertEquals(mcq.includes(raw), false);
  }
  assertEquals(expandListSection(null), null);
});

Deno.test("filterListRows: group filter, null row never matches", () => {
  const rows = [
    { section: "mcq-bank" },
    { section: "mcq_bank" },
    { section: "short-qa" },
    { section: null },
  ] as never[];
  assertEquals(filterListRows(rows, null, "mcq_bank").length, 2);
  assertEquals(filterListRows(rows, null, "short").length, 1);
});

Deno.test("grp_* exam-kind groups expand to exact raw lists and are valid", () => {
  assertEquals(expandListSection("grp_one_word"), ["quiz"]);
  assertEquals(
    expandListSection("grp_knowledge"),
    ["knowledge-qa", "knowledge"],
  );
  assertEquals(
    expandListSection("grp_comprehension"),
    ["comprehension-qa", "understanding-qa", "comprehension"],
  );
  assertEquals(
    expandListSection("grp_math_problem"),
    ["topic-math", "topic-math-bank", "applied-math"],
  );
  assertEquals(
    expandListSection("grp_other_practice"),
    ["viva", "activity", "practical-chunk"],
  );
  assertEquals(expandListSection("grp_exercise"), ["exercise"]);
  assertEquals(expandListSection("grp_activity"), ["activity"]);
  assertEquals(expandListSection("grp_exercise_mcq"), ["exercise-mcq"]);
  for (
    const name of [
      "grp_exercise",
      "grp_activity",
      "grp_exercise_mcq",
      "grp_one_word",
      "grp_knowledge",
      "grp_comprehension",
      "grp_math_problem",
      "grp_other_practice",
    ]
  ) {
    assertEquals(isValidListSection(name), true);
  }
  // raw names keep their exact meaning (old flows are unchanged)
  assertEquals(expandListSection("knowledge"), ["knowledge"]);
  assertEquals(expandListSection("quiz"), ["quiz"]);
});

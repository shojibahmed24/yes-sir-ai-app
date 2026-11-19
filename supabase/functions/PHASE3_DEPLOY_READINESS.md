# Phase 3 Deploy Readiness — Edge-function redeploy after imports

Status: FILE-ONLY PREP COMPLETE. Nothing was deployed, no token
was used, no database was written, no app code was changed.
This document is the deploy runbook for the moment the access
token arrives. Do NOT follow `DEPLOY_PLAN.md` in this folder.

## 0. Stale-doc warning (read first)

`DEPLOY_PLAN.md` (2026-10-30) claims both functions return 404 /
were never deployed. That is OUTDATED and must not be followed:
`guide-bank` was redeployed twice on 2026-11-01 and
`explain-question` is ACTIVE v9. This deploy is a REDEPLOY of
both functions after the Bangla / Paper-II / Biology imports
land. Nothing in this prep changes that deployed history; it
only adds the diffs in §1–§3 below.

## 1. Diff (a) — guide-bank list carries stimulusRef

- `guide-bank/index.ts`, list select (buildQuery, withNewCols
  branch): select string now includes `stimulus_ref` alongside
  `stimulus_id, stimulus_text, flag_note, guide_solution`.
  guide_solution is still selected ONLY to derive the
  hasSolution boolean and never reaches the payload.
- `guide-bank/list.ts`, `shapeListRow`: new field `stimulusRef`
  mapped from `r.stimulus_ref`, gated on `pilotFieldsKnown`
  exactly like `stimulusText` (null on pre-migration servers,
  null when the row carries no reference — never a guessed
  reference).
- Payload-safety comment in `list.ts`, the `list` response doc
  in `index.ts`, and `guide-bank/README.md` updated to list
  `stimulusRef` (and the previously undocumented `flagNote`) in
  the carried fields. The NEVER clause is unchanged: payload
  NEVER carries `answer_key` or `guide_solution` text.
- Effect without an app update: the app's `GuideBankQuestion`
  model already parses `stimulusRef` from list rows, so after
  this redeploy the passage/stimulus header populates from list
  rows that carry a reference. Rows without one report null.

## 2. Diff (b) — section allowlist extended (41 values)

`guide-bank/list.ts`, `LIST_SECTION_VALUES` (exact-match,
case-sensitive; any other non-empty string is still HTTP 400).
Previously only Math: `practice_work, textbook_exercise,
mcq_bank, short, creative`. Now, grouped in code comments:

- Bangla 1st Paper (6 new; `short`, `creative` already listed):
  `quiz, mcq, model-mcq, descriptive, model-creative, bank`.
- English Paper-II (15 new): `gapbox, table, verbs, transform,
  tag, suffix, prefix, preposition, connector, punctuation,
  writing-paragraph, writing-email, writing-letter,
  writing-application, writing-composition`.
- Biology (15 new; `quiz, descriptive, model-mcq,
  model-creative, creative` already listed): `mcq-bank,
  short-qa, model-short, board-mcq, board-creative,
  knowledge-qa, viva, conceptual, rapid-qa, knowledge,
  gyanmulok, anudhabanmulok, activity, comprehension,
  general-qa` (20 sections per the Biology dry-run §3).

Union = 5 + 6 + 15 + 15 = 41 (shared values counted once).

### 'mcq' conflict — resolved deliberately, not silently

`list.test.ts` previously asserted `isValidListSection("mcq")
== false`. That is no longer true: Bangla genuinely uses
section `mcq` (2,351 rows). The test's negative example is now
a string no subject uses (`not_a_section`), and a positive
assertion pins `mcq` as valid. Near-identical spellings remain
DISTINCT exact-match values: `mcq` (Bangla) vs `mcq_bank`
(Math) vs `mcq-bank` (Biology); `short` vs `short-qa`;
`creative` vs `model-creative` / `board-creative`.

### Correction to the prep brief (documented, not silent)

The brief's Paper-II list omitted `prefix`. It is included:
the Paper-II tagging spec makes prefix its own section, and
the Paper-II dry-run audit counts 67 prefix rows. Omitting it
would have left those rows filtering to HTTP 400.

### Deliberately NOT changed

- English Paper-I section values are NOT added. The deployed
  behaviour (section filter 400s for English values) is BY
  DESIGN: the English flow does not filter by section through
  the `list` action. Unchanged.
- The `search` action payload is unchanged (it carries no
  stimulus fields today). Out of scope for this prep.

## 3. Diff (c) — explain-question Mode G carries stimulus

Previously Mode G's guide-question fetch selected only `id,
book_id, chapter_id, question_text, question_type, marks,
answer_key` and returned NO stimulus fields at all.

- `explain-question/index.ts`, Mode G branch: a separate
  try/catch fetch now selects `stimulus_text, stimulus_ref`
  for the same row id, following the existing tag-fetch
  pattern — a server without `stimulus_ref` answers with nulls
  instead of failing Mode G.
- Response now includes `stimulusText` (string | null) and
  `stimulusRef` (string | null), documented in the Mode G
  response contract comment. Absent = null, matching the
  guide-bank list convention (not empty-string guessing).

### Key-name decision — evidence, not a guess

Keys are camelCase `stimulusText` / `stimulusRef` because:

- The guide-bank list payload already uses `stimulusText` /
  `stimulusId`, and the app's `GuideBankQuestion` model parses
  `stimulusRef` (guide_bank_model.dart) — the header widget
  already reads `question.stimulusText` / `question.stimulusRef`
  from list rows.
- The current Mode G consumer
  (`structured_explanation_service.dart`, `_guideContextFrom`)
  reads only the known keys (questionText, marks,
  textbookChunks, fallbackChunk, guideQuestionId, questionType,
  answerKey, groundingSolution, unitKind, verbatimKind,
  verbatimText, correctionNote, guideError, book/chapter
  fields) and ignores unknown keys, and `GroundedContext` has
  no stimulus fields today. So adding these fields is
  ADDITIVE ONLY: no current app path breaks, and a future app
  change can read them for id-only chat paths (e.g. model-test
  Ask-AI) that never saw a list row.
- `stimulusId` was deliberately NOT added to Mode G (brief
  scope: text + ref only; the list payload already carries it).

## 4. Test results (deno 2.9.8, offline)

- `guide-bank`: 31 passed, 0 failed (was 30; +1 new test
  "sections: Bangla/Paper-II/Biology values are valid" pinning
  the 36 new values, the 41-value union, and the distinct mcq
  spellings; `mcq` negative example replaced as in §2).
- `explain-question`: 17 passed, 0 failed (unchanged; Mode G
  has no offline test harness because `index.ts` imports
  supabase-js — its verification is the live probe in §6).
- `deno check` on both `index.ts` files: `guide-bank/index.ts`
  is CLEAN (0 errors). `explain-question/index.ts` reports 11
  PRE-EXISTING type errors, NONE on the new lines: lines 278
  and 520 (Dart-style `.where` on arrays in Mode A/B code) and
  lines 630–633, 724–725, 731 (untyped-query `GenericStringError`
  on the pre-existing `gq.*` accesses). The new stimulus lines
  (fetch ~608–628, response ~733–734) carry no errors. No test
  was weakened to force green; no refactor of the pre-existing
  errors was attempted (unrelated to this prep; the deployed v9
  runs this same code today).

## 5. Deploy command (run when the token arrives)

From `~/workspace/yes-sir-ai-app`, token via environment only
(never in a file, command string, or log):

```
cd ~/workspace/yes-sir-ai-app
SUPABASE_ACCESS_TOKEN=<token-from-user> \
  ~/.supabase/bin/supabase functions deploy guide-bank explain-question \
  --project-ref vvyiwyzredqoulufqgmg
```

- Deploy BOTH functions in one command. Do NOT pass
  `--no-verify-jwt` (verify_jwt stays true per the function
  READMEs). Do NOT pass `--prune`.
- Deploy AFTER the Bangla / Paper-II / Biology imports land,
  so the §6 probes have data to check against. The deploy
  itself does not depend on the data.
- Supabase CLI 2.122.0 at `~/.supabase/bin/supabase` (not on
  PATH). Project ref: `vvyiwyzredqoulufqgmg`.
  Functions base URL:
  `https://vvyiwyzredqoulufqgmg.supabase.co/functions/v1/`.

## 6. Live verification probes (after deploy)

Probe contract (already established): POST with `apikey` and
`Authorization: Bearer <anon-key>` headers; the anon key is
public by design — it is NOT pasted here, take it from the
app's `dart_defines.json`. Substitute real ids from the import
audits where a placeholder is shown. All probes must return
HTTP 200 except probe 6 (HTTP 400 by design).

1. Bangla `mcq` section now passes the allowlist (was 400):
   POST `guide-bank`, body
   `{ "action": "list", "classId": 9, "subject": "bangla",
     "chapterless": true, "section": "mcq", "limit": 5 }`.
   Expect `found: true`, rows present, each row carrying
   `stimulusRef` (string or null — never absent as a key).
2. Paper-II `prefix` section passes (was 400):
   body as above with `"subject": "english-2nd",
   "section": "prefix"`. Expect `found: true`.
3. Biology `board-mcq` section passes (was 400):
   body as above with `"subject": "biology",
   "section": "board-mcq"`. Expect `found: true`.
4. Mode G stimulus for a passage row (example id from the
   Paper-I backfill audit, a row known to carry passage text):
   POST `explain-question`, body
   `{ "guideQuestionId": "eng1-p161-poem-q8d",
     "language": "en" }`.
   Expect `found: true`, `stimulusText` a non-empty string,
   `stimulusRef` a non-empty string.
5. Mode G no-regression for a row without stimulus:
   same call with a Math guide row id from the Math audit.
   Expect `found: true`, `stimulusText: null`,
   `stimulusRef: null` (no failure, no invented reference).
6. Invalid section still rejected:
   `guide-bank` list body with `"section": "not_a_section"`.
   Expect HTTP 400 (unchanged behaviour).
7. Payload safety spot-check on any probe-1 row:
   response JSON must NOT contain the strings `answer_key` or
   `guide_solution` as keys.

## 7. Still needs a decision (not a deploy blocker)

- App-side use of the new Mode G fields: the deploy alone does
  not wire any chat UI to `stimulusText` / `stimulusRef` from
  Mode G — id-only chat paths still get their stimulus from
  the guide-bank list row today, exactly as before. Whether a
  future app change should read the Mode G fields (so id-only
  paths show the stimulus without a list fetch) is an app
  decision for later; it does not block this redeploy, and the
  fields will be present whenever that change lands.
- Nothing else in this prep is undecided: the allowlist values
  are taken from the three dry-run reports, the `mcq`
  conflict and the `prefix` omission are resolved above with
  evidence, and the Mode G key names follow the existing app
  model.

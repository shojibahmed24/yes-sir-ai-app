# Edge Function: `guide-bank`

Server-side list reader for `guide_questions` (migration `008`).
The Flutter app must never query that table directly (008 gives it
no client read policy on purpose). This function is the only path
from the guide bank UI to chapter lists and model-test set metadata.

## What it does

- `list`: given `{ action: 'list', classId, subject, chapter?,
  setId?, type?, importantOnly?, marks?, page?, pageSize?,
  lesson?, section?, offset?, limit? }`,
  returns one page of that chapter's bank rows (or one
  model-test set's rows when `setId` is given), ordered by id,
  with an exact total count (the full filtered count, never the
  page length). `lesson` (e.g. "2.1") and `section` (one of
  LIST_SECTION_VALUES in list.ts — Math, Bangla, Paper-II,
  Biology values) filter server-side by exact equality; omitted means
  all. `offset` (default 0, >= 0) + `limit` (default 20, clamped
  1..50) are the new pagination; legacy `page`/`pageSize`
  (pageSize capped at 20) still work, with offset/limit winning
  when both are sent. Invalid lesson/section values are HTTP
  400, never silently dropped. On a pre-migration server
  (42703), unfiltered requests retry without pilot fields, but
  filtered requests return `{ found: false, reason:
  'pilot-columns-missing' }` — never unfiltered rows. Rows carry
  `id, questionText, questionType, options, marks, important,
  setId, hasKey, guideError, lesson, section, stimulusId,
  stimulusText, stimulusRef, flagNote, hasSolution` — NEVER `answer_key`, NEVER
  `guide_solution`. `hasSolution` is true iff a solution is
  stored (non-null, non-empty); pilot fields are null when the
  row is untagged, and null (unknown) on pre-migration servers.
  Chapter bank lists exclude model-test rows (`set_id` null only).
  Empty chapter/bank => `found: true, total: 0, questions: []`.
- `sets`: given `{ action: 'sets', classId, subject }`, returns
  distinct non-null set_ids with `totalCount` / `keyedCount`
  (metadata only, no rows). Unkeyed rows are never scored.
- `guideChapters`: given `{ action: 'guideChapters', classId,
  subject }`, returns `[{ chapter, totalCount, keyedCount }]`
  for bank rows (set_id NULL) grouped by guide chapter number,
  sorted by chapter. Counts are EXACT: distinct chapters are
  paged first, then one exact head-count per chapter (total +
  keyed) — never a capped row sample. Pre-migration servers
  (chapter_number absent) fall back to textbook-chapter
  grouping. Rows with chapter_number NULL are excluded, so
  classes whose old rows lack the column (class 7) return empty
  until a backfill decision.
- `search`: given `{ action: 'search', classId, subject, query,
  limit? }`, returns at most 50 bank rows (set_id NULL, no
  chapter filter) whose question_text contains the query as a
  case-insensitive substring, ordered by chapter_number then
  id. Rows carry `id, questionText, questionType, options,
  marks, chapterNumber, hasKey, guideError` — NEVER `answer_key`,
  NEVER `guide_solution`. A blank query returns an empty list,
  never the whole guide. `limit` is clamped to 1..50 server-side
  (default 50).
- Unknown class/subject => `found: false, reason: 'no-book'`.
- Tables missing (008 not applied) => HTTP 500
  `{ error: 'guide-tables-missing' }` — an error, never an empty
  list, so the client shows unavailable, not empty.

## What it does NOT do

- No answer keys, no worked solutions, no whole-guide dumps.
  Detail/answer fetching stays with `explain-question` Mode G,
  which enforces the key-check gate and the paywall gate.
- No data is written here; no demo data is ever returned.

## Deploy

Deploy with `verify_jwt = true` (the default) — do NOT disable
it. The function additionally requires an `Authorization` header
and reads `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` from the
function environment. No key is stored in this folder.

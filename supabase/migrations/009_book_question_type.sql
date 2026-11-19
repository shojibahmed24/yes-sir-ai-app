-- 009: question_type on public.book_questions (textbook chapter list).
-- NEW file: never edit 001-008. Run after 001-008.
--
-- WHAT THIS ADDS: one nullable TEXT column, question_type, on
-- public.book_questions. It carries the LOWER-CASE canonical type
-- of the printed textbook question (mcq, fill_blank, creative,
-- short, problem, task, descriptive, boxed_kaj, other, plus any
-- other verbatim file value lowercased by the backfill — see
-- supabase/tools/backfill_book_question_type.py). The Edge
-- function listByChapter (Mode L) selects this column so the
-- chapter list can be filtered by type client-side; guide rows
-- are unaffected (guide_questions already has question_type
-- from migration 008).
--
-- WHAT THIS DOES *NOT* ADD — NO MARKS COLUMN, ON PURPOSE:
-- NCTB textbook questions carry NO printed marks. A marks column
-- on book_questions would have to be invented per row, and
-- invented marks presented to students would be dishonest
-- grounding. Marks exist ONLY on guide_questions (migration
-- 008), where the guide itself prints them. The chapter-list
-- client must therefore offer a type filter but NEVER a marks
-- filter for textbook rows (guide bank lists, served by the
-- guide-bank function, are the only place a marks filter is
-- honest). If printed marks for textbooks ever appear in a
-- verified source, that is a NEW migration with its own
-- provenance, not a quiet addition here.
--
-- IDEMPOTENT: ADD COLUMN IF NOT EXISTS, so re-running this file
-- is safe. No data is inserted here: the backfill script
-- (supabase/tools/backfill_book_question_type.py) fills the
-- column from the local per-book JSONs, UPDATEing only rows
-- that are currently NULL, inside one verified transaction.
--
-- *** DEPLOY ORDERING — READ BEFORE DEPLOYING ***
-- 1. Apply this migration (009) to the live database.
-- 2. Run the backfill script in live mode (parent runs it with
--    the transient password; it verifies every id exists and
--    the updated count matches before COMMIT).
-- 3. ONLY THEN deploy the explain-question function containing
--    listByChapter's question_type select.
-- Deploying step 3 before steps 1-2 does NOT crash the list:
-- the handler retries without the column (Postgres 42703) and
-- returns questionType: null for every row — but the client
-- then cannot filter by type (every row lands under অন্যান্য),
-- and every list call pays one failed select. So the ordering
-- above is required for a CORRECT list, not just a live one.
-- The by-question-id mode (Mode Q) selects NO question_type
-- column, does NOT depend on this migration, and may deploy
-- earlier — before, between, or independently of steps 1-3.
-- Nothing in this file changes RLS: book_questions keeps NO
-- client read policy (002); only the Edge Function (service
-- role) reads it.

alter table public.book_questions
  add column if not exists question_type text;

comment on column public.book_questions.question_type is
  'Lowercase canonical type of the printed textbook question '
  '(mcq, fill_blank, creative, short, problem, task, descriptive, '
  'boxed_kaj, other, or another verbatim file value lowercased). '
  'NULL = file had no type (untyped rows stay visible under other, '
  'never hidden by a type filter). Deliberately NO marks column: '
  'NCTB textbook questions carry no printed marks.';

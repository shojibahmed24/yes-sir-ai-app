-- Phase 3 (2026-11-02): Paper-II Q10-12 model link.
-- Each Q10-12 test row points at its bank model row (eng1- id)
-- in the same table; NULL = no link (all non-Q10-12 rows).
-- No FK: ids are guide-archive ids, and the backfill verifies
-- every target exists before writing.
ALTER TABLE public.guide_questions
  ADD COLUMN IF NOT EXISTS model_question_id text;
COMMENT ON COLUMN public.guide_questions.model_question_id IS
  'Linked bank model row id (Paper-II Q10-12 test row -> eng1- bank row); NULL = no link.';

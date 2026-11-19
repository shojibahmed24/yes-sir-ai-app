-- Phase ICT (2026-11-02): printed per-question explanation for
-- guide rows. ICT bank MCQs print a "তথ্য/ব্যাখ্যা" paragraph after
-- the answer; it is content, not a flag note, so it gets its own
-- column instead of being folded into guide_solution or flag_note.
-- Nullable: every pre-ICT row keeps NULL, and the Edge/app read it
-- in a try/catch so a pre-migration server answers with nulls
-- instead of failing. No RLS change: Edge reads via service role.
ALTER TABLE public.guide_questions
  ADD COLUMN IF NOT EXISTS explanation text;
COMMENT ON COLUMN public.guide_questions.explanation IS
  'Printed per-question explanation (ICT bank-MCQ তথ্য/ব্যাখ্যা paragraph), verbatim; NULL = guide prints none.';

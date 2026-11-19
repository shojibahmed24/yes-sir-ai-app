-- 012: correction store for guide rows (verbatim-first, 2026-10-31).
--
-- WHY: printed guide answers are sometimes wrong (class-7: 18
-- guide-error MCQs; Talimit: 1 excluded row). The printed value
-- must NEVER be overwritten — it stays in answer_key with
-- guide_error=true — so the verified correction lives here, in
-- its own columns, with a human-readable note. The app shows
-- the correction WITH its note ("printed answer was wrong"),
-- never passing a correction off as the guide's own text.
--
-- No values are backfilled here: corrections are curated row by
-- row (log file -> these columns) in a later data pass, per the
-- owner's "data fixes later" order. Until then both columns stay
-- NULL and verbatim display falls back to guide text (or none
-- for uncorrected error rows).
alter table public.guide_questions
  add column if not exists corrected_answer_key text,
  add column if not exists correction_note text;

comment on column public.guide_questions.corrected_answer_key is
  'Verified correct answer/key for a guide_error row (migration 012). NULL = no correction curated yet; a corrected row must never be auto-scored on this value without a separate owner decision.';
comment on column public.guide_questions.correction_note is
  'Human-readable note shown with a correction, e.g. why the printed answer was wrong (migration 012).';

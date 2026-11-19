-- 011: guide-native chapter number on guide_questions.
--
-- WHY: textbook chapters and guide chapters carry the SAME
-- chapter number (user-confirmed 2026-10-31), but a guide for a
-- class whose textbooks are not in the DB yet (Talimit class-9
-- math) has no textbook chapters rows to point chapter_id at.
-- chapter_number lets guide-bank resolve a chapter by number
-- through EITHER system: textbook chapter_id OR this column.
-- Set rows (model tests) are chapter-free: chapter_number NULL
-- with set_id set, served by book_id + set_id.
--
-- Backfill for pre-011 rows is intentionally NOT done here:
-- class-7 guide rows keep chapter_id -> textbook chapters and
-- resolve through system 1; only newly imported guide rows
-- carry chapter_number. The Edge list filter is an OR of both,
-- so old and new rows coexist without a rewrite.
alter table public.guide_questions
  add column if not exists chapter_number int;

comment on column public.guide_questions.chapter_number is
  'Guide-native chapter number (migration 011). Same number as the textbook chapter; used when no textbook chapters exist yet. NULL for model-test set rows.';

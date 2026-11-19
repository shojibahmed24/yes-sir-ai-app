-- 013: pilot lesson/section/tag columns for guide_questions (Class 9 Math Ch2 pilot, lesson 2.1).
-- All nullable; existing rows stay untouched. Applied live 2026-10-31 with the 2.1 pilot import.
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS lesson TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS section TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS stimulus_id TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS stimulus_text TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS source_pdf_page INTEGER NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS source_printed_page INTEGER NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS has_diagram BOOLEAN NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS diagram_note TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS flag_note TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS note TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS marks_parts JSONB NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS board_name TEXT NULL;
ALTER TABLE guide_questions ADD COLUMN IF NOT EXISTS board_year INTEGER NULL;

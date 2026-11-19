-- 008: guide tables — Tier 2 practice bank (textbooks stay pure).
-- NEW file: never edit 001-007. Run after 001-007.
--
-- WHAT THESE TABLES ARE: guide_questions / guide_chunks hold the
-- Class 7+ guide extraction (see yes-sir-ai-guides/PLAN.md §3).
-- They are SEPARATE from book_questions / book_chunks on purpose:
-- mixing guide rows into textbook tables would break Tier 1 purity,
-- chapter counts, and every verification the app already passed.
--
-- TABLES STAY EMPTY AFTER THIS MIGRATION. No data is inserted
-- here. The data-migration run (single INSERTs with ON CONFLICT
-- DO NOTHING, from the pilot's final consolidated files) is a
-- SEPARATE step that needs the user's transient password +
-- approval, and it runs only after the Math pilot's final
-- consolidation. Until then, Edge Mode G returns
-- 'guide-unavailable' and the bank UI shows honest empty /
-- unavailable states — never demo data.
--
-- guide_solution (TEXT NULL) — WHY THIS COLUMN EXISTS: the locked
-- question-wise primary design (PLAN.md §4, 2026-10-29) sends the
-- AI the question's OWN unit: the printed key for MCQ/short, the
-- worked solution as HIDDEN grounding for creative/long/Math.
-- That unit must be queryable by question id. Prose fallback
-- chunks alone would break the design (they are chapter-level,
-- capped at 1, and only a fallback). Mode G in
-- supabase/functions/explain-question already selects this column
-- optionally (absent column => empty string, fallback chunk
-- instead). NULL = no worked solution stored for this row (e.g.
-- MCQ rows, whose unit is the printed key).
--
-- options (JSONB NULL) — NOTE ON PLAN §3: the plan's column list
-- omits options, but the pilot's typed extraction stores verbatim
-- MCQ options (object keyed by ক/খ/গ/ঘ, or an array) and the
-- Flutter client model requires them to display an MCQ at all.
-- Options are QUESTION CONTENT (shown to students), NOT keys:
-- answer_key stays a separate column and is NEVER served in list
-- responses (only a has_key boolean). Without this column every
-- imported MCQ would lose its options, so it is included here
-- deliberately; the data-migration maps pilot options into it.
-- Non-MCQ rows leave it NULL.
--
-- guide_chunks mirrors migration 007's book_chunks columns exactly
-- (PLAN §3 says "14 columns"; 007 actually defines 15, so the
-- mirror wins over the plan's arithmetic) + guide_source.
-- File-stage-only provenance (difficulty, section, verification
-- notes) is deliberately NOT carried: the data-migration drops it.
--
-- SERVER-ONLY, same rule as book_questions / book_chunks: RLS
-- enabled with NO client policy. Only Edge Functions (service
-- role) may read these tables, so the guide bank cannot be
-- scraped from the app.
create table if not exists public.guide_questions (
  id text primary key,
  book_id text not null references public.books (id) on delete cascade,
  chapter_id text references public.chapters (id) on delete set null,
  -- Filename + guide page, e.g. '06-Math-Guide.pdf p10'.
  guide_source text not null default '',
  question_text text not null check (char_length(question_text) > 0),
  question_type text not null,
  -- Verbatim MCQ options (JSON object keyed ক/খ/গ/ঘ, or array).
  -- NULL for non-MCQ rows. Question content, NOT a key.
  options jsonb,
  -- Printed key ONLY (MCQ letter / short-answer text).
  -- NULL for creative/long (their unit is guide_solution).
  -- NEVER served in list responses; Mode G serves it for the
  -- single opened question under the key-check gate.
  answer_key text,
  -- Worked solution as HIDDEN grounding for creative/long/Math.
  -- Never rendered verbatim; never served in list responses.
  guide_solution text,
  -- Printed marks ONLY. NULL = not printed (never invented).
  marks int,
  -- Printed importance ONLY. False unless the guide prints it.
  important boolean not null default false,
  -- NULL = chapter bank; 'model-test-<n>' = model-test set.
  set_id text,
  verified_visual boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists guide_questions_chapter
  on public.guide_questions (chapter_id);
create index if not exists guide_questions_set
  on public.guide_questions (set_id);
create index if not exists guide_questions_book_chapter
  on public.guide_questions (book_id, chapter_id);
alter table public.guide_questions enable row level security;
-- Deliberately NO select/insert/update/delete policy for clients.
-- Service-role (Edge Functions) bypasses RLS; anon/authenticated
-- clients cannot read guide rows directly.

create table if not exists public.guide_chunks (
  id text primary key,
  book_id text not null references public.books (id) on delete cascade,
  chapter_id text references public.chapters (id) on delete set null,
  language text not null check (language in ('bn', 'en')),
  -- PRINTED guide pages (what the student sees in the guide).
  page_start int not null,
  page_end int not null,
  -- PDF pages of the guide scan, where distinguishable.
  pdf_page_start int,
  pdf_page_end int,
  -- 1-based index of the chunk inside its chapter.
  chunk_index int not null,
  -- Guide text (notes/summary), corrected per the quality gate.
  chunk_text text not null check (char_length(chunk_text) > 0),
  word_count int not null check (word_count > 0),
  -- Source PDF filename only (never a full local path, never a key).
  source_pdf text not null,
  ocr_engine text not null default 'tesseract',
  ocr_confidence_note text not null default '',
  -- Filename + guide page range for this chunk.
  guide_source text not null default '',
  created_at timestamptz not null default now(),
  check (page_end >= page_start),
  check (pdf_page_end is null or pdf_page_start is null
    or pdf_page_end >= pdf_page_start)
);
create unique index if not exists guide_chunks_book_chapter_index
  on public.guide_chunks (book_id, chapter_id, chunk_index);
create index if not exists guide_chunks_book_page
  on public.guide_chunks (book_id, page_start);
create index if not exists guide_chunks_book_chapter
  on public.guide_chunks (book_id, chapter_id);
alter table public.guide_chunks enable row level security;
-- Deliberately NO select/insert/update/delete policy for clients.
-- Service-role (Edge Functions) bypasses RLS; anon/authenticated
-- clients cannot read chunks directly.

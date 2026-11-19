-- 007: book_chunks — one-time OCR text chunks for book-grounded AI.
-- Run after 001-006. This table is SERVER-ONLY, same rule as
-- book_questions in migration 002: NO client read policy on purpose.
-- Only the explain-question Edge Function (service role) may read
-- chunks, so the grounding index cannot be scraped from the app.
-- chunk_text is OCR text, verbatim as OCR'd. It is NOT a printed
-- answer key and must never be presented to a student as one;
-- OCR errors (especially Bengali conjuncts under tesseract) are
-- possible, and the import contract records them per book.
--
-- ID format (supplied by the import, never generated here):
--   {book_id}-chunk-{chapter_number}-{chunk_index}
--   e.g. class6-science-bn-chunk-1-003
-- chapter_id uses the LIVE DB format from book_import.sql:
--   {book_id}-ch{number}  (NO zero padding: -ch1, not -ch01)
-- NOTE: supabase/chapter_page_map.json writes -ch01; the chunk
-- pipeline MUST normalise -ch01 -> -ch1 before import, or the
-- foreign key below will fail.
create table if not exists public.book_chunks (
  id text primary key,
  book_id text not null references public.books (id) on delete cascade,
  chapter_id text references public.chapters (id) on delete set null,
  language text not null check (language in ('bn', 'en')),
  -- PRINTED book pages (what the student sees in the book).
  page_start int not null,
  page_end int not null,
  -- PDF pages (printed + 5 for the core NCTB books; recorded where
  -- distinguishable, so a chunk can be re-checked against the scan).
  pdf_page_start int,
  pdf_page_end int,
  -- 1-based index of the chunk inside its chapter.
  chunk_index int not null,
  -- OCR text, verbatim as OCR'd. Do NOT clean it into invented
  -- wording and do NOT fabricate missing words.
  chunk_text text not null check (char_length(chunk_text) > 0),
  word_count int not null check (word_count > 0),
  -- Source PDF filename only (never a full local path, never a key).
  source_pdf text not null,
  ocr_engine text not null default 'tesseract',
  ocr_confidence_note text not null default '',
  created_at timestamptz not null default now(),
  check (page_end >= page_start),
  check (pdf_page_end is null or pdf_page_start is null
    or pdf_page_end >= pdf_page_start)
);
create unique index if not exists book_chunks_book_chapter_index
  on public.book_chunks (book_id, chapter_id, chunk_index);
create index if not exists book_chunks_book_page
  on public.book_chunks (book_id, page_start);
create index if not exists book_chunks_book_chapter
  on public.book_chunks (book_id, chapter_id);
alter table public.book_chunks enable row level security;
-- Deliberately NO select/insert/update/delete policy for clients.
-- Service-role (Edge Function) bypasses RLS; anon/authenticated
-- clients cannot read chunks directly.

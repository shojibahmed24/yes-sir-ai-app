-- 010: guide_error exposure + tagged-prose dependency link (Phase 2).
-- NEW file: never edit 001-009. Run after 001-009.
--
-- guide_error: live DB already carries guide_questions.guide_error
-- (added 2026-10-29 outside a migration file), but no migration
-- file ever recorded it, so a fresh DB built from 001-009 alone
-- would lack the column the guide-bank list now selects. This
-- migration records it idempotently: ADD COLUMN IF NOT EXISTS,
-- so it is a no-op on the live DB and a real column on fresh DBs.
--
-- linked_prose_chunk_id: the dependency-link column the
-- no-neighbour rule always required for a fallback (user order
-- 2026-10-30: fallback = ONLY the prose the question actually
-- depends on, max 1; never neighbours, never chapter filler).
-- A guide question tags AT MOST ONE guide_chunks row it depends
-- on. NULL = no linked prose, and then Mode G returns
-- fallbackChunk null exactly as before — an untagged question
-- never gains filler. Tags are CURATION, not inference: no
-- existing row is tagged by this migration, and no tag may ever
-- be auto-invented by a script. Tagging happens row by row when
-- a human (or a verified extraction pass) proves the question
-- depends on that prose. Until tags exist, the fallback stays
-- zero — the mechanism existing is not the same as tags existing,
-- and this file must not be read as claiming otherwise.
--
-- Textbook (book_chunks) tagging is NOT in this migration: Mode A
-- has no fallbackChunk field in its response, so a book_chunks
-- link column today would be unused schema. When Mode A wiring
-- is ordered, it gets its own migration + Edge + client change.
-- guide_chunks-to-guide_chunks links are likewise not added:
-- prose does not need to tag prose for this feature.
DO $$
BEGIN
  BEGIN
    ALTER TABLE public.guide_questions
      ADD COLUMN guide_error boolean NOT NULL DEFAULT false;
  EXCEPTION WHEN duplicate_column THEN NULL;
  END;
  BEGIN
    ALTER TABLE public.guide_questions
      ADD COLUMN linked_prose_chunk_id text
        REFERENCES public.guide_chunks (id) ON DELETE SET NULL;
  EXCEPTION
    WHEN duplicate_column THEN NULL;
  END;
END $$;

COMMENT ON COLUMN public.guide_questions.guide_error IS
  'True when the printed key/solution for this row is proven wrong; such rows must never be scored.';
COMMENT ON COLUMN public.guide_questions.linked_prose_chunk_id IS
  'At most one guide_chunks row this question depends on (human-curated tag only, never auto-invented). NULL = no linked prose; Mode G then returns fallbackChunk null.';

-- Phase 3 (2026-11-02): per-set metadata for Bangla model tests.
-- Grade bands VARY per lesson, so they live here, never as a
-- global copy. Read by the guide-bank sets action (service role);
-- Edge is the only reader, so no RLS policy is added.
CREATE TABLE IF NOT EXISTS public.guide_set_metadata (
  book_id text NOT NULL,
  set_id text NOT NULL,
  lesson text,
  kind text,
  total_marks integer,
  time_minutes integer,
  grade_bands jsonb NOT NULL,
  PRIMARY KEY (book_id, set_id)
);
COMMENT ON TABLE public.guide_set_metadata IS
  'Per-set metadata (Bangla model-test grade bands as printed, normalised [lo,hi]); backfilled from import_bangla1st_audit.json.';

-- Phase Biology-Others (2026-11-02): out-of-syllabus flag for
-- guide rows. Biology board items marked out-of-syllabus on the
-- paper were held at collection and never imported; the user
-- orders them visible under a chapter-like "Others" grouping
-- instead of inside their board sets/chapters. The flag is what
-- moves a row into that grouping: the Edge list action serves
-- flagged rows ONLY under the others scope and excludes them
-- from chapter/set/chapterless scopes, so no row is ever shown
-- twice. Nullable with no default change for old rows: every
-- pre-existing row keeps NULL (= not flagged), and the Edge/app
-- read it in a try/catch so a pre-migration server answers
-- with nulls/false instead of failing. No RLS change: Edge
-- reads via service role.
ALTER TABLE public.guide_questions
  ADD COLUMN IF NOT EXISTS out_of_syllabus boolean;
COMMENT ON COLUMN public.guide_questions.out_of_syllabus IS
  'True = guide item flagged out-of-syllabus on the paper (Biology board items); shown only under the Others grouping, never in its set/chapter list. NULL/false = in-syllabus.';

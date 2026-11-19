-- 019: reference data readable by anonymous clients too.
-- The app reads subjects/classes/chapters with the anon key
-- before sign-in, but the 002 policies allow only
-- auth.role() = 'authenticated', so anon reads returned zero
-- rows and Home could show no subjects at all. This adds anon
-- SELECT on the three reference tables only. The books table
-- stays blocked (source_link is server-only; clients read books
-- via the books_public view) and book_questions stays blocked
-- (server / Edge only). NOT APPLIED YET: needs a DB apply with
-- owner credentials (2026-11-04).
create policy "reference read anon" on public.classes
  for select using (auth.role() = 'anon');
create policy "reference read anon" on public.subjects
  for select using (auth.role() = 'anon');
create policy "reference read anon" on public.chapters
  for select using (auth.role() = 'anon');

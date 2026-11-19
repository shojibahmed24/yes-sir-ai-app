-- 014: guardian columns on profiles + backfill from parent_links.
-- Run after 001 (parent_links) and 013. Run ONCE: Supabase records
-- applied migrations, so this file is never re-run in practice.
--
-- Why: guardian name/phone used to live in two places that never
-- met — the phone's local profile JSON and the parent_links table
-- (registration wrote it there, but the app never read it back, so
-- a fresh install showed an empty guardian and there was no way to
-- edit it after registration). From here on profiles is the single
-- home: the app's profileRemoteColumns set includes both names, so
-- restore-merge, login backfill and Settings edits all carry them
-- automatically. parent_links is kept as history only and is no
-- longer written by the app.
--
-- No RLS change: the existing "own profile write" policy already
-- covers a user updating their own row, guardian columns included.
alter table if exists public.profiles
  add column if not exists guardian_name text not null default '',
  add column if not exists guardian_phone text not null default '';

-- Backfill: each student's LATEST parent_links row wins (a
-- re-registration inserted a second row instead of upserting, so
-- "latest" is the only honest pick). Students with no parent_links
-- row keep the '' defaults; their guardian arrives via the next
-- login backfill or a Settings edit instead.
update public.profiles p
set guardian_name = pl.guardian_name,
    guardian_phone = pl.guardian_phone
from (
  select distinct on (student_id) student_id, guardian_name, guardian_phone
  from public.parent_links
  order by student_id, created_at desc
) pl
where p.id = pl.student_id;

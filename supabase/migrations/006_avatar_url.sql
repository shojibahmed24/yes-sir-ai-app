-- 006: profile picture URL (batch 2, item 6). Run after 001.
-- The app stores the picked picture locally first (profile JSON key
-- avatar_local_path, device-only) and, when signed in, uploads it to
-- the Storage bucket 'avatars' and saves the public URL here. The
-- bucket itself + its storage policies are dashboard steps, not SQL:
-- create a bucket named 'avatars' and allow each authenticated user
-- to upload/read only '<their-uid>/avatar.jpg'. If this column is
-- missing on a live database, the app still works: the profiles
-- upsert retries without avatar_url, so name edits are never blocked
-- and the picture simply stays local-only until 006 is applied.
alter table if exists public.profiles
  add column if not exists avatar_url text not null default '';

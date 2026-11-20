-- 022_avatars_bucket.sql
--
-- Profile photos live in the `avatars` bucket (the app already
-- uploads to it and saves the public URL in profiles.avatar_url; the
-- bucket/policies were never created, so every upload failed and the
-- photo stayed on the device only).
--
-- Public read: the stored URL is shown on Home/Profile. Writes are
-- restricted to the owner's folder (<uid>/avatar.jpg), which the
-- uploader already uses.
--
-- WRITE: apply only with the owner's one-time permission.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "avatar read" on storage.objects;
create policy "avatar read" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatar write own" on storage.objects;
create policy "avatar write own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatar update own" on storage.objects;
create policy "avatar update own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatar delete own" on storage.objects;
create policy "avatar delete own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

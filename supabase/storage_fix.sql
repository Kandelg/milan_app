-- Milan — Storage bucket fix
--
-- Run this once in the Supabase SQL editor (Dashboard → SQL → New query)
-- when the app reports: "Bucket not found" while uploading profile photos.
--
-- It (re)creates the `profile-photos` bucket and its access policies.

-- ---------------------------------------------------------------------------
-- 1. Create the public bucket for profile photos.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do update set public = true;

-- ---------------------------------------------------------------------------
-- 2. Policies on storage.objects for the `profile-photos` bucket.
-- ---------------------------------------------------------------------------

-- Anyone signed in may read photos.
drop policy if exists "profile photos are publicly readable" on storage.objects;
create policy "profile photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'profile-photos');

-- Users may only upload into their own folder (`<userId>/...`).
drop policy if exists "users upload their own photos" on storage.objects;
create policy "users upload their own photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users update their own photos" on storage.objects;
create policy "users update their own photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "users delete their own photos" on storage.objects;
create policy "users delete their own photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

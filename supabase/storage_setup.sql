-- 1. Create the storage bucket (Idempotent)
insert into storage.buckets (id, name, public)
values ('carousel-images', 'carousel-images', true)
on conflict (id) do nothing;

-- 2. Policies
-- We remove the 'alter table' command as it causes permission errors and RLS is usually enabled by default on storage.objects.

-- Policy: Allow public read access to the bucket
drop policy if exists "Public View" on storage.objects;
create policy "Public View"
  on storage.objects for select
  using ( bucket_id = 'carousel-images' );

-- Policy: Allow anonymous uploads (Necessary since Admin Panel uses Firebase Auth, not Supabase Auth)
drop policy if exists "Anon Upload" on storage.objects;
create policy "Anon Upload"
  on storage.objects for insert
  with check ( bucket_id = 'carousel-images' );

-- Policy: Allow anonymous updates (For managing slides)
drop policy if exists "Anon Update" on storage.objects;
create policy "Anon Update"
  on storage.objects for update
  using ( bucket_id = 'carousel-images' );

-- Policy: Allow anonymous deletes
drop policy if exists "Anon Delete" on storage.objects;
create policy "Anon Delete"
  on storage.objects for delete
  using ( bucket_id = 'carousel-images' );

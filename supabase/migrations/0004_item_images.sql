-- ReLearn 0004: item image storage.
-- Public-read bucket for catalogue images. Only admins can upload, replace or
-- remove files. The app stores the resulting public URL on the item row.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'item-images',
  'item-images',
  true,
  5242880, -- 5 MB
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Anyone may view catalogue images; they are public product photos.
drop policy if exists item_images_public_read on storage.objects;
create policy item_images_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'item-images');

-- Only active admins may write. RLS on storage.objects is the boundary, so a
-- collector cannot upload even with a valid session.
drop policy if exists item_images_admin_insert on storage.objects;
create policy item_images_admin_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'item-images' and public.is_admin());

drop policy if exists item_images_admin_update on storage.objects;
create policy item_images_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'item-images' and public.is_admin())
  with check (bucket_id = 'item-images' and public.is_admin());

drop policy if exists item_images_admin_delete on storage.objects;
create policy item_images_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'item-images' and public.is_admin());

-- Item rows keep the public URL returned by Supabase Storage.
alter table public.materials add column if not exists image_url text;
alter table public.rewards add column if not exists image_url text;

-- SASTIFY Welcome Page CMS
-- Run once in Supabase SQL Editor. Safe to re-run.
create table if not exists public.site_content (
  id text primary key check (id = 'welcome'),
  draft jsonb not null default '{}'::jsonb,
  published jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  updated_by uuid references auth.users(id)
);
alter table public.site_content enable row level security;
drop policy if exists "Owner can manage welcome content" on public.site_content;
create policy "Owner can manage welcome content"
on public.site_content for all to authenticated
using (exists (select 1 from public.admin_access aa where aa.user_id = auth.uid() and aa.access_level = 'owner'))
with check (exists (select 1 from public.admin_access aa where aa.user_id = auth.uid() and aa.access_level = 'owner'));
revoke all on public.site_content from anon, authenticated;
grant select, insert, update on public.site_content to authenticated;
create or replace function public.get_published_welcome()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(published, '{}'::jsonb)
  from public.site_content
  where id = 'welcome'
  limit 1;
$$;
revoke all on function public.get_published_welcome() from public;
grant execute on function public.get_published_welcome() to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('site-assets','site-assets',true,5242880,array['image/jpeg','image/png','image/webp','image/gif','image/svg+xml'])
on conflict (id) do update set public=true, file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png','image/webp','image/gif','image/svg+xml'];
drop policy if exists "Public can view SASTIFY site assets" on storage.objects;
create policy "Public can view SASTIFY site assets" on storage.objects
for select to public using (bucket_id='site-assets');
drop policy if exists "Owner can upload SASTIFY site assets" on storage.objects;
create policy "Owner can upload SASTIFY site assets" on storage.objects
for insert to authenticated with check (
 bucket_id='site-assets' and exists(select 1 from public.admin_access aa where aa.user_id=auth.uid() and aa.access_level='owner')
);
drop policy if exists "Owner can update SASTIFY site assets" on storage.objects;
create policy "Owner can update SASTIFY site assets" on storage.objects
for update to authenticated using (
 bucket_id='site-assets' and exists(select 1 from public.admin_access aa where aa.user_id=auth.uid() and aa.access_level='owner')
) with check (
 bucket_id='site-assets' and exists(select 1 from public.admin_access aa where aa.user_id=auth.uid() and aa.access_level='owner')
);
drop policy if exists "Owner can delete SASTIFY site assets" on storage.objects;
create policy "Owner can delete SASTIFY site assets" on storage.objects
for delete to authenticated using (
 bucket_id='site-assets' and exists(select 1 from public.admin_access aa where aa.user_id=auth.uid() and aa.access_level='owner')
);

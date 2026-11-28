-- SASTIFY Admin Security Foundation
-- Safe to run after supabase/admin_setup.sql and supabase/welcome_cms.sql.
-- Does not modify or replace the existing profiles table.

create or replace function public.is_sastify_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_access aa
    where aa.user_id = (select auth.uid())
      and aa.access_level = 'owner'
  );
$$;

revoke all on function public.is_sastify_owner() from public;
grant execute on function public.is_sastify_owner() to authenticated;

create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (length(trim(action)) between 1 and 120),
  target_table text,
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_logs_created_at_idx
  on public.admin_audit_logs (created_at desc);
create index if not exists admin_audit_logs_actor_idx
  on public.admin_audit_logs (actor_user_id, created_at desc);

alter table public.admin_audit_logs enable row level security;

revoke all on table public.admin_audit_logs from anon, authenticated;
grant select, insert on table public.admin_audit_logs to authenticated;

drop policy if exists "SASTIFY owner can read audit logs" on public.admin_audit_logs;
create policy "SASTIFY owner can read audit logs"
on public.admin_audit_logs
for select
to authenticated
using (public.is_sastify_owner());

drop policy if exists "SASTIFY owner can add audit logs" on public.admin_audit_logs;
create policy "SASTIFY owner can add audit logs"
on public.admin_audit_logs
for insert
to authenticated
with check (
  public.is_sastify_owner()
  and actor_user_id = (select auth.uid())
);

-- Keep audit history append-only for normal application roles.
drop policy if exists "SASTIFY owner cannot update audit logs" on public.admin_audit_logs;
drop policy if exists "SASTIFY owner cannot delete audit logs" on public.admin_audit_logs;

comment on table public.admin_audit_logs is
  'Append-only record of privileged SASTIFY admin actions.';

notify pgrst, 'reload schema';

-- Verification: should return true for the registered owner account.
select public.is_sastify_owner() as current_user_is_owner;

-- SASTIFY User Management Foundation
-- Run after admin_setup.sql and admin_security_foundation.sql.
-- Preserves the existing public.profiles table and all profile data.

create table if not exists public.user_account_controls (
  user_id uuid primary key references auth.users(id) on delete cascade,
  account_status text not null default 'active'
    check (account_status in ('active', 'suspended', 'banned')),
  reason text,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_account_controls_reason_length
    check (reason is null or length(reason) <= 1000)
);

create index if not exists user_account_controls_status_idx
  on public.user_account_controls (account_status, updated_at desc);

alter table public.user_account_controls enable row level security;
revoke all on table public.user_account_controls from anon, authenticated;
grant select on table public.user_account_controls to authenticated;

drop policy if exists "SASTIFY owner can read account controls"
  on public.user_account_controls;
create policy "SASTIFY owner can read account controls"
on public.user_account_controls
for select
to authenticated
using (public.is_sastify_owner());

create or replace function public.admin_set_user_status(
  target_user_id uuid,
  new_status text,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
  normalized_status text := lower(trim(new_status));
  clean_reason text := nullif(trim(change_reason), '');
begin
  if actor is null or not public.is_sastify_owner() then
    raise exception 'Owner access required' using errcode = '42501';
  end if;

  if target_user_id is null then
    raise exception 'A target user is required';
  end if;

  if normalized_status not in ('active', 'suspended', 'banned') then
    raise exception 'Invalid account status';
  end if;

  if clean_reason is not null and length(clean_reason) > 1000 then
    raise exception 'Reason must be 1000 characters or fewer';
  end if;

  if not exists (select 1 from auth.users u where u.id = target_user_id) then
    raise exception 'User not found';
  end if;

  if target_user_id = actor and normalized_status <> 'active' then
    raise exception 'You cannot suspend or ban your own Owner account';
  end if;

  insert into public.user_account_controls
    (user_id, account_status, reason, updated_by, updated_at)
  values
    (target_user_id, normalized_status, clean_reason, actor, now())
  on conflict (user_id) do update
    set account_status = excluded.account_status,
        reason = excluded.reason,
        updated_by = excluded.updated_by,
        updated_at = now();

  insert into public.admin_audit_logs
    (actor_user_id, action, target_table, target_id, details)
  values
    (actor, 'user_status_changed', 'user_account_controls',
     target_user_id::text,
     jsonb_build_object('status', normalized_status, 'reason', clean_reason));

  return jsonb_build_object(
    'success', true,
    'user_id', target_user_id,
    'account_status', normalized_status
  );
end;
$$;

revoke all on function public.admin_set_user_status(uuid, text, text) from public;
grant execute on function public.admin_set_user_status(uuid, text, text) to authenticated;

comment on table public.user_account_controls is
  'Owner-managed account status overrides. Existing profiles are preserved.';
comment on function public.admin_set_user_status(uuid, text, text) is
  'Owner-only RPC to activate, suspend or ban an account and append an audit log.';

notify pgrst, 'reload schema';

-- Verification: table exists; SQL Editor auth.uid() may be null, so this
-- query intentionally does not use the current-user Owner check.
select
  to_regclass('public.user_account_controls') as user_management_table,
  to_regprocedure('public.admin_set_user_status(uuid,text,text)') as status_rpc;

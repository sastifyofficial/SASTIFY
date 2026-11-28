create table if not exists public.admin_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  access_level text not null default 'owner' check (access_level = 'owner'),
  created_at timestamptz not null default now()
);
alter table public.admin_access enable row level security;
revoke all on table public.admin_access from anon;
revoke all on table public.admin_access from authenticated;
grant select on table public.admin_access to authenticated;
drop policy if exists "Owner can read own admin access" on public.admin_access;
create policy "Owner can read own admin access"
on public.admin_access for select to authenticated
using (user_id = (select auth.uid()));
insert into public.admin_access (user_id, access_level)
select id, 'owner' from auth.users
where lower(email) = lower('mdjihadofficial00@gmail.com')
on conflict (user_id) do update set access_level = excluded.access_level;
select aa.user_id, u.email, aa.access_level, aa.created_at
from public.admin_access aa join auth.users u on u.id = aa.user_id;
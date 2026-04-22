create table if not exists public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  role text not null default 'clinician' check (role in ('admin', 'clinician')),
  status text not null default 'pending' check (status in ('pending', 'active', 'blocked')),
  approved_at timestamptz,
  blocked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.anesthesia_cases (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  pre_anesthetic_date text default '',
  anesthesia_date text default '',
  status text not null,
  record jsonb not null
);

create or replace function public.is_admin_user()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and role = 'admin'
      and status = 'active'
  );
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_app_users_updated_at on public.app_users;
create trigger touch_app_users_updated_at
before update on public.app_users
for each row execute function public.touch_updated_at();

drop trigger if exists touch_anesthesia_cases_updated_at on public.anesthesia_cases;
create trigger touch_anesthesia_cases_updated_at
before update on public.anesthesia_cases
for each row execute function public.touch_updated_at();

alter table public.app_users enable row level security;
alter table public.anesthesia_cases enable row level security;

drop policy if exists "users can read own profile" on public.app_users;
create policy "users can read own profile"
on public.app_users
for select
to authenticated
using (id = auth.uid());

drop policy if exists "admins can read all profiles" on public.app_users;
create policy "admins can read all profiles"
on public.app_users
for select
to authenticated
using (public.is_admin_user());

drop policy if exists "users can insert own profile" on public.app_users;
create policy "users can insert own profile"
on public.app_users
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "admins can update profiles" on public.app_users;
create policy "admins can update profiles"
on public.app_users
for update
to authenticated
using (public.is_admin_user())
with check (public.is_admin_user());

drop policy if exists "active users can read cases" on public.anesthesia_cases;
create policy "active users can read cases"
on public.anesthesia_cases
for select
to authenticated
using (
  exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and status = 'active'
  )
);

drop policy if exists "active users can insert cases" on public.anesthesia_cases;
create policy "active users can insert cases"
on public.anesthesia_cases
for insert
to authenticated
with check (
  exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and status = 'active'
  )
);

drop policy if exists "active users can update cases" on public.anesthesia_cases;
create policy "active users can update cases"
on public.anesthesia_cases
for update
to authenticated
using (
  exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and status = 'active'
  )
)
with check (
  exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and status = 'active'
  )
);

drop policy if exists "active users can delete cases" on public.anesthesia_cases;
create policy "active users can delete cases"
on public.anesthesia_cases
for delete
to authenticated
using (
  exists (
    select 1
    from public.app_users
    where id = auth.uid()
      and status = 'active'
  )
);

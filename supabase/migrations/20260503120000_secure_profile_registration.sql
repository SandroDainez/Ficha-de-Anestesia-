create or replace function public.register_current_user_profile(
  full_name_input text default ''
)
returns public.app_users
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  current_user_email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  bootstrap_admin_email constant text := 'sandrodainez@hotmail.com';
  profile public.app_users;
begin
  if current_user_id is null then
    raise exception 'authenticated user required';
  end if;

  insert into public.app_users (
    id,
    email,
    full_name,
    role,
    status,
    approved_at,
    blocked_at
  )
  values (
    current_user_id,
    current_user_email,
    trim(coalesce(full_name_input, '')),
    case
      when current_user_email = bootstrap_admin_email then 'admin'
      else 'clinician'
    end,
    case
      when current_user_email = bootstrap_admin_email then 'active'
      else 'pending'
    end,
    case
      when current_user_email = bootstrap_admin_email then now()
      else null
    end,
    null
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = case
      when excluded.full_name <> '' then excluded.full_name
      else app_users.full_name
    end,
    updated_at = now()
  returning * into profile;

  return profile;
end;
$$;

revoke all on function public.register_current_user_profile(text) from public;
grant execute on function public.register_current_user_profile(text)
to authenticated;

update public.app_users
set
  role = 'admin',
  status = 'active',
  approved_at = coalesce(approved_at, now()),
  blocked_at = null,
  updated_at = now()
where lower(email) = 'sandrodainez@hotmail.com';

drop policy if exists "users can insert own profile" on public.app_users;
drop policy if exists "users can insert own pending clinician profile"
on public.app_users;

create policy "users can insert own pending clinician profile"
on public.app_users
for insert
to authenticated
with check (
  id = auth.uid()
  and lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  and role = 'clinician'
  and status = 'pending'
  and approved_at is null
  and blocked_at is null
);

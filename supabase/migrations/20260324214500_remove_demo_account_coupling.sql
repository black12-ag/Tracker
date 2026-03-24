update public.profiles
set is_active = true
where is_active = false;

update auth.users
set
  email = concat('archived-', replace(id::text, '-', ''), '@disabled.local'),
  raw_user_meta_data = jsonb_set(
    coalesce(raw_user_meta_data, '{}'::jsonb),
    '{display_name}',
    to_jsonb('Archived user'::text),
    true
  )
where email like '%@fesajtracker.com';

update public.profiles
set
  email = concat('archived-', replace(id::text, '-', ''), '@disabled.local'),
  role = 'operator',
  is_active = false,
  display_name = 'Archived user'
where email like '%@fesajtracker.com';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  assigned_role text;
begin
  assigned_role := case
    when exists (
      select 1
      from public.profiles
      where role = 'owner'
    ) then 'operator'
    else 'owner'
  end;

  insert into public.profiles (id, email, role, is_active, display_name)
  values (
    new.id,
    new.email,
    assigned_role,
    true,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update
  set
    email = excluded.email,
    role = public.profiles.role,
    is_active = true,
    display_name = excluded.display_name,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

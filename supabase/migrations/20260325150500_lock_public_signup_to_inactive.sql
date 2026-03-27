create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  assigned_role text;
  creator_id uuid;
  activate_user boolean;
begin
  assigned_role := case
    when exists (
      select 1
      from public.profiles
      where role = 'owner'
        and is_active = true
    ) then 'staff'
    else 'owner'
  end;

  creator_id := case
    when assigned_role = 'staff'
      and coalesce(new.raw_user_meta_data ->> 'created_by_owner', '') <> ''
    then (new.raw_user_meta_data ->> 'created_by_owner')::uuid
    else null
  end;

  activate_user := case
    when assigned_role = 'owner' then true
    when creator_id is not null then true
    else false
  end;

  insert into public.profiles (
    id,
    email,
    role,
    is_active,
    display_name,
    phone,
    created_by_owner
  )
  values (
    new.id,
    new.email,
    assigned_role,
    activate_user,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    nullif(coalesce(new.raw_user_meta_data ->> 'phone', new.phone), ''),
    creator_id
  )
  on conflict (id) do update
  set
    email = excluded.email,
    role = public.profiles.role,
    is_active = case
      when public.profiles.role = 'owner' then true
      else public.profiles.is_active
    end,
    display_name = excluded.display_name,
    phone = coalesce(excluded.phone, public.profiles.phone),
    created_by_owner = coalesce(public.profiles.created_by_owner, excluded.created_by_owner),
    updated_at = timezone('utc', now());

  return new;
end;
$$;

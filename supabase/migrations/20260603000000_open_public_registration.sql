-- ============================================================
-- Open public registration (multi-tenant SaaS model)
-- ------------------------------------------------------------
-- Previous behaviour (20260325150500_lock_public_signup_to_inactive):
--   * First ever sign-up  -> owner, active
--   * Everyone after that -> staff, INACTIVE (locked out)
--
-- New behaviour:
--   * Any self sign-up                       -> OWNER, active
--       (the on_new_owner_create_workspace trigger then gives
--        each owner their own isolated workspace automatically)
--   * Sign-up carrying `created_by_owner`    -> STAFF, active
--       (only the create-staff edge function sets this metadata,
--        so staff can still only be minted by an existing owner)
--
-- Result: anyone can register and immediately run their own
-- business; nobody is left in a locked "inactive" limbo.
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  creator_id uuid;
  assigned_role text;
begin
  -- Staff are minted exclusively by the create-staff edge function, which
  -- stamps the owner's id into APP metadata (raw_app_meta_data). App metadata
  -- is writable only by the service role, so a public self-signup cannot
  -- forge it. We deliberately do NOT trust raw_user_meta_data here, which is
  -- client-settable via auth.signUp(data: {...}).
  creator_id := case
    when coalesce(new.raw_app_meta_data ->> 'created_by_owner', '') <> ''
    then (new.raw_app_meta_data ->> 'created_by_owner')::uuid
    else null
  end;

  -- Defence in depth: only honour the staff assignment if the asserted
  -- creator is actually an active owner. Otherwise fall back to owner so the
  -- account is never left in a broken, workspace-less staff state.
  if creator_id is not null and not exists (
    select 1 from public.profiles
    where id = creator_id and role = 'owner' and is_active = true
  ) then
    creator_id := null;
  end if;

  assigned_role := case
    when creator_id is not null then 'staff'
    else 'owner'
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
    true, -- every account is active on creation
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    nullif(coalesce(new.raw_user_meta_data ->> 'phone', new.phone), ''),
    creator_id
  )
  on conflict (id) do update
  set
    email = excluded.email,
    role = public.profiles.role,
    is_active = true,
    display_name = excluded.display_name,
    phone = coalesce(excluded.phone, public.profiles.phone),
    created_by_owner = coalesce(public.profiles.created_by_owner, excluded.created_by_owner),
    updated_at = timezone('utc', now());

  return new;
end;
$$;

-- ============================================================
-- SECURITY: lock privileged columns on public.profiles
-- ------------------------------------------------------------
-- The profiles UPDATE policy allows `id = auth.uid()` (you may edit your
-- own row). Without column protection, ANY authenticated user could update
-- their own profile to set workspace_id = <another business> and
-- role = 'owner', granting themselves full cross-tenant access. With open
-- public registration this is exploitable by anyone, so we harden it here.
--
-- Rule (for non-service callers):
--   * workspace_id can NEVER be changed from the client. It is set once,
--     by the signup trigger / create-staff edge function, which mark the
--     write as privileged via a transaction-local flag.
--   * You cannot change your OWN role, is_active, or created_by_owner.
--   * An owner managing staff in their workspace may toggle is_active /
--     display_name / phone, but may not grant 'owner' to anyone.
-- Service-role calls (edge functions) bypass the guard entirely.
-- ============================================================
create or replace function public.guard_profile_privileged_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Edge functions (service role) and the signup workspace-assignment path
  -- (flagged transaction-locally) are trusted to set privileged columns.
  if auth.role() = 'service_role'
     or coalesce(current_setting('app.privileged_profile_write', true), '') = '1' then
    return new;
  end if;

  -- A profile can never be moved across workspaces from the client.
  new.workspace_id := old.workspace_id;

  if new.id = auth.uid() then
    -- You cannot self-escalate role, reactivate yourself, or reassign creator.
    new.role := old.role;
    new.is_active := old.is_active;
    new.created_by_owner := old.created_by_owner;
  else
    -- Owners managing staff may NOT promote anyone to owner.
    if new.role = 'owner' and old.role <> 'owner' then
      new.role := old.role;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists guard_profiles_privileged_columns on public.profiles;
create trigger guard_profiles_privileged_columns
  before update on public.profiles
  for each row
  execute function public.guard_profile_privileged_columns();

-- Re-issue the owner-signup trigger so its workspace_id assignment is
-- marked as a privileged write (otherwise the guard above would revert it
-- back to NULL on a brand-new owner).
create or replace function public.handle_new_owner_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_workspace_id uuid;
  business_name text;
begin
  if new.role <> 'owner' then
    return new;
  end if;

  business_name := coalesce(
    (select raw_user_meta_data->>'business_name' from auth.users where id = new.id),
    split_part(new.email, '@', 1)
  );

  insert into public.workspaces (name, owner_id)
  values (business_name, new.id)
  returning id into new_workspace_id;

  perform set_config('app.privileged_profile_write', '1', true);
  update public.profiles
  set workspace_id = new_workspace_id
  where id = new.id;
  perform set_config('app.privileged_profile_write', '', true);

  return new;
end;
$$;

alter table public.profiles
add column if not exists is_active boolean;

update public.profiles
set is_active = true
where is_active is distinct from true;

alter table public.profiles
alter column is_active set default true;

alter table public.profiles
alter column is_active set not null;

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_active = true
      and role = 'owner'
  );
$$;

create or replace function public.has_app_access()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_active = true
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role, is_active, display_name)
  values (
    new.id,
    new.email,
    'operator',
    true,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update
  set
    email = excluded.email,
    display_name = excluded.display_name,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop policy if exists "profiles_update_self" on public.profiles;

drop policy if exists "customers_shared_access" on public.customers;
create policy "customers_shared_access" on public.customers
for select
to authenticated
using (public.has_app_access());

drop policy if exists "customers_shared_insert" on public.customers;
create policy "customers_shared_insert" on public.customers
for insert
to authenticated
with check (public.has_app_access());

drop policy if exists "customers_shared_update" on public.customers;
create policy "customers_shared_update" on public.customers
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "production_entries_shared_select" on public.production_entries;
create policy "production_entries_shared_select" on public.production_entries
for select
to authenticated
using (public.has_app_access());

drop policy if exists "production_entries_shared_insert" on public.production_entries;
create policy "production_entries_shared_insert" on public.production_entries
for insert
to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "production_entries_shared_update" on public.production_entries;
create policy "production_entries_shared_update" on public.production_entries
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access() and (created_by = auth.uid() or public.is_owner()));

drop policy if exists "sales_dispatches_shared_select" on public.sales_dispatches;
create policy "sales_dispatches_shared_select" on public.sales_dispatches
for select
to authenticated
using (public.has_app_access());

drop policy if exists "sales_dispatches_shared_insert" on public.sales_dispatches;
create policy "sales_dispatches_shared_insert" on public.sales_dispatches
for insert
to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "sales_dispatches_shared_update" on public.sales_dispatches;
create policy "sales_dispatches_shared_update" on public.sales_dispatches
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access() and (created_by = auth.uid() or public.is_owner()));

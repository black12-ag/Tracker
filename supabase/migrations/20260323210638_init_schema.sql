create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  role text not null default 'operator' check (role in ('owner', 'operator')),
  is_active boolean not null default false,
  display_name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.product_settings (
  id integer primary key default 1 check (id = 1),
  product_name text not null,
  default_cost_per_liter numeric(12, 2) not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.product_sizes (
  id uuid primary key default gen_random_uuid(),
  label text not null unique,
  liters numeric(4, 1) not null unique,
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.size_prices (
  id uuid primary key default gen_random_uuid(),
  size_id uuid not null unique references public.product_sizes (id) on delete cascade,
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.production_entries (
  id uuid primary key default gen_random_uuid(),
  produced_on date not null default current_date,
  size_id uuid not null references public.product_sizes (id),
  quantity_units integer not null check (quantity_units > 0),
  notes text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales_dispatches (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers (id),
  size_id uuid not null references public.product_sizes (id),
  quantity_units integer not null check (quantity_units > 0),
  sold_at timestamptz not null default timezone('utc', now()),
  dispatch_status text not null default 'recorded' check (dispatch_status in ('recorded', 'completed')),
  notes text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sale_finance (
  id uuid primary key default gen_random_uuid(),
  dispatch_id uuid not null unique references public.sales_dispatches (id) on delete cascade,
  unit_price_snapshot numeric(12, 2) not null check (unit_price_snapshot >= 0),
  unit_cost_snapshot numeric(12, 2) not null check (unit_cost_snapshot >= 0),
  total_amount numeric(12, 2) not null check (total_amount >= 0),
  paid_amount numeric(12, 2) not null default 0 check (paid_amount >= 0),
  balance_amount numeric(12, 2) not null default 0 check (balance_amount >= 0),
  loan_label text,
  finance_status text not null default 'unpaid' check (finance_status in ('unpaid', 'partial', 'paid')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.payment_records (
  id uuid primary key default gen_random_uuid(),
  sale_finance_id uuid not null references public.sale_finance (id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  payment_date date not null default current_date,
  note text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists production_entries_size_id_idx on public.production_entries (size_id);
create index if not exists production_entries_produced_on_idx on public.production_entries (produced_on desc);
create index if not exists sales_dispatches_customer_id_idx on public.sales_dispatches (customer_id);
create index if not exists sales_dispatches_size_id_idx on public.sales_dispatches (size_id);
create index if not exists sales_dispatches_sold_at_idx on public.sales_dispatches (sold_at desc);
create index if not exists payment_records_sale_finance_id_idx on public.payment_records (sale_finance_id);

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger set_product_settings_updated_at
before update on public.product_settings
for each row
execute function public.set_updated_at();

create trigger set_product_sizes_updated_at
before update on public.product_sizes
for each row
execute function public.set_updated_at();

create trigger set_size_prices_updated_at
before update on public.size_prices
for each row
execute function public.set_updated_at();

create trigger set_customers_updated_at
before update on public.customers
for each row
execute function public.set_updated_at();

create trigger set_production_entries_updated_at
before update on public.production_entries
for each row
execute function public.set_updated_at();

create trigger set_sales_dispatches_updated_at
before update on public.sales_dispatches
for each row
execute function public.set_updated_at();

create trigger set_sale_finance_updated_at
before update on public.sale_finance
for each row
execute function public.set_updated_at();

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'operator'
  );
$$;

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
  insert into public.profiles (id, email, role, display_name)
  values (
    new.id,
    new.email,
    'operator',
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

create or replace function public.normalize_sale_finance()
returns trigger
language plpgsql
as $$
begin
  new.balance_amount := greatest(new.total_amount - new.paid_amount, 0);

  if new.paid_amount <= 0 then
    new.finance_status := 'unpaid';
  elsif new.balance_amount = 0 then
    new.finance_status := 'paid';
  else
    new.finance_status := 'partial';
  end if;

  return new;
end;
$$;

create trigger normalize_sale_finance_before_write
before insert or update on public.sale_finance
for each row
execute function public.normalize_sale_finance();

create or replace function public.sync_sale_finance_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_finance_id uuid;
  total_paid numeric(12, 2);
begin
  target_finance_id := coalesce(new.sale_finance_id, old.sale_finance_id);

  select coalesce(sum(amount), 0)
  into total_paid
  from public.payment_records
  where sale_finance_id = target_finance_id;

  update public.sale_finance
  set paid_amount = total_paid
  where id = target_finance_id;

  return coalesce(new, old);
end;
$$;

create trigger sync_sale_finance_totals_after_payment_change
after insert or update or delete on public.payment_records
for each row
execute function public.sync_sale_finance_totals();

create or replace function public.get_product_public_settings()
returns table (
  id integer,
  product_name text
)
language sql
security definer
set search_path = public
as $$
  select ps.id, ps.product_name
  from public.product_settings ps;
$$;

create or replace view public.size_inventory_summary
with (security_invoker = true)
as
with produced as (
  select size_id, coalesce(sum(quantity_units), 0) as produced_units
  from public.production_entries
  group by size_id
),
sold as (
  select size_id, coalesce(sum(quantity_units), 0) as sold_units
  from public.sales_dispatches
  group by size_id
)
select
  s.id as size_id,
  s.label,
  s.liters,
  s.low_stock_threshold,
  coalesce(p.produced_units, 0) as produced_units,
  coalesce(sa.sold_units, 0) as sold_units,
  greatest(coalesce(p.produced_units, 0) - coalesce(sa.sold_units, 0), 0) as current_stock_units,
  greatest(coalesce(p.produced_units, 0) - coalesce(sa.sold_units, 0), 0) <= s.low_stock_threshold as is_low_stock
from public.product_sizes s
left join produced p on p.size_id = s.id
left join sold sa on sa.size_id = s.id
order by s.liters asc;

create or replace function public.owner_finance_summary()
returns table (
  total_sales numeric,
  total_paid numeric,
  total_balance numeric,
  estimated_profit numeric,
  open_loans bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_owner() then
    raise exception 'owner access required'
      using errcode = '42501';
  end if;

  return query
  select
    coalesce(sum(sf.total_amount), 0)::numeric as total_sales,
    coalesce(sum(sf.paid_amount), 0)::numeric as total_paid,
    coalesce(sum(sf.balance_amount), 0)::numeric as total_balance,
    coalesce(sum((sf.unit_price_snapshot - sf.unit_cost_snapshot) * sd.quantity_units), 0)::numeric as estimated_profit,
    count(*) filter (where sf.balance_amount > 0)::bigint as open_loans
  from public.sale_finance sf
  join public.sales_dispatches sd on sd.id = sf.dispatch_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.product_settings enable row level security;
alter table public.product_sizes enable row level security;
alter table public.size_prices enable row level security;
alter table public.customers enable row level security;
alter table public.production_entries enable row level security;
alter table public.sales_dispatches enable row level security;
alter table public.sale_finance enable row level security;
alter table public.payment_records enable row level security;

create policy "profiles_select_self" on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "product_settings_owner_only" on public.product_settings
for all
to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "product_sizes_select_all" on public.product_sizes
for select
to authenticated
using (true);

create policy "product_sizes_owner_manage" on public.product_sizes
for all
to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "size_prices_owner_only" on public.size_prices
for all
to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "customers_shared_access" on public.customers
for select
to authenticated
using (public.has_app_access());

create policy "customers_shared_insert" on public.customers
for insert
to authenticated
with check (public.has_app_access());

create policy "customers_shared_update" on public.customers
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access());

create policy "production_entries_shared_select" on public.production_entries
for select
to authenticated
using (public.has_app_access());

create policy "production_entries_shared_insert" on public.production_entries
for insert
to authenticated
with check (public.has_app_access() and created_by = auth.uid());

create policy "production_entries_shared_update" on public.production_entries
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access() and (created_by = auth.uid() or public.is_owner()));

create policy "sales_dispatches_shared_select" on public.sales_dispatches
for select
to authenticated
using (public.has_app_access());

create policy "sales_dispatches_shared_insert" on public.sales_dispatches
for insert
to authenticated
with check (public.has_app_access() and created_by = auth.uid());

create policy "sales_dispatches_shared_update" on public.sales_dispatches
for update
to authenticated
using (public.has_app_access())
with check (public.has_app_access() and (created_by = auth.uid() or public.is_owner()));

create policy "sale_finance_owner_only" on public.sale_finance
for all
to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "payment_records_owner_only" on public.payment_records
for all
to authenticated
using (public.is_owner())
with check (public.is_owner());

insert into public.product_settings (id, product_name, default_cost_per_liter)
values (1, 'Liquid Soap', 0)
on conflict (id) do nothing;

insert into public.product_sizes (label, liters, low_stock_threshold, active)
values
  ('1L', 1.0, 12, true),
  ('2.5L', 2.5, 8, true),
  ('5L', 5.0, 6, true),
  ('10L', 10.0, 4, true)
on conflict (liters) do nothing;

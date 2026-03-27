alter table public.profiles
  add column if not exists phone text,
  add column if not exists created_by_owner uuid references public.profiles (id),
  add column if not exists last_password_change_at timestamptz;

update public.profiles
set role = 'staff'
where role = 'operator';

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  alter column role set default 'staff';

alter table public.profiles
  add constraint profiles_role_check check (role in ('owner', 'staff'));

create unique index if not exists profiles_phone_unique_idx
on public.profiles (phone)
where phone is not null;

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'staff'
  );
$$;

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
        and is_active = true
    ) then 'staff'
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
    true,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    nullif(coalesce(new.raw_user_meta_data ->> 'phone', new.phone), ''),
    case
      when assigned_role = 'staff'
        and coalesce(new.raw_user_meta_data ->> 'created_by_owner', '') <> ''
      then (new.raw_user_meta_data ->> 'created_by_owner')::uuid
      else null
    end
  )
  on conflict (id) do update
  set
    email = excluded.email,
    role = public.profiles.role,
    is_active = true,
    display_name = excluded.display_name,
    phone = coalesce(excluded.phone, public.profiles.phone),
    updated_at = timezone('utc', now());

  return new;
end;
$$;

create table if not exists public.document_counters (
  counter_key text primary key,
  current_value bigint not null default 0
);

create or replace function public.next_document_code(
  p_counter_key text,
  p_prefix text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  next_value bigint;
begin
  insert into public.document_counters (counter_key, current_value)
  values (p_counter_key, 0)
  on conflict (counter_key) do nothing;

  update public.document_counters
  set current_value = current_value + 1
  where counter_key = p_counter_key
  returning current_value into next_value;

  return format('%s-%s', p_prefix, lpad(next_value::text, 5, '0'));
end;
$$;

create table if not exists public.partners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  partner_type text not null default 'customer'
    check (partner_type in ('customer', 'supplier', 'mixed', 'walk_in')),
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null,
  unit_type text not null,
  bought_price numeric(12, 2) not null default 0 check (bought_price >= 0),
  selling_price numeric(12, 2) not null default 0 check (selling_price >= 0),
  description text,
  active boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.inventory_item_images (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.inventory_items (id) on delete cascade,
  storage_path text not null,
  public_url text,
  sort_order integer not null default 0,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.inventory_items (id) on delete cascade,
  movement_type text not null
    check (
      movement_type in (
        'purchase',
        'receive',
        'sale',
        'shipment',
        'adjustment_plus',
        'adjustment_minus',
        'opening_balance'
      )
    ),
  quantity numeric(14, 2) not null check (quantity > 0),
  movement_date date not null default current_date,
  note text,
  source_table text,
  source_id uuid,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  account_code text not null unique,
  account_name text not null,
  account_number text,
  bank_name text,
  account_type text not null check (account_type in ('cash', 'bank')),
  opening_balance numeric(14, 2) not null default 0,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.account_transfers (
  id uuid primary key default gen_random_uuid(),
  from_account_id uuid not null references public.accounts (id),
  to_account_id uuid not null references public.accounts (id),
  amount numeric(14, 2) not null check (amount > 0),
  transfer_date date not null default current_date,
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  constraint account_transfers_different_accounts check (from_account_id <> to_account_id)
);

create table if not exists public.sales_orders (
  id uuid primary key default gen_random_uuid(),
  order_code text not null unique,
  partner_id uuid references public.partners (id),
  order_date date not null default current_date,
  shipment_date date,
  status text not null default 'draft'
    check (status in ('draft', 'ready', 'shipped', 'completed', 'cancelled')),
  note text,
  total_amount numeric(14, 2) not null default 0,
  paid_amount numeric(14, 2) not null default 0,
  balance_amount numeric(14, 2) not null default 0,
  account_id uuid references public.accounts (id),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales_order_items (
  id uuid primary key default gen_random_uuid(),
  sales_order_id uuid not null references public.sales_orders (id) on delete cascade,
  item_id uuid not null references public.inventory_items (id),
  quantity numeric(14, 2) not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  unit_cost_snapshot numeric(12, 2) not null default 0 check (unit_cost_snapshot >= 0),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  order_code text not null unique,
  partner_id uuid references public.partners (id),
  order_date date not null default current_date,
  receive_date date,
  status text not null default 'draft'
    check (status in ('draft', 'ready', 'received', 'completed', 'cancelled')),
  note text,
  total_amount numeric(14, 2) not null default 0,
  paid_amount numeric(14, 2) not null default 0,
  balance_amount numeric(14, 2) not null default 0,
  account_id uuid references public.accounts (id),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders (id) on delete cascade,
  item_id uuid not null references public.inventory_items (id),
  quantity numeric(14, 2) not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.loan_records (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.partners (id),
  direction text not null check (direction in ('they_gave_us', 'we_gave_them')),
  record_date date not null default current_date,
  amount numeric(14, 2) not null check (amount > 0),
  settled_amount numeric(14, 2) not null default 0 check (settled_amount >= 0),
  balance_amount numeric(14, 2) not null default 0 check (balance_amount >= 0),
  account_id uuid references public.accounts (id),
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.expense_entries
  add column if not exists account_id uuid references public.accounts (id);

create index if not exists partners_name_idx on public.partners (name);
create index if not exists partners_phone_idx on public.partners (phone);
create index if not exists inventory_items_name_idx on public.inventory_items (name);
create index if not exists stock_movements_item_idx on public.stock_movements (item_id, movement_date desc);
create index if not exists sales_orders_order_date_idx on public.sales_orders (order_date desc);
create index if not exists purchase_orders_order_date_idx on public.purchase_orders (order_date desc);
create index if not exists loan_records_record_date_idx on public.loan_records (record_date desc);

create trigger set_partners_updated_at
before update on public.partners
for each row
execute function public.set_updated_at();

create trigger set_inventory_items_updated_at
before update on public.inventory_items
for each row
execute function public.set_updated_at();

create trigger set_accounts_updated_at
before update on public.accounts
for each row
execute function public.set_updated_at();

create trigger set_sales_orders_updated_at
before update on public.sales_orders
for each row
execute function public.set_updated_at();

create trigger set_purchase_orders_updated_at
before update on public.purchase_orders
for each row
execute function public.set_updated_at();

create trigger set_loan_records_updated_at
before update on public.loan_records
for each row
execute function public.set_updated_at();

create or replace function public.assign_inventory_item_sku()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.sku is null or btrim(new.sku) = '' then
    new.sku := public.next_document_code('inventory_items', 'SKU');
  end if;
  return new;
end;
$$;

drop trigger if exists assign_inventory_item_sku_before_insert on public.inventory_items;
create trigger assign_inventory_item_sku_before_insert
before insert on public.inventory_items
for each row
execute function public.assign_inventory_item_sku();

create or replace function public.assign_account_code()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.account_code is null or btrim(new.account_code) = '' then
    new.account_code := public.next_document_code('accounts', 'ACC');
  end if;
  return new;
end;
$$;

drop trigger if exists assign_account_code_before_insert on public.accounts;
create trigger assign_account_code_before_insert
before insert on public.accounts
for each row
execute function public.assign_account_code();

create or replace function public.assign_sales_order_code()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.order_code is null or btrim(new.order_code) = '' then
    new.order_code := public.next_document_code('sales_orders', 'SO');
  end if;
  return new;
end;
$$;

drop trigger if exists assign_sales_order_code_before_insert on public.sales_orders;
create trigger assign_sales_order_code_before_insert
before insert on public.sales_orders
for each row
execute function public.assign_sales_order_code();

create or replace function public.assign_purchase_order_code()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.order_code is null or btrim(new.order_code) = '' then
    new.order_code := public.next_document_code('purchase_orders', 'PO');
  end if;
  return new;
end;
$$;

drop trigger if exists assign_purchase_order_code_before_insert on public.purchase_orders;
create trigger assign_purchase_order_code_before_insert
before insert on public.purchase_orders
for each row
execute function public.assign_purchase_order_code();

create or replace function public.normalize_sales_order()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.paid_amount := greatest(new.paid_amount, 0);
  new.total_amount := greatest(new.total_amount, 0);
  new.balance_amount := greatest(new.total_amount - new.paid_amount, 0);
  return new;
end;
$$;

drop trigger if exists normalize_sales_order_before_write on public.sales_orders;
create trigger normalize_sales_order_before_write
before insert or update on public.sales_orders
for each row
execute function public.normalize_sales_order();

create or replace function public.normalize_purchase_order()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.paid_amount := greatest(new.paid_amount, 0);
  new.total_amount := greatest(new.total_amount, 0);
  new.balance_amount := greatest(new.total_amount - new.paid_amount, 0);
  return new;
end;
$$;

drop trigger if exists normalize_purchase_order_before_write on public.purchase_orders;
create trigger normalize_purchase_order_before_write
before insert or update on public.purchase_orders
for each row
execute function public.normalize_purchase_order();

create or replace function public.normalize_loan_record()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.settled_amount := greatest(new.settled_amount, 0);
  new.balance_amount := greatest(new.amount - new.settled_amount, 0);
  return new;
end;
$$;

drop trigger if exists normalize_loan_record_before_write on public.loan_records;
create trigger normalize_loan_record_before_write
before insert or update on public.loan_records
for each row
execute function public.normalize_loan_record();

create or replace function public.set_sales_item_cost_snapshot()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.unit_cost_snapshot = 0 then
    select coalesce(bought_price, 0)
    into new.unit_cost_snapshot
    from public.inventory_items
    where id = new.item_id;
  end if;

  return new;
end;
$$;

drop trigger if exists set_sales_item_cost_snapshot_before_write on public.sales_order_items;
create trigger set_sales_item_cost_snapshot_before_write
before insert or update on public.sales_order_items
for each row
execute function public.set_sales_item_cost_snapshot();

create or replace function public.sync_sales_order_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id uuid;
  target_total numeric(14, 2);
begin
  target_order_id := coalesce(new.sales_order_id, old.sales_order_id);

  select coalesce(sum(quantity * unit_price), 0)
  into target_total
  from public.sales_order_items
  where sales_order_id = target_order_id;

  update public.sales_orders
  set
    total_amount = target_total,
    balance_amount = greatest(target_total - paid_amount, 0),
    updated_at = timezone('utc', now())
  where id = target_order_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_sales_order_totals_after_write on public.sales_order_items;
create trigger sync_sales_order_totals_after_write
after insert or update or delete on public.sales_order_items
for each row
execute function public.sync_sales_order_totals();

create or replace function public.sync_purchase_order_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id uuid;
  target_total numeric(14, 2);
begin
  target_order_id := coalesce(new.purchase_order_id, old.purchase_order_id);

  select coalesce(sum(quantity * unit_price), 0)
  into target_total
  from public.purchase_order_items
  where purchase_order_id = target_order_id;

  update public.purchase_orders
  set
    total_amount = target_total,
    balance_amount = greatest(target_total - paid_amount, 0),
    updated_at = timezone('utc', now())
  where id = target_order_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_purchase_order_totals_after_write on public.purchase_order_items;
create trigger sync_purchase_order_totals_after_write
after insert or update or delete on public.purchase_order_items
for each row
execute function public.sync_purchase_order_totals();

create or replace view public.inventory_stock_summary as
select
  i.id as item_id,
  i.name as item_name,
  i.sku,
  coalesce(sum(
    case
      when sm.movement_type in ('purchase', 'receive', 'adjustment_plus', 'opening_balance') then sm.quantity
      else -sm.quantity
    end
  ), 0)::numeric(14, 2) as current_stock
from public.inventory_items i
left join public.stock_movements sm on sm.item_id = i.id
group by i.id, i.name, i.sku;

create or replace function public.record_purchase_receipt(
  p_purchase_order_id uuid,
  p_receive_date date default current_date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.purchase_orders%rowtype;
begin
  if not public.has_app_access() then
    raise exception 'app access required'
      using errcode = '42501';
  end if;

  select *
  into order_row
  from public.purchase_orders
  where id = p_purchase_order_id;

  if not found then
    raise exception 'purchase order not found'
      using errcode = 'P0002';
  end if;

  if exists (
    select 1
    from public.stock_movements
    where source_table = 'purchase_orders'
      and source_id = p_purchase_order_id
      and movement_type = 'receive'
  ) then
    raise exception 'purchase order already received'
      using errcode = '23505';
  end if;

  insert into public.stock_movements (
    item_id,
    movement_type,
    quantity,
    movement_date,
    note,
    source_table,
    source_id,
    created_by
  )
  select
    poi.item_id,
    'receive',
    poi.quantity,
    coalesce(p_receive_date, current_date),
    order_row.note,
    'purchase_orders',
    order_row.id,
    auth.uid()
  from public.purchase_order_items poi
  where poi.purchase_order_id = order_row.id;

  update public.purchase_orders
  set
    status = case
      when balance_amount = 0 then 'completed'
      else 'received'
    end,
    receive_date = coalesce(p_receive_date, current_date),
    updated_at = timezone('utc', now())
  where id = order_row.id;
end;
$$;

create or replace function public.record_sales_shipment(
  p_sales_order_id uuid,
  p_shipment_date date default current_date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  order_row public.sales_orders%rowtype;
begin
  if not public.has_app_access() then
    raise exception 'app access required'
      using errcode = '42501';
  end if;

  select *
  into order_row
  from public.sales_orders
  where id = p_sales_order_id;

  if not found then
    raise exception 'sales order not found'
      using errcode = 'P0002';
  end if;

  if exists (
    select 1
    from public.stock_movements
    where source_table = 'sales_orders'
      and source_id = p_sales_order_id
      and movement_type = 'shipment'
  ) then
    raise exception 'sales order already shipped'
      using errcode = '23505';
  end if;

  insert into public.stock_movements (
    item_id,
    movement_type,
    quantity,
    movement_date,
    note,
    source_table,
    source_id,
    created_by
  )
  select
    soi.item_id,
    'shipment',
    soi.quantity,
    coalesce(p_shipment_date, current_date),
    order_row.note,
    'sales_orders',
    order_row.id,
    auth.uid()
  from public.sales_order_items soi
  where soi.sales_order_id = order_row.id;

  update public.sales_orders
  set
    status = case
      when balance_amount = 0 then 'completed'
      else 'shipped'
    end,
    shipment_date = coalesce(p_shipment_date, current_date),
    updated_at = timezone('utc', now())
  where id = order_row.id;
end;
$$;

create or replace function public.account_balance_summary()
returns table (
  account_id uuid,
  account_code text,
  account_name text,
  account_number text,
  bank_name text,
  account_type text,
  current_balance numeric
)
language sql
security definer
set search_path = public
as $$
  select
    a.id,
    a.account_code,
    a.account_name,
    a.account_number,
    a.bank_name,
    a.account_type,
    (
      a.opening_balance
      + coalesce((
        select sum(t.amount)
        from public.account_transfers t
        where t.to_account_id = a.id
      ), 0)
      - coalesce((
        select sum(t.amount)
        from public.account_transfers t
        where t.from_account_id = a.id
      ), 0)
      + coalesce((
        select sum(so.paid_amount)
        from public.sales_orders so
        where so.account_id = a.id
      ), 0)
      - coalesce((
        select sum(po.paid_amount)
        from public.purchase_orders po
        where po.account_id = a.id
      ), 0)
      + coalesce((
        select sum(lr.amount)
        from public.loan_records lr
        where lr.account_id = a.id
          and lr.direction = 'they_gave_us'
      ), 0)
      - coalesce((
        select sum(lr.amount)
        from public.loan_records lr
        where lr.account_id = a.id
          and lr.direction = 'we_gave_them'
      ), 0)
      - coalesce((
        select sum(ee.amount)
        from public.expense_entries ee
        where ee.account_id = a.id
      ), 0)
    )::numeric(14, 2) as current_balance
  from public.accounts a
  where public.is_owner();
$$;

create or replace function public.home_overview_summary(
  p_period text default 'monthly'
)
returns table (
  inventory_items_count bigint,
  total_stock_units numeric,
  total_sales_orders bigint,
  total_purchase_orders bigint,
  total_assets numeric,
  total_in_banks numeric,
  loan_records_collectible numeric,
  loan_records_payable numeric,
  net_worth numeric,
  profit_margin numeric,
  revenue numeric,
  collected_money numeric,
  estimated_profit numeric,
  net_profit numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  range_start date;
begin
  range_start := case
    when lower(coalesce(p_period, 'monthly')) = 'weekly' then current_date - interval '7 days'
    when lower(coalesce(p_period, 'monthly')) = 'monthly' then date_trunc('month', current_date)::date
    else current_date - interval '100 years'
  end;

  if public.is_owner() then
    return query
    with stock as (
      select
        count(*)::bigint as inventory_items_count,
        coalesce(sum(current_stock), 0)::numeric as total_stock_units,
        coalesce(sum(current_stock * i.bought_price), 0)::numeric as inventory_value
      from public.inventory_stock_summary s
      join public.inventory_items i on i.id = s.item_id
      where i.active = true
    ),
    sales as (
      select
        count(*)::bigint as total_sales_orders,
        coalesce(sum(total_amount), 0)::numeric as revenue,
        coalesce(sum(paid_amount), 0)::numeric as collected_money
      from public.sales_orders
      where order_date >= range_start
    ),
    purchases as (
      select count(*)::bigint as total_purchase_orders
      from public.purchase_orders
      where order_date >= range_start
    ),
    loans as (
      select
        coalesce(sum(case when direction = 'we_gave_them' then balance_amount else 0 end), 0)::numeric as collectible,
        coalesce(sum(case when direction = 'they_gave_us' then balance_amount else 0 end), 0)::numeric as payable
      from public.loan_records
    ),
    balances as (
      select
        coalesce(sum(current_balance), 0)::numeric as total_assets,
        coalesce(sum(current_balance) filter (where account_type = 'bank'), 0)::numeric as total_in_banks
      from public.account_balance_summary()
    ),
    profits as (
      select
        coalesce(sum((soi.unit_price - soi.unit_cost_snapshot) * soi.quantity), 0)::numeric as estimated_profit
      from public.sales_order_items soi
      join public.sales_orders so on so.id = soi.sales_order_id
      where so.order_date >= range_start
    ),
    expenses as (
      select
        coalesce(sum(amount), 0)::numeric as total_expenses
      from public.expense_entries
      where expense_date >= range_start
    )
    select
      stock.inventory_items_count,
      stock.total_stock_units,
      sales.total_sales_orders,
      purchases.total_purchase_orders,
      (balances.total_assets + stock.inventory_value + loans.collectible)::numeric as total_assets,
      balances.total_in_banks,
      loans.collectible,
      loans.payable,
      ((balances.total_assets + stock.inventory_value + loans.collectible) - loans.payable)::numeric as net_worth,
      case
        when sales.revenue > 0 then ((profits.estimated_profit - expenses.total_expenses) / sales.revenue) * 100
        else 0
      end::numeric as profit_margin,
      sales.revenue,
      sales.collected_money,
      profits.estimated_profit,
      (profits.estimated_profit - expenses.total_expenses)::numeric as net_profit
    from stock, sales, purchases, loans, balances, profits, expenses;
  end if;

  return query
  with stock as (
    select
      count(*)::bigint as inventory_items_count,
      coalesce(sum(current_stock), 0)::numeric as total_stock_units
    from public.inventory_stock_summary
  ),
  sales as (
    select count(*)::bigint as total_sales_orders
    from public.sales_orders
    where order_date >= range_start
  ),
  purchases as (
    select count(*)::bigint as total_purchase_orders
    from public.purchase_orders
    where order_date >= range_start
  )
  select
    stock.inventory_items_count,
    stock.total_stock_units,
    sales.total_sales_orders,
    purchases.total_purchase_orders,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric,
    null::numeric
  from stock, sales, purchases;
end;
$$;

create or replace function public.sales_report_summary(
  p_period text default 'monthly'
)
returns table (
  total_orders bigint,
  delivery_rate numeric,
  total_amount numeric,
  total_items numeric,
  highest_single_order_amount numeric,
  highest_single_order_items numeric,
  top_customer_name text,
  top_customer_revenue numeric,
  top_customer_items numeric
)
language sql
security definer
set search_path = public
as $$
  with filtered_orders as (
    select *
    from public.sales_orders
    where order_date >= case
      when lower(coalesce(p_period, 'monthly')) = 'weekly' then current_date - interval '7 days'
      when lower(coalesce(p_period, 'monthly')) = 'monthly' then date_trunc('month', current_date)::date
      else current_date - interval '100 years'
    end
  ),
  order_items as (
    select
      soi.sales_order_id,
      sum(soi.quantity)::numeric as line_items_total,
      sum(soi.quantity * soi.unit_price)::numeric as line_amount_total
    from public.sales_order_items soi
    group by soi.sales_order_id
  ),
  top_customer as (
    select
      p.name,
      sum(oi.line_amount_total)::numeric as revenue,
      sum(oi.line_items_total)::numeric as items
    from filtered_orders fo
    join order_items oi on oi.sales_order_id = fo.id
    left join public.partners p on p.id = fo.partner_id
    group by p.name
    order by revenue desc nulls last
    limit 1
  )
  select
    count(*)::bigint as total_orders,
    case when count(*) > 0 then
      (count(*) filter (where status in ('shipped', 'completed'))::numeric / count(*)::numeric) * 100
    else 0 end::numeric as delivery_rate,
    coalesce(sum(filtered_orders.total_amount), 0)::numeric as total_amount,
    coalesce((select sum(oi.line_items_total) from order_items oi join filtered_orders fo on fo.id = oi.sales_order_id), 0)::numeric as total_items,
    coalesce((select max(oi.line_amount_total) from order_items oi join filtered_orders fo on fo.id = oi.sales_order_id), 0)::numeric as highest_single_order_amount,
    coalesce((select max(oi.line_items_total) from order_items oi join filtered_orders fo on fo.id = oi.sales_order_id), 0)::numeric as highest_single_order_items,
    coalesce((select name from top_customer), 'No customer') as top_customer_name,
    coalesce((select revenue from top_customer), 0)::numeric as top_customer_revenue,
    coalesce((select items from top_customer), 0)::numeric as top_customer_items
  from filtered_orders;
$$;

create or replace function public.purchase_report_summary(
  p_period text default 'monthly'
)
returns table (
  total_orders bigint,
  receive_rate numeric,
  total_amount numeric,
  total_items numeric,
  highest_single_order_amount numeric,
  highest_single_order_items numeric,
  top_supplier_name text,
  top_supplier_spend numeric,
  top_supplier_items numeric
)
language sql
security definer
set search_path = public
as $$
  with filtered_orders as (
    select *
    from public.purchase_orders
    where order_date >= case
      when lower(coalesce(p_period, 'monthly')) = 'weekly' then current_date - interval '7 days'
      when lower(coalesce(p_period, 'monthly')) = 'monthly' then date_trunc('month', current_date)::date
      else current_date - interval '100 years'
    end
  ),
  order_items as (
    select
      poi.purchase_order_id,
      sum(poi.quantity)::numeric as line_items_total,
      sum(poi.quantity * poi.unit_price)::numeric as line_amount_total
    from public.purchase_order_items poi
    group by poi.purchase_order_id
  ),
  top_supplier as (
    select
      p.name,
      sum(oi.line_amount_total)::numeric as spend,
      sum(oi.line_items_total)::numeric as items
    from filtered_orders fo
    join order_items oi on oi.purchase_order_id = fo.id
    left join public.partners p on p.id = fo.partner_id
    group by p.name
    order by spend desc nulls last
    limit 1
  )
  select
    count(*)::bigint as total_orders,
    case when count(*) > 0 then
      (count(*) filter (where status in ('received', 'completed'))::numeric / count(*)::numeric) * 100
    else 0 end::numeric as receive_rate,
    coalesce(sum(filtered_orders.total_amount), 0)::numeric as total_amount,
    coalesce((select sum(oi.line_items_total) from order_items oi join filtered_orders fo on fo.id = oi.purchase_order_id), 0)::numeric as total_items,
    coalesce((select max(oi.line_amount_total) from order_items oi join filtered_orders fo on fo.id = oi.purchase_order_id), 0)::numeric as highest_single_order_amount,
    coalesce((select max(oi.line_items_total) from order_items oi join filtered_orders fo on fo.id = oi.purchase_order_id), 0)::numeric as highest_single_order_items,
    coalesce((select name from top_supplier), 'No supplier') as top_supplier_name,
    coalesce((select spend from top_supplier), 0)::numeric as top_supplier_spend,
    coalesce((select items from top_supplier), 0)::numeric as top_supplier_items
  from filtered_orders;
$$;

create or replace function public.inventory_report_summary()
returns table (
  total_item_in_stock numeric,
  total_stock_value numeric,
  top_sold_item_name text,
  top_sold_item_quantity numeric,
  top_sold_item_amount numeric,
  top_purchased_item_name text,
  top_purchased_item_quantity numeric,
  top_purchased_item_amount numeric
)
language sql
security definer
set search_path = public
as $$
  with sold as (
    select
      i.name,
      sum(soi.quantity)::numeric as quantity,
      sum(soi.quantity * soi.unit_price)::numeric as amount
    from public.sales_order_items soi
    join public.inventory_items i on i.id = soi.item_id
    group by i.name
    order by amount desc nulls last
    limit 1
  ),
  purchased as (
    select
      i.name,
      sum(poi.quantity)::numeric as quantity,
      sum(poi.quantity * poi.unit_price)::numeric as amount
    from public.purchase_order_items poi
    join public.inventory_items i on i.id = poi.item_id
    group by i.name
    order by amount desc nulls last
    limit 1
  ),
  stock as (
    select
      coalesce(sum(current_stock), 0)::numeric as total_item_in_stock,
      coalesce(sum(current_stock * i.bought_price), 0)::numeric as total_stock_value
    from public.inventory_stock_summary s
    join public.inventory_items i on i.id = s.item_id
  )
  select
    stock.total_item_in_stock,
    stock.total_stock_value,
    coalesce((select name from sold), 'No sales'),
    coalesce((select quantity from sold), 0)::numeric,
    coalesce((select amount from sold), 0)::numeric,
    coalesce((select name from purchased), 'No purchases'),
    coalesce((select quantity from purchased), 0)::numeric,
    coalesce((select amount from purchased), 0)::numeric
  from stock;
$$;

create or replace function public.inventory_adjustment_report_summary(
  p_period text default 'monthly'
)
returns table (
  total_adjustments bigint,
  positive_adjustment numeric,
  negative_adjustment numeric,
  positive_items bigint,
  positive_quantities numeric,
  positive_amount numeric,
  negative_items bigint,
  negative_quantities numeric,
  negative_amount numeric
)
language sql
security definer
set search_path = public
as $$
  with filtered as (
    select
      sm.*,
      i.bought_price
    from public.stock_movements sm
    join public.inventory_items i on i.id = sm.item_id
    where sm.movement_type in ('adjustment_plus', 'adjustment_minus')
      and sm.movement_date >= case
        when lower(coalesce(p_period, 'monthly')) = 'weekly' then current_date - interval '7 days'
        when lower(coalesce(p_period, 'monthly')) = 'monthly' then date_trunc('month', current_date)::date
        else current_date - interval '100 years'
      end
  )
  select
    count(*)::bigint as total_adjustments,
    coalesce(sum(quantity) filter (where movement_type = 'adjustment_plus'), 0)::numeric as positive_adjustment,
    coalesce(sum(quantity) filter (where movement_type = 'adjustment_minus'), 0)::numeric as negative_adjustment,
    count(distinct item_id) filter (where movement_type = 'adjustment_plus')::bigint as positive_items,
    coalesce(sum(quantity) filter (where movement_type = 'adjustment_plus'), 0)::numeric as positive_quantities,
    coalesce(sum(quantity * bought_price) filter (where movement_type = 'adjustment_plus'), 0)::numeric as positive_amount,
    count(distinct item_id) filter (where movement_type = 'adjustment_minus')::bigint as negative_items,
    coalesce(sum(quantity) filter (where movement_type = 'adjustment_minus'), 0)::numeric as negative_quantities,
    coalesce(sum(quantity * bought_price) filter (where movement_type = 'adjustment_minus'), 0)::numeric as negative_amount
  from filtered;
$$;

alter table public.partners enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_item_images enable row level security;
alter table public.stock_movements enable row level security;
alter table public.accounts enable row level security;
alter table public.account_transfers enable row level security;
alter table public.sales_orders enable row level security;
alter table public.sales_order_items enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_order_items enable row level security;
alter table public.loan_records enable row level security;

drop policy if exists "partners_select" on public.partners;
create policy "partners_select" on public.partners
for select to authenticated
using (public.has_app_access());

drop policy if exists "partners_insert" on public.partners;
create policy "partners_insert" on public.partners
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "partners_update" on public.partners;
create policy "partners_update" on public.partners
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "inventory_items_select" on public.inventory_items;
create policy "inventory_items_select" on public.inventory_items
for select to authenticated
using (public.has_app_access());

drop policy if exists "inventory_items_insert" on public.inventory_items;
create policy "inventory_items_insert" on public.inventory_items
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "inventory_items_update" on public.inventory_items;
create policy "inventory_items_update" on public.inventory_items
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "inventory_item_images_select" on public.inventory_item_images;
create policy "inventory_item_images_select" on public.inventory_item_images
for select to authenticated
using (public.has_app_access());

drop policy if exists "inventory_item_images_insert" on public.inventory_item_images;
create policy "inventory_item_images_insert" on public.inventory_item_images
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "inventory_item_images_update" on public.inventory_item_images;
create policy "inventory_item_images_update" on public.inventory_item_images
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "stock_movements_select" on public.stock_movements;
create policy "stock_movements_select" on public.stock_movements
for select to authenticated
using (public.has_app_access());

drop policy if exists "stock_movements_insert" on public.stock_movements;
create policy "stock_movements_insert" on public.stock_movements
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "stock_movements_update" on public.stock_movements;
create policy "stock_movements_update" on public.stock_movements
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "sales_orders_select" on public.sales_orders;
create policy "sales_orders_select" on public.sales_orders
for select to authenticated
using (public.has_app_access());

drop policy if exists "sales_orders_insert" on public.sales_orders;
create policy "sales_orders_insert" on public.sales_orders
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "sales_orders_update" on public.sales_orders;
create policy "sales_orders_update" on public.sales_orders
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "sales_order_items_select" on public.sales_order_items;
create policy "sales_order_items_select" on public.sales_order_items
for select to authenticated
using (
  public.has_app_access()
  and exists (
    select 1
    from public.sales_orders so
    where so.id = sales_order_id
  )
);

drop policy if exists "sales_order_items_insert" on public.sales_order_items;
create policy "sales_order_items_insert" on public.sales_order_items
for insert to authenticated
with check (
  public.has_app_access()
  and exists (
    select 1
    from public.sales_orders so
    where so.id = sales_order_id
  )
);

drop policy if exists "sales_order_items_update" on public.sales_order_items;
create policy "sales_order_items_update" on public.sales_order_items
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "purchase_orders_select" on public.purchase_orders;
create policy "purchase_orders_select" on public.purchase_orders
for select to authenticated
using (public.has_app_access());

drop policy if exists "purchase_orders_insert" on public.purchase_orders;
create policy "purchase_orders_insert" on public.purchase_orders
for insert to authenticated
with check (public.has_app_access() and created_by = auth.uid());

drop policy if exists "purchase_orders_update" on public.purchase_orders;
create policy "purchase_orders_update" on public.purchase_orders
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "purchase_order_items_select" on public.purchase_order_items;
create policy "purchase_order_items_select" on public.purchase_order_items
for select to authenticated
using (
  public.has_app_access()
  and exists (
    select 1
    from public.purchase_orders po
    where po.id = purchase_order_id
  )
);

drop policy if exists "purchase_order_items_insert" on public.purchase_order_items;
create policy "purchase_order_items_insert" on public.purchase_order_items
for insert to authenticated
with check (
  public.has_app_access()
  and exists (
    select 1
    from public.purchase_orders po
    where po.id = purchase_order_id
  )
);

drop policy if exists "purchase_order_items_update" on public.purchase_order_items;
create policy "purchase_order_items_update" on public.purchase_order_items
for update to authenticated
using (public.has_app_access())
with check (public.has_app_access());

drop policy if exists "accounts_owner_select" on public.accounts;
create policy "accounts_owner_select" on public.accounts
for select to authenticated
using (public.is_owner());

drop policy if exists "accounts_owner_insert" on public.accounts;
create policy "accounts_owner_insert" on public.accounts
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "accounts_owner_update" on public.accounts;
create policy "accounts_owner_update" on public.accounts
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

drop policy if exists "account_transfers_owner_select" on public.account_transfers;
create policy "account_transfers_owner_select" on public.account_transfers
for select to authenticated
using (public.is_owner());

drop policy if exists "account_transfers_owner_insert" on public.account_transfers;
create policy "account_transfers_owner_insert" on public.account_transfers
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "loan_records_owner_select" on public.loan_records;
create policy "loan_records_owner_select" on public.loan_records
for select to authenticated
using (public.is_owner());

drop policy if exists "loan_records_owner_insert" on public.loan_records;
create policy "loan_records_owner_insert" on public.loan_records
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "loan_records_owner_update" on public.loan_records;
create policy "loan_records_owner_update" on public.loan_records
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

drop policy if exists "expense_entries_owner_select" on public.expense_entries;
create policy "expense_entries_owner_select" on public.expense_entries
for select to authenticated
using (public.is_owner());

drop policy if exists "expense_entries_owner_insert" on public.expense_entries;
create policy "expense_entries_owner_insert" on public.expense_entries
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "expense_entries_owner_update" on public.expense_entries;
create policy "expense_entries_owner_update" on public.expense_entries
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

insert into storage.buckets (id, name, public)
values ('inventory-images', 'inventory-images', false)
on conflict (id) do nothing;

drop policy if exists "inventory_images_select" on storage.objects;
create policy "inventory_images_select" on storage.objects
for select to authenticated
using (
  bucket_id = 'inventory-images'
  and public.has_app_access()
);

drop policy if exists "inventory_images_insert" on storage.objects;
create policy "inventory_images_insert" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'inventory-images'
  and public.has_app_access()
);

drop policy if exists "inventory_images_update" on storage.objects;
create policy "inventory_images_update" on storage.objects
for update to authenticated
using (
  bucket_id = 'inventory-images'
  and public.has_app_access()
)
with check (
  bucket_id = 'inventory-images'
  and public.has_app_access()
);

drop policy if exists "inventory_images_delete" on storage.objects;
create policy "inventory_images_delete" on storage.objects
for delete to authenticated
using (
  bucket_id = 'inventory-images'
  and public.has_app_access()
);

create or replace function public.log_partner_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'partner_saved',
    format('Partner saved: %s', new.name),
    new.created_by,
    jsonb_build_object('partner_id', new.id)
  );
  return new;
end;
$$;

create or replace function public.log_inventory_item_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'inventory_item_saved',
    format('Inventory item saved: %s', new.name),
    new.created_by,
    jsonb_build_object('inventory_item_id', new.id, 'sku', new.sku)
  );
  return new;
end;
$$;

create or replace function public.log_sales_order_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'sales_order_saved',
    format('Sales order saved: %s', new.order_code),
    new.created_by,
    jsonb_build_object('sales_order_id', new.id, 'order_code', new.order_code)
  );
  return new;
end;
$$;

create or replace function public.log_purchase_order_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'purchase_order_saved',
    format('Purchase order saved: %s', new.order_code),
    new.created_by,
    jsonb_build_object('purchase_order_id', new.id, 'order_code', new.order_code)
  );
  return new;
end;
$$;

create or replace function public.log_account_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'account_saved',
    format('Account saved: %s', new.account_name),
    new.created_by,
    jsonb_build_object('account_id', new.id, 'account_code', new.account_code)
  );
  return new;
end;
$$;

create or replace function public.log_transfer_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'account_transfer_saved',
    'Account transfer saved',
    new.created_by,
    jsonb_build_object('account_transfer_id', new.id, 'amount', new.amount)
  );
  return new;
end;
$$;

create or replace function public.log_loan_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'loan_record_saved',
    'Loan record saved',
    new.created_by,
    jsonb_build_object('loan_record_id', new.id, 'amount', new.amount, 'direction', new.direction)
  );
  return new;
end;
$$;

drop trigger if exists log_partner_after_insert on public.partners;
create trigger log_partner_after_insert
after insert on public.partners
for each row
execute function public.log_partner_entry();

drop trigger if exists log_inventory_item_after_insert on public.inventory_items;
create trigger log_inventory_item_after_insert
after insert on public.inventory_items
for each row
execute function public.log_inventory_item_entry();

drop trigger if exists log_sales_order_after_insert on public.sales_orders;
create trigger log_sales_order_after_insert
after insert on public.sales_orders
for each row
execute function public.log_sales_order_entry();

drop trigger if exists log_purchase_order_after_insert on public.purchase_orders;
create trigger log_purchase_order_after_insert
after insert on public.purchase_orders
for each row
execute function public.log_purchase_order_entry();

drop trigger if exists log_account_after_insert on public.accounts;
create trigger log_account_after_insert
after insert on public.accounts
for each row
execute function public.log_account_entry();

drop trigger if exists log_transfer_after_insert on public.account_transfers;
create trigger log_transfer_after_insert
after insert on public.account_transfers
for each row
execute function public.log_transfer_entry();

drop trigger if exists log_loan_after_insert on public.loan_records;
create trigger log_loan_after_insert
after insert on public.loan_records
for each row
execute function public.log_loan_entry();

alter table public.sales_orders
  add column if not exists due_date date,
  add column if not exists last_payment_at timestamptz,
  add column if not exists payment_count integer not null default 0,
  add column if not exists last_reminder_at timestamptz,
  add column if not exists next_reminder_at timestamptz,
  add column if not exists reminder_state text not null default 'none'
    check (reminder_state in ('none', 'upcoming', 'late', 'severe', 'settled'));

create table if not exists public.sales_order_payments (
  id uuid primary key default gen_random_uuid(),
  sales_order_id uuid not null references public.sales_orders (id) on delete cascade,
  account_id uuid not null references public.accounts (id),
  amount numeric(14, 2) not null check (amount > 0),
  payment_date date not null default current_date,
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sales_order_reminders (
  id uuid primary key default gen_random_uuid(),
  sales_order_id uuid not null references public.sales_orders (id) on delete cascade,
  reminder_state text not null check (reminder_state in ('late', 'severe')),
  balance_snapshot numeric(14, 2) not null check (balance_snapshot >= 0),
  days_overdue_snapshot integer not null default 0,
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.owner_devices (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  installation_id text not null unique,
  platform text not null,
  push_token text,
  notifications_enabled boolean not null default true,
  last_seen_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists sales_orders_due_date_idx
on public.sales_orders (due_date desc);

create index if not exists sales_orders_next_reminder_at_idx
on public.sales_orders (next_reminder_at asc)
where balance_amount > 0;

create index if not exists sales_order_payments_sales_order_idx
on public.sales_order_payments (sales_order_id, payment_date desc);

create index if not exists sales_order_payments_account_idx
on public.sales_order_payments (account_id, payment_date desc);

create index if not exists sales_order_reminders_sales_order_idx
on public.sales_order_reminders (sales_order_id, created_at desc);

drop trigger if exists set_owner_devices_updated_at on public.owner_devices;
create trigger set_owner_devices_updated_at
before update on public.owner_devices
for each row
execute function public.set_updated_at();

create or replace function public.refresh_sales_order_financials(
  p_sales_order_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order public.sales_orders%rowtype;
  target_total numeric(14, 2);
  target_paid numeric(14, 2);
  target_balance numeric(14, 2);
  target_payment_count integer;
  target_last_payment_at timestamptz;
  computed_due_date date;
  computed_reminder_state text;
  computed_next_reminder_at timestamptz;
  overdue_days integer;
begin
  select *
  into target_order
  from public.sales_orders
  where id = p_sales_order_id;

  if not found then
    return;
  end if;

  select coalesce(sum(quantity * unit_price), 0)::numeric(14, 2)
  into target_total
  from public.sales_order_items
  where sales_order_id = p_sales_order_id;

  select
    coalesce(sum(amount), 0)::numeric(14, 2),
    count(*)::integer,
    max(payment_date)::timestamp at time zone 'utc'
  into
    target_paid,
    target_payment_count,
    target_last_payment_at
  from public.sales_order_payments
  where sales_order_id = p_sales_order_id;

  target_balance := greatest(target_total - target_paid, 0);
  computed_due_date := target_order.due_date;
  if target_balance > 0 and computed_due_date is null then
    computed_due_date := coalesce(target_order.shipment_date, target_order.order_date, current_date) + 7;
  elsif target_balance = 0 then
    computed_due_date := target_order.due_date;
  end if;

  overdue_days := case
    when computed_due_date is null or target_balance <= 0 then 0
    else greatest((current_date - computed_due_date), 0)
  end;

  computed_reminder_state := case
    when target_balance <= 0 then 'settled'
    when computed_due_date is null then 'none'
    when computed_due_date > current_date then 'upcoming'
    when overdue_days >= 7 then 'severe'
    else 'late'
  end;

  computed_next_reminder_at := case
    when target_balance <= 0 then null
    when computed_due_date is null then null
    when computed_due_date > current_date then (computed_due_date::timestamp at time zone 'utc')
    when target_order.last_reminder_at is not null then target_order.last_reminder_at + interval '7 days'
    else timezone('utc', now())
  end;

  update public.sales_orders
  set
    total_amount = target_total,
    paid_amount = target_paid,
    balance_amount = target_balance,
    payment_count = target_payment_count,
    last_payment_at = target_last_payment_at,
    due_date = computed_due_date,
    reminder_state = computed_reminder_state,
    next_reminder_at = computed_next_reminder_at,
    updated_at = timezone('utc', now())
  where id = p_sales_order_id;
end;
$$;

create or replace function public.normalize_sales_order()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.paid_amount := greatest(new.paid_amount, 0);
  new.total_amount := greatest(new.total_amount, 0);
  new.balance_amount := greatest(new.total_amount - new.paid_amount, 0);

  if new.balance_amount > 0 and new.due_date is null then
    new.due_date := coalesce(new.shipment_date, new.order_date, current_date) + 7;
  end if;

  if new.balance_amount = 0 then
    new.reminder_state := 'settled';
    new.next_reminder_at := null;
  end if;

  return new;
end;
$$;

create or replace function public.sync_sales_order_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id uuid;
begin
  target_order_id := coalesce(new.sales_order_id, old.sales_order_id);
  perform public.refresh_sales_order_financials(target_order_id);
  return coalesce(new, old);
end;
$$;

create or replace function public.sync_sales_order_payment_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order_id uuid;
begin
  target_order_id := coalesce(new.sales_order_id, old.sales_order_id);
  perform public.refresh_sales_order_financials(target_order_id);
  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_sales_order_payments_after_write on public.sales_order_payments;
create trigger sync_sales_order_payments_after_write
after insert or update or delete on public.sales_order_payments
for each row
execute function public.sync_sales_order_payment_totals();

create or replace function public.record_sales_order_payment(
  p_sales_order_id uuid,
  p_account_id uuid,
  p_amount numeric,
  p_payment_date date default current_date,
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_order public.sales_orders%rowtype;
  payment_id uuid;
begin
  if not public.is_owner() then
    raise exception 'owner access required'
      using errcode = '42501';
  end if;

  select *
  into target_order
  from public.sales_orders
  where id = p_sales_order_id;

  if not found then
    raise exception 'sales order not found'
      using errcode = 'P0002';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be greater than 0'
      using errcode = '22023';
  end if;

  if target_order.balance_amount > 0 and p_amount > target_order.balance_amount then
    raise exception 'payment amount cannot be greater than remaining balance'
      using errcode = '22023';
  end if;

  insert into public.sales_order_payments (
    sales_order_id,
    account_id,
    amount,
    payment_date,
    note,
    created_by
  )
  values (
    p_sales_order_id,
    p_account_id,
    p_amount,
    coalesce(p_payment_date, current_date),
    nullif(btrim(p_note), ''),
    auth.uid()
  )
  returning id into payment_id;

  perform public.write_activity_log(
    'sales_payment_recorded',
    jsonb_build_object(
      'sales_order_id', p_sales_order_id,
      'payment_id', payment_id,
      'amount', p_amount
    )
  );

  return payment_id;
end;
$$;

create or replace function public.sales_balance_alerts()
returns table (
  sales_order_id uuid,
  order_code text,
  partner_id uuid,
  customer_name text,
  customer_phone text,
  order_date date,
  due_date date,
  total_amount numeric,
  paid_amount numeric,
  balance_amount numeric,
  payment_count integer,
  last_payment_at timestamptz,
  days_overdue integer,
  overdue_level text,
  reminder_state text,
  next_reminder_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    so.id,
    so.order_code,
    so.partner_id,
    p.name as customer_name,
    p.phone as customer_phone,
    so.order_date,
    so.due_date,
    so.total_amount,
    so.paid_amount,
    so.balance_amount,
    so.payment_count,
    so.last_payment_at,
    case
      when so.due_date is null or so.balance_amount <= 0 then 0
      else greatest((current_date - so.due_date), 0)
    end::integer as days_overdue,
    case
      when so.balance_amount <= 0 then 'settled'
      when so.due_date is null then 'pending'
      when so.due_date > current_date then 'upcoming'
      when (current_date - so.due_date) >= 7 then 'severe'
      else 'late'
    end as overdue_level,
    so.reminder_state,
    so.next_reminder_at
  from public.sales_orders so
  left join public.partners p on p.id = so.partner_id
  where public.is_owner()
    and so.balance_amount > 0
    and so.status <> 'cancelled'
  order by
    case
      when so.due_date is null then 2
      when so.due_date <= current_date then 0
      else 1
    end,
    so.due_date nulls last,
    so.created_at desc;
$$;

create or replace function public.mark_sales_order_reminder_sent(
  p_sales_order_id uuid,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  alert_row record;
begin
  if not public.is_owner() then
    raise exception 'owner access required'
      using errcode = '42501';
  end if;

  select *
  into alert_row
  from public.sales_balance_alerts()
  where sales_order_id = p_sales_order_id;

  if not found then
    return;
  end if;

  update public.sales_orders
  set
    last_reminder_at = timezone('utc', now()),
    next_reminder_at = timezone('utc', now()) + interval '7 days',
    reminder_state = case
      when alert_row.overdue_level = 'severe' then 'severe'
      when alert_row.overdue_level = 'late' then 'late'
      else reminder_state
    end,
    updated_at = timezone('utc', now())
  where id = p_sales_order_id;

  insert into public.sales_order_reminders (
    sales_order_id,
    reminder_state,
    balance_snapshot,
    days_overdue_snapshot,
    note,
    created_by
  )
  values (
    p_sales_order_id,
    case
      when alert_row.overdue_level = 'severe' then 'severe'
      else 'late'
    end,
    alert_row.balance_amount,
    alert_row.days_overdue,
    nullif(btrim(p_note), ''),
    auth.uid()
  );

  perform public.write_activity_log(
    'sales_payment_reminder_sent',
    jsonb_build_object(
      'sales_order_id', p_sales_order_id,
      'balance_amount', alert_row.balance_amount,
      'days_overdue', alert_row.days_overdue
    )
  );
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
  with sales_payments_by_account as (
    select
      sp.account_id,
      sum(sp.amount)::numeric as total_amount
    from public.sales_order_payments sp
    group by sp.account_id
  ),
  legacy_sales_by_account as (
    select
      so.account_id,
      sum(so.paid_amount)::numeric as total_amount
    from public.sales_orders so
    where so.account_id is not null
      and not exists (
        select 1
        from public.sales_order_payments sp
        where sp.sales_order_id = so.id
      )
    group by so.account_id
  )
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
      + coalesce((select total_amount from sales_payments_by_account spa where spa.account_id = a.id), 0)
      + coalesce((select total_amount from legacy_sales_by_account lsa where lsa.account_id = a.id), 0)
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

drop function if exists public.home_overview_summary(text);
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
  net_profit numeric,
  overdue_orders_count bigint,
  overdue_balance_total numeric
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
    ),
    overdue as (
      select
        count(*)::bigint as overdue_orders_count,
        coalesce(sum(balance_amount), 0)::numeric as overdue_balance_total
      from public.sales_orders
      where balance_amount > 0
        and due_date is not null
        and due_date < current_date
        and status <> 'cancelled'
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
      (profits.estimated_profit - expenses.total_expenses)::numeric as net_profit,
      overdue.overdue_orders_count,
      overdue.overdue_balance_total
    from stock, sales, purchases, loans, balances, profits, expenses, overdue;
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
    null::numeric,
    null::bigint,
    null::numeric
  from stock, sales, purchases;
end;
$$;

alter table public.sales_order_payments enable row level security;
alter table public.sales_order_reminders enable row level security;
alter table public.owner_devices enable row level security;

drop policy if exists "sales_order_payments_owner_select" on public.sales_order_payments;
create policy "sales_order_payments_owner_select" on public.sales_order_payments
for select to authenticated
using (public.is_owner());

drop policy if exists "sales_order_payments_owner_insert" on public.sales_order_payments;
create policy "sales_order_payments_owner_insert" on public.sales_order_payments
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "sales_order_payments_owner_update" on public.sales_order_payments;
create policy "sales_order_payments_owner_update" on public.sales_order_payments
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

drop policy if exists "sales_order_reminders_owner_select" on public.sales_order_reminders;
create policy "sales_order_reminders_owner_select" on public.sales_order_reminders
for select to authenticated
using (public.is_owner());

drop policy if exists "sales_order_reminders_owner_insert" on public.sales_order_reminders;
create policy "sales_order_reminders_owner_insert" on public.sales_order_reminders
for insert to authenticated
with check (public.is_owner() and created_by = auth.uid());

drop policy if exists "owner_devices_owner_select" on public.owner_devices;
create policy "owner_devices_owner_select" on public.owner_devices
for select to authenticated
using (public.is_owner() and owner_id = auth.uid());

drop policy if exists "owner_devices_owner_insert" on public.owner_devices;
create policy "owner_devices_owner_insert" on public.owner_devices
for insert to authenticated
with check (public.is_owner() and owner_id = auth.uid());

drop policy if exists "owner_devices_owner_update" on public.owner_devices;
create policy "owner_devices_owner_update" on public.owner_devices
for update to authenticated
using (public.is_owner() and owner_id = auth.uid())
with check (public.is_owner() and owner_id = auth.uid());

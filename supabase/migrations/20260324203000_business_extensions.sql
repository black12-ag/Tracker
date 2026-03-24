alter table public.product_settings
add column if not exists product_image_path text;

create table if not exists public.expense_entries (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null default current_date,
  category text not null,
  amount numeric(12, 2) not null check (amount > 0),
  note text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  message text not null,
  actor_id uuid references public.profiles (id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists expense_entries_expense_date_idx
on public.expense_entries (expense_date desc);

create index if not exists activity_logs_created_at_idx
on public.activity_logs (created_at desc);

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

drop function if exists public.get_product_public_settings();

create or replace function public.get_product_public_settings()
returns table (
  id integer,
  product_name text,
  product_image_path text
)
language sql
security definer
set search_path = public
as $$
  select ps.id, ps.product_name, ps.product_image_path
  from public.product_settings ps;
$$;

drop function if exists public.owner_finance_summary();

create or replace function public.owner_finance_summary()
returns table (
  total_sales numeric,
  total_paid numeric,
  total_balance numeric,
  estimated_profit numeric,
  total_expenses numeric,
  net_profit numeric,
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
  with finance as (
    select
      coalesce(sum(sf.total_amount), 0)::numeric as total_sales,
      coalesce(sum(sf.paid_amount), 0)::numeric as total_paid,
      coalesce(sum(sf.balance_amount), 0)::numeric as total_balance,
      coalesce(sum((sf.unit_price_snapshot - sf.unit_cost_snapshot) * sd.quantity_units), 0)::numeric as estimated_profit,
      count(*) filter (where sf.balance_amount > 0)::bigint as open_loans
    from public.sale_finance sf
    join public.sales_dispatches sd on sd.id = sf.dispatch_id
  ),
  expenses as (
    select coalesce(sum(amount), 0)::numeric as total_expenses
    from public.expense_entries
  )
  select
    finance.total_sales,
    finance.total_paid,
    finance.total_balance,
    finance.estimated_profit,
    expenses.total_expenses,
    (finance.estimated_profit - expenses.total_expenses)::numeric as net_profit,
    finance.open_loans
  from finance, expenses;
end;
$$;

create or replace function public.write_activity_log(
  log_event_type text,
  log_message text,
  log_actor_id uuid,
  log_metadata jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.activity_logs (event_type, message, actor_id, metadata)
  values (log_event_type, log_message, log_actor_id, coalesce(log_metadata, '{}'::jsonb));
$$;

create or replace function public.log_production_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  size_label text;
begin
  select label into size_label
  from public.product_sizes
  where id = new.size_id;

  perform public.write_activity_log(
    'production_created',
    format('Production recorded: %s units of %s', new.quantity_units, coalesce(size_label, 'product')),
    new.created_by,
    jsonb_build_object('production_entry_id', new.id, 'size_id', new.size_id, 'quantity_units', new.quantity_units)
  );

  return new;
end;
$$;

create or replace function public.log_sales_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_name text;
begin
  select name into customer_name
  from public.customers
  where id = new.customer_id;

  perform public.write_activity_log(
    'sale_created',
    format('Sale recorded for %s', coalesce(customer_name, 'customer')),
    new.created_by,
    jsonb_build_object('sales_dispatch_id', new.id, 'customer_id', new.customer_id, 'quantity_units', new.quantity_units)
  );

  return new;
end;
$$;

create or replace function public.log_sale_finance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'finance_attached',
    'Finance attached to a recorded dispatch',
    auth.uid(),
    jsonb_build_object('sale_finance_id', new.id, 'dispatch_id', new.dispatch_id, 'total_amount', new.total_amount)
  );

  return new;
end;
$$;

create or replace function public.log_payment_record()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'payment_recorded',
    'Payment recorded against a customer loan',
    auth.uid(),
    jsonb_build_object('payment_record_id', new.id, 'sale_finance_id', new.sale_finance_id, 'amount', new.amount)
  );

  return new;
end;
$$;

create or replace function public.log_expense_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.write_activity_log(
    'expense_recorded',
    format('Expense recorded: %s', new.category),
    new.created_by,
    jsonb_build_object('expense_entry_id', new.id, 'amount', new.amount, 'category', new.category)
  );

  return new;
end;
$$;

drop trigger if exists log_production_entry_after_insert on public.production_entries;
create trigger log_production_entry_after_insert
after insert on public.production_entries
for each row
execute function public.log_production_entry();

drop trigger if exists log_sales_dispatch_after_insert on public.sales_dispatches;
create trigger log_sales_dispatch_after_insert
after insert on public.sales_dispatches
for each row
execute function public.log_sales_dispatch();

drop trigger if exists log_sale_finance_after_insert on public.sale_finance;
create trigger log_sale_finance_after_insert
after insert on public.sale_finance
for each row
execute function public.log_sale_finance();

drop trigger if exists log_payment_record_after_insert on public.payment_records;
create trigger log_payment_record_after_insert
after insert on public.payment_records
for each row
execute function public.log_payment_record();

drop trigger if exists log_expense_entry_after_insert on public.expense_entries;
create trigger log_expense_entry_after_insert
after insert on public.expense_entries
for each row
execute function public.log_expense_entry();

alter table public.expense_entries enable row level security;
alter table public.activity_logs enable row level security;

create policy "expense_entries_owner_only" on public.expense_entries
for all
to authenticated
using (public.is_owner())
with check (public.is_owner() and created_by = auth.uid());

create policy "activity_logs_shared_select" on public.activity_logs
for select
to authenticated
using (public.has_app_access());

insert into storage.buckets (id, name, public)
values ('product-media', 'product-media', true)
on conflict (id) do nothing;

create policy "product_media_select" on storage.objects
for select
to authenticated
using (bucket_id = 'product-media' and public.has_app_access());

create policy "product_media_owner_insert" on storage.objects
for insert
to authenticated
with check (bucket_id = 'product-media' and public.is_owner());

create policy "product_media_owner_update" on storage.objects
for update
to authenticated
using (bucket_id = 'product-media' and public.is_owner())
with check (bucket_id = 'product-media' and public.is_owner());

create policy "product_media_owner_delete" on storage.objects
for delete
to authenticated
using (bucket_id = 'product-media' and public.is_owner());

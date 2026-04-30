-- ============================================================
-- 1. WORKSPACES TABLE
-- ============================================================
create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.workspaces enable row level security;

create policy "Workspace owner can read"
  on public.workspaces for select
  to authenticated
  using (owner_id = auth.uid());

create policy "Workspace owner can update"
  on public.workspaces for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- ============================================================
-- 2. ADD workspace_id TO PROFILES
-- ============================================================
alter table public.profiles
  add column if not exists workspace_id uuid references public.workspaces (id) on delete set null;

-- ============================================================
-- 3. ADD workspace_id TO ALL DATA TABLES
-- ============================================================
alter table public.sales_orders        add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.sales_order_items   add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.sales_order_payments add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.sales_order_reminders add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.sales_dispatches    add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.purchase_orders     add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.purchase_order_items add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.inventory_items     add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.inventory_item_images add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.stock_movements     add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.production_entries  add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.customers           add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.partners            add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.accounts            add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.account_transfers   add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.expense_entries     add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.loan_records        add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.sale_finance        add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.payment_records     add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.product_settings    add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.product_sizes       add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.size_prices         add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.activity_logs       add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.owner_devices       add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;
alter table public.document_counters   add column if not exists workspace_id uuid references public.workspaces (id) on delete cascade;

-- ============================================================
-- 4. BACKFILL: create one workspace per existing owner profile
-- ============================================================
do $$
declare
  owner_row record;
  new_workspace_id uuid;
begin
  for owner_row in
    select id, email from public.profiles where role = 'owner'
  loop
    insert into public.workspaces (name, owner_id)
    values (split_part(owner_row.email, '@', 1), owner_row.id)
    returning id into new_workspace_id;

    update public.profiles
    set workspace_id = new_workspace_id
    where id = owner_row.id;

    update public.profiles
    set workspace_id = new_workspace_id
    where created_by_owner = owner_row.id;

    update public.sales_orders        set workspace_id = new_workspace_id where workspace_id is null;
    update public.sales_order_items   set workspace_id = new_workspace_id where workspace_id is null;
    update public.sales_order_payments set workspace_id = new_workspace_id where workspace_id is null;
    update public.sales_order_reminders set workspace_id = new_workspace_id where workspace_id is null;
    update public.sales_dispatches    set workspace_id = new_workspace_id where workspace_id is null;
    update public.purchase_orders     set workspace_id = new_workspace_id where workspace_id is null;
    update public.purchase_order_items set workspace_id = new_workspace_id where workspace_id is null;
    update public.inventory_items     set workspace_id = new_workspace_id where workspace_id is null;
    update public.inventory_item_images set workspace_id = new_workspace_id where workspace_id is null;
    update public.stock_movements     set workspace_id = new_workspace_id where workspace_id is null;
    update public.production_entries  set workspace_id = new_workspace_id where workspace_id is null;
    update public.customers           set workspace_id = new_workspace_id where workspace_id is null;
    update public.partners            set workspace_id = new_workspace_id where workspace_id is null;
    update public.accounts            set workspace_id = new_workspace_id where workspace_id is null;
    update public.account_transfers   set workspace_id = new_workspace_id where workspace_id is null;
    update public.expense_entries     set workspace_id = new_workspace_id where workspace_id is null;
    update public.loan_records        set workspace_id = new_workspace_id where workspace_id is null;
    update public.sale_finance        set workspace_id = new_workspace_id where workspace_id is null;
    update public.payment_records     set workspace_id = new_workspace_id where workspace_id is null;
    update public.product_settings    set workspace_id = new_workspace_id where workspace_id is null;
    update public.product_sizes       set workspace_id = new_workspace_id where workspace_id is null;
    update public.size_prices         set workspace_id = new_workspace_id where workspace_id is null;
    update public.activity_logs       set workspace_id = new_workspace_id where workspace_id is null;
    update public.owner_devices       set workspace_id = new_workspace_id where workspace_id is null;
    update public.document_counters   set workspace_id = new_workspace_id where workspace_id is null;
  end loop;
end $$;

-- ============================================================
-- 5. HELPER FUNCTION
-- ============================================================
create or replace function public.get_my_workspace_id()
returns uuid
language sql
stable
security definer
as $$
  select workspace_id from public.profiles where id = auth.uid();
$$;

-- ============================================================
-- 6. UPDATE RLS POLICIES ON ALL DATA TABLES
-- ============================================================

-- SALES_ORDERS
drop policy if exists "Owner can select sales_orders" on public.sales_orders;
drop policy if exists "Owner can insert sales_orders" on public.sales_orders;
drop policy if exists "Owner can update sales_orders" on public.sales_orders;
drop policy if exists "Owner can delete sales_orders" on public.sales_orders;
drop policy if exists "Workspace members can read sales_orders" on public.sales_orders;
drop policy if exists "Workspace members can insert sales_orders" on public.sales_orders;
drop policy if exists "Workspace owner can update sales_orders" on public.sales_orders;
drop policy if exists "Workspace owner can delete sales_orders" on public.sales_orders;

create policy "Workspace members can read sales_orders"
  on public.sales_orders for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can insert sales_orders"
  on public.sales_orders for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can update sales_orders"
  on public.sales_orders for update to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace owner can delete sales_orders"
  on public.sales_orders for delete to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PURCHASE_ORDERS
drop policy if exists "Owner can select purchase_orders" on public.purchase_orders;
drop policy if exists "Owner can insert purchase_orders" on public.purchase_orders;
drop policy if exists "Owner can update purchase_orders" on public.purchase_orders;
drop policy if exists "Workspace members can read purchase_orders" on public.purchase_orders;
drop policy if exists "Workspace members can insert purchase_orders" on public.purchase_orders;
drop policy if exists "Workspace members can update purchase_orders" on public.purchase_orders;

create policy "Workspace members can read purchase_orders"
  on public.purchase_orders for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can insert purchase_orders"
  on public.purchase_orders for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can update purchase_orders"
  on public.purchase_orders for update to authenticated
  using (workspace_id = public.get_my_workspace_id());

-- INVENTORY_ITEMS
drop policy if exists "Owner can select inventory_items" on public.inventory_items;
drop policy if exists "Owner can insert inventory_items" on public.inventory_items;
drop policy if exists "Owner can update inventory_items" on public.inventory_items;
drop policy if exists "Workspace members can read inventory_items" on public.inventory_items;
drop policy if exists "Workspace owner can insert inventory_items" on public.inventory_items;
drop policy if exists "Workspace owner can update inventory_items" on public.inventory_items;

create policy "Workspace members can read inventory_items"
  on public.inventory_items for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace owner can insert inventory_items"
  on public.inventory_items for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can update inventory_items"
  on public.inventory_items for update to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- CUSTOMERS
drop policy if exists "Owner can select customers" on public.customers;
drop policy if exists "Owner can insert customers" on public.customers;
drop policy if exists "Owner can update customers" on public.customers;
drop policy if exists "Workspace members can read customers" on public.customers;
drop policy if exists "Workspace members can insert customers" on public.customers;
drop policy if exists "Workspace members can update customers" on public.customers;

create policy "Workspace members can read customers"
  on public.customers for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can insert customers"
  on public.customers for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can update customers"
  on public.customers for update to authenticated
  using (workspace_id = public.get_my_workspace_id());

-- PARTNERS
drop policy if exists "Owner can select partners" on public.partners;
drop policy if exists "Owner can insert partners" on public.partners;
drop policy if exists "Owner can update partners" on public.partners;
drop policy if exists "Workspace members can read partners" on public.partners;
drop policy if exists "Workspace owner can insert partners" on public.partners;
drop policy if exists "Workspace owner can update partners" on public.partners;

create policy "Workspace members can read partners"
  on public.partners for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace owner can insert partners"
  on public.partners for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can update partners"
  on public.partners for update to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- ACCOUNTS
drop policy if exists "Owner can select accounts" on public.accounts;
drop policy if exists "Owner can insert accounts" on public.accounts;
drop policy if exists "Owner can update accounts" on public.accounts;
drop policy if exists "Workspace owner can read accounts" on public.accounts;
drop policy if exists "Workspace owner can insert accounts" on public.accounts;
drop policy if exists "Workspace owner can update accounts" on public.accounts;

create policy "Workspace owner can read accounts"
  on public.accounts for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can insert accounts"
  on public.accounts for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can update accounts"
  on public.accounts for update to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- EXPENSE_ENTRIES
drop policy if exists "Owner can select expense_entries" on public.expense_entries;
drop policy if exists "Owner can insert expense_entries" on public.expense_entries;
drop policy if exists "Workspace members can read expense_entries" on public.expense_entries;
drop policy if exists "Workspace owner can insert expense_entries" on public.expense_entries;

create policy "Workspace members can read expense_entries"
  on public.expense_entries for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace owner can insert expense_entries"
  on public.expense_entries for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PRODUCTION_ENTRIES
drop policy if exists "Owner can select production_entries" on public.production_entries;
drop policy if exists "Owner can insert production_entries" on public.production_entries;
drop policy if exists "Workspace members can read production_entries" on public.production_entries;
drop policy if exists "Workspace members can insert production_entries" on public.production_entries;

create policy "Workspace members can read production_entries"
  on public.production_entries for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can insert production_entries"
  on public.production_entries for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());

-- LOAN_RECORDS
drop policy if exists "Owner can select loan_records" on public.loan_records;
drop policy if exists "Workspace owner can read loan_records" on public.loan_records;
drop policy if exists "Workspace owner can insert loan_records" on public.loan_records;

create policy "Workspace owner can read loan_records"
  on public.loan_records for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can insert loan_records"
  on public.loan_records for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- SALE_FINANCE
drop policy if exists "Owner can select sale_finance" on public.sale_finance;
drop policy if exists "Workspace owner can read sale_finance" on public.sale_finance;
drop policy if exists "Workspace owner can insert sale_finance" on public.sale_finance;

create policy "Workspace owner can read sale_finance"
  on public.sale_finance for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can insert sale_finance"
  on public.sale_finance for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PAYMENT_RECORDS
drop policy if exists "Owner can select payment_records" on public.payment_records;
drop policy if exists "Workspace owner can read payment_records" on public.payment_records;
drop policy if exists "Workspace owner can insert payment_records" on public.payment_records;

create policy "Workspace owner can read payment_records"
  on public.payment_records for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Workspace owner can insert payment_records"
  on public.payment_records for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PROFILES
drop policy if exists "Owner can select staff profiles" on public.profiles;
drop policy if exists "Owner can insert staff profiles" on public.profiles;
drop policy if exists "Users can read their own profile" on public.profiles;
drop policy if exists "Owner can insert staff profiles" on public.profiles;
drop policy if exists "Owner can update staff in their workspace" on public.profiles;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using (id = auth.uid() or workspace_id = public.get_my_workspace_id());
create policy "Owner can insert staff profiles"
  on public.profiles for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "Owner can update staff in their workspace"
  on public.profiles for update to authenticated
  using (id = auth.uid() or (workspace_id = public.get_my_workspace_id() and public.is_owner()));

-- DOCUMENT_COUNTERS
drop policy if exists "Authenticated users can read counters" on public.document_counters;
drop policy if exists "Authenticated users can update counters" on public.document_counters;
drop policy if exists "Workspace members can read counters" on public.document_counters;
drop policy if exists "Workspace members can update counters" on public.document_counters;
drop policy if exists "Workspace members can insert counters" on public.document_counters;

create policy "Workspace members can read counters"
  on public.document_counters for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can update counters"
  on public.document_counters for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());
create policy "Workspace members can insert counters"
  on public.document_counters for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());

-- ============================================================
-- 7. TRIGGER: auto-create workspace on new owner sign-up
-- ============================================================
create or replace function public.handle_new_owner_signup()
returns trigger
language plpgsql
security definer
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

  update public.profiles
  set workspace_id = new_workspace_id
  where id = new.id;

  return new;
end;
$$;

drop trigger if exists on_new_owner_create_workspace on public.profiles;
create trigger on_new_owner_create_workspace
  after insert on public.profiles
  for each row
  execute function public.handle_new_owner_signup();

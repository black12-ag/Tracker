-- ============================================================
-- Workspace-scope the secondary tables (close cross-tenant leaks)
-- ------------------------------------------------------------
-- The 20260430000000_workspaces migration added workspace_id to many tables
-- and re-scoped the 13 PRIMARY tables, but several SECONDARY tables kept their
-- old, global policies:
--   * product_sizes        : using (true)            -> any user reads ALL sizes
--   * product_settings,
--     size_prices           : using (is_owner())      -> any owner reads ANY ws
--   * sales_order_payments,
--     account_transfers,
--     sales_order_reminders,
--     owner_devices         : using (is_owner())      -> any owner reads ANY ws
--   * stock_movements,
--     sales_order_items,
--     purchase_order_items,
--     inventory_item_images,
--     sales_dispatches      : using (has_app_access()) -> any member reads ANY ws
--
-- This migration:
--   1. Adds a BEFORE INSERT trigger that auto-fills workspace_id from the
--      caller's profile when NULL, so the app needs NO changes and scoped
--      insert checks always pass.
--   2. Rewrites every leaking policy to be workspace-scoped, preserving the
--      existing role semantics (member-readable vs owner-only).
--
-- Role model preserved:
--   * Operational/config tables : read by any workspace MEMBER, written by OWNER
--                                 (or member where members already wrote).
--   * Financial tables          : OWNER-only, within the workspace.
-- ============================================================

-- 1. Shared auto-populate trigger function -----------------------------------
create or replace function public.set_workspace_id_from_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.workspace_id is null then
    new.workspace_id := public.get_my_workspace_id();
  end if;
  return new;
end;
$$;

-- Attach the auto-populate trigger to every table we are about to scope.
do $$
declare
  t text;
begin
  foreach t in array array[
    'product_settings', 'product_sizes', 'size_prices',
    'stock_movements', 'sales_order_items', 'purchase_order_items',
    'inventory_item_images', 'sales_dispatches',
    'sales_order_payments', 'account_transfers',
    'sales_order_reminders', 'owner_devices'
  ]
  loop
    execute format(
      'drop trigger if exists set_workspace_id on public.%I', t);
    execute format(
      'create trigger set_workspace_id before insert on public.%I '
      'for each row execute function public.set_workspace_id_from_profile()', t);
  end loop;
end $$;

-- Helper expressions used below:
--   member : workspace_id = public.get_my_workspace_id()
--   owner  : workspace_id = public.get_my_workspace_id() and public.is_owner()

-- 2. CONFIG / OPERATIONAL TABLES (member read, owner manage) -----------------

-- product_settings
drop policy if exists "product_settings_owner_only" on public.product_settings;
create policy "product_settings_ws_read" on public.product_settings
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "product_settings_ws_manage" on public.product_settings
  for all to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner())
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- product_sizes
drop policy if exists "product_sizes_select_all" on public.product_sizes;
drop policy if exists "product_sizes_owner_manage" on public.product_sizes;
create policy "product_sizes_ws_read" on public.product_sizes
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "product_sizes_ws_manage" on public.product_sizes
  for all to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner())
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- size_prices
drop policy if exists "size_prices_owner_only" on public.size_prices;
create policy "size_prices_ws_read" on public.size_prices
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "size_prices_ws_manage" on public.size_prices
  for all to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner())
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- stock_movements (members record stock as they sell/receive)
drop policy if exists "stock_movements_select" on public.stock_movements;
drop policy if exists "stock_movements_insert" on public.stock_movements;
drop policy if exists "stock_movements_update" on public.stock_movements;
create policy "stock_movements_ws_select" on public.stock_movements
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "stock_movements_ws_insert" on public.stock_movements
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and created_by = auth.uid());
create policy "stock_movements_ws_update" on public.stock_movements
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());

-- sales_order_items
drop policy if exists "sales_order_items_select" on public.sales_order_items;
drop policy if exists "sales_order_items_insert" on public.sales_order_items;
drop policy if exists "sales_order_items_update" on public.sales_order_items;
create policy "sales_order_items_ws_select" on public.sales_order_items
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "sales_order_items_ws_insert" on public.sales_order_items
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "sales_order_items_ws_update" on public.sales_order_items
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());

-- purchase_order_items
drop policy if exists "purchase_order_items_select" on public.purchase_order_items;
drop policy if exists "purchase_order_items_insert" on public.purchase_order_items;
drop policy if exists "purchase_order_items_update" on public.purchase_order_items;
create policy "purchase_order_items_ws_select" on public.purchase_order_items
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "purchase_order_items_ws_insert" on public.purchase_order_items
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "purchase_order_items_ws_update" on public.purchase_order_items
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());

-- inventory_item_images
drop policy if exists "inventory_item_images_select" on public.inventory_item_images;
drop policy if exists "inventory_item_images_insert" on public.inventory_item_images;
drop policy if exists "inventory_item_images_update" on public.inventory_item_images;
create policy "inventory_item_images_ws_select" on public.inventory_item_images
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "inventory_item_images_ws_insert" on public.inventory_item_images
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "inventory_item_images_ws_update" on public.inventory_item_images
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());

-- sales_dispatches
drop policy if exists "sales_dispatches_shared_select" on public.sales_dispatches;
drop policy if exists "sales_dispatches_shared_insert" on public.sales_dispatches;
drop policy if exists "sales_dispatches_shared_update" on public.sales_dispatches;
create policy "sales_dispatches_ws_select" on public.sales_dispatches
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id());
create policy "sales_dispatches_ws_insert" on public.sales_dispatches
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());
create policy "sales_dispatches_ws_update" on public.sales_dispatches
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id())
  with check (workspace_id = public.get_my_workspace_id());

-- 3. FINANCIAL TABLES (owner-only, within the workspace) ---------------------

-- sales_order_payments
drop policy if exists "sales_order_payments_owner_select" on public.sales_order_payments;
drop policy if exists "sales_order_payments_owner_insert" on public.sales_order_payments;
drop policy if exists "sales_order_payments_owner_update" on public.sales_order_payments;
create policy "sales_order_payments_ws_select" on public.sales_order_payments
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "sales_order_payments_ws_insert" on public.sales_order_payments
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner()
              and created_by = auth.uid());
create policy "sales_order_payments_ws_update" on public.sales_order_payments
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner())
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- account_transfers
drop policy if exists "account_transfers_owner_select" on public.account_transfers;
drop policy if exists "account_transfers_owner_insert" on public.account_transfers;
create policy "account_transfers_ws_select" on public.account_transfers
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "account_transfers_ws_insert" on public.account_transfers
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner()
              and created_by = auth.uid());

-- sales_order_reminders
drop policy if exists "sales_order_reminders_owner_select" on public.sales_order_reminders;
drop policy if exists "sales_order_reminders_owner_insert" on public.sales_order_reminders;
create policy "sales_order_reminders_ws_select" on public.sales_order_reminders
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "sales_order_reminders_ws_insert" on public.sales_order_reminders
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- owner_devices
drop policy if exists "owner_devices_owner_select" on public.owner_devices;
drop policy if exists "owner_devices_owner_insert" on public.owner_devices;
drop policy if exists "owner_devices_owner_update" on public.owner_devices;
create policy "owner_devices_ws_select" on public.owner_devices
  for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "owner_devices_ws_insert" on public.owner_devices
  for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());
create policy "owner_devices_ws_update" on public.owner_devices
  for update to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner())
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

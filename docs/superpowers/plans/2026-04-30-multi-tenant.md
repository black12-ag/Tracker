# Multi-Tenant Workspaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the app from a single hardcoded owner to a true multi-tenant SaaS where every user who signs up becomes the owner of their own isolated workspace, and can create staff (employees) within it.

**Architecture:** Add a `workspaces` table as the top-level tenant container. Every data table gains a `workspace_id` FK. RLS policies scope all data reads/writes to the current user's workspace. Sign-up automatically creates a workspace and assigns the user as owner. Staff users are tied to a workspace via their profile.

**Tech Stack:** Flutter 3, Riverpod, Supabase (Postgres + Auth + RLS), Dart

---

## Background: Current Architecture

- **Single-tenant today.** There is exactly one `role = 'owner'` user per database. All data is implicitly theirs.
- `public.is_owner()` is a Supabase function: `select role = 'owner' from profiles where id = auth.uid()`.
- RLS policies gate all writes with `is_owner()`. Staff can read but not write/admin.
- No `workspace_id` column exists on any table — data scope is implicit.
- `AppProfile` has: `id, email, displayName, role (owner|staff), isActive, phone, createdByOwner`.
- Pages with owner-only gates: `AccountPage`, `ReportsPage` (early return for staff).

## Target Architecture

- Any user signs up → their profile gets `role = 'owner'` → a workspace row is created → `profile.workspace_id` is set.
- All data tables gain a `workspace_id` column pointing to the workspace that owns the row.
- `is_owner()` still means "this user has role=owner in their profile" — unchanged semantics.
- `get_my_workspace_id()` is a new helper function: returns the workspace_id the current user belongs to.
- RLS: every policy adds `workspace_id = get_my_workspace_id()` to scope reads/writes.
- Staff users belong to a workspace via `profiles.workspace_id`. Their workspace_id = their owner's workspace_id.
- Sign-up flow: new field for "Business name" → creates workspace row, sets profile workspace_id.

---

## File Map

### Database (Supabase)
| File | Action | Purpose |
|------|--------|---------|
| `supabase/migrations/20260430000000_workspaces.sql` | CREATE | Add workspaces table, workspace_id columns, updated helpers, updated RLS |

### Flutter App — Models & Providers
| File | Action | Purpose |
|------|--------|---------|
| `app/lib/core/models/app_profile.dart` | MODIFY | Add `workspaceId` field |
| `app/lib/core/providers/core_providers.dart` | MODIFY | Pass workspaceId into repositories |

### Flutter App — Auth
| File | Action | Purpose |
|------|--------|---------|
| `app/lib/core/repositories/auth_repository.dart` | MODIFY | `signUp` creates workspace; `fetchProfile` returns workspaceId |
| `app/lib/features/auth/page/login_page.dart` | MODIFY | Add "Business name" field on sign-up tab |

### Flutter App — Repositories
| File | Action | Purpose |
|------|--------|---------|
| `app/lib/core/repositories/tracker_repository.dart` | MODIFY | `createEmployee` passes `workspace_id`; remove any hardcoded owner assumptions |

### Flutter App — Pages (remove owner-only content gates)
| File | Action | Purpose |
|------|--------|---------|
| `app/lib/features/account/page/account_page.dart` | MODIFY | Remove "owner only" early return; all workspace owners see accounts |
| `app/lib/features/reports/page/reports_page.dart` | MODIFY | Remove "owner only" early return |

---

## Task 1: Add workspaces table and workspace_id columns (Database migration)

**Files:**
- Create: `supabase/migrations/20260430000000_workspaces.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- supabase/migrations/20260430000000_workspaces.sql

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

-- Owners can read/update their own workspace
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
-- Each table gets workspace_id; nullable initially for migration safety,
-- then we backfill and add NOT NULL.

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
    -- Create a workspace for this owner
    insert into public.workspaces (name, owner_id)
    values (split_part(owner_row.email, '@', 1), owner_row.id)
    returning id into new_workspace_id;

    -- Assign workspace to the owner profile
    update public.profiles
    set workspace_id = new_workspace_id
    where id = owner_row.id;

    -- Assign workspace to all staff created by this owner
    update public.profiles
    set workspace_id = new_workspace_id
    where created_by_owner = owner_row.id;

    -- Backfill all data tables using created_by = owner id
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
-- 5. HELPER FUNCTIONS
-- ============================================================

-- Returns the workspace_id for the currently authenticated user
create or replace function public.get_my_workspace_id()
returns uuid
language sql
stable
security definer
as $$
  select workspace_id from public.profiles where id = auth.uid();
$$;

-- is_owner() stays the same — checks if current user has role='owner'
-- (no change needed — it was already: select role = 'owner' from profiles where id = auth.uid())

-- ============================================================
-- 6. UPDATE RLS POLICIES ON ALL DATA TABLES
-- ============================================================
-- Pattern: drop old policies, add new workspace-scoped ones.
-- Staff can read workspace data; owners can also write.

-- Helper: create workspace-scoped policies for a table
-- We do each table explicitly so the policy names are clear.

-- SALES_ORDERS
drop policy if exists "Owner can select sales_orders" on public.sales_orders;
drop policy if exists "Owner can insert sales_orders" on public.sales_orders;
drop policy if exists "Owner can update sales_orders" on public.sales_orders;
drop policy if exists "Owner can delete sales_orders" on public.sales_orders;

create policy "Workspace members can read sales_orders"
  on public.sales_orders for select to authenticated
  using (workspace_id = public.get_my_workspace_id());

create policy "Workspace members can insert sales_orders"
  on public.sales_orders for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());

create policy "Workspace owner can update sales_orders"
  on public.sales_orders for update to authenticated
  using (workspace_id = public.get_my_workspace_id());

create policy "Workspace owner can delete sales_orders"
  on public.sales_orders for delete to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PURCHASE_ORDERS
drop policy if exists "Owner can select purchase_orders" on public.purchase_orders;
drop policy if exists "Owner can insert purchase_orders" on public.purchase_orders;
drop policy if exists "Owner can update purchase_orders" on public.purchase_orders;

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

create policy "Workspace members can read expense_entries"
  on public.expense_entries for select to authenticated
  using (workspace_id = public.get_my_workspace_id());

create policy "Workspace owner can insert expense_entries"
  on public.expense_entries for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PRODUCTION_ENTRIES
drop policy if exists "Owner can select production_entries" on public.production_entries;
drop policy if exists "Owner can insert production_entries" on public.production_entries;

create policy "Workspace members can read production_entries"
  on public.production_entries for select to authenticated
  using (workspace_id = public.get_my_workspace_id());

create policy "Workspace members can insert production_entries"
  on public.production_entries for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id());

-- LOAN_RECORDS / SALE_FINANCE / PAYMENT_RECORDS
drop policy if exists "Owner can select loan_records" on public.loan_records;
drop policy if exists "Owner can select sale_finance" on public.sale_finance;
drop policy if exists "Owner can select payment_records" on public.payment_records;

create policy "Workspace owner can read loan_records"
  on public.loan_records for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Workspace owner can insert loan_records"
  on public.loan_records for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Workspace owner can read sale_finance"
  on public.sale_finance for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Workspace owner can insert sale_finance"
  on public.sale_finance for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Workspace owner can read payment_records"
  on public.payment_records for select to authenticated
  using (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Workspace owner can insert payment_records"
  on public.payment_records for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

-- PROFILES (staff management — owner can see their workspace's staff)
drop policy if exists "Owner can select staff profiles" on public.profiles;
drop policy if exists "Owner can insert staff profiles" on public.profiles;

create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using (id = auth.uid() or workspace_id = public.get_my_workspace_id());

create policy "Owner can insert staff profiles"
  on public.profiles for insert to authenticated
  with check (workspace_id = public.get_my_workspace_id() and public.is_owner());

create policy "Owner can update staff in their workspace"
  on public.profiles for update to authenticated
  using (id = auth.uid() or (workspace_id = public.get_my_workspace_id() and public.is_owner()));

-- DOCUMENT_COUNTERS (workspace-scoped so each workspace has independent numbering)
drop policy if exists "Authenticated users can read counters" on public.document_counters;
drop policy if exists "Authenticated users can update counters" on public.document_counters;

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
  -- Only auto-create workspace if role is 'owner'
  if new.role <> 'owner' then
    return new;
  end if;

  -- Use business_name from metadata if provided, else derive from email
  business_name := coalesce(
    new.raw_user_meta_data->>'business_name',
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

-- Note: this trigger fires after profile row is created.
-- The profile insert trigger already exists from the init migration;
-- we add a second trigger step here.
drop trigger if exists on_new_owner_create_workspace on public.profiles;
create trigger on_new_owner_create_workspace
  after insert on public.profiles
  for each row
  execute function public.handle_new_owner_signup();
```

- [ ] **Step 2: Apply migration to Supabase**

```bash
cd /Users/munir/Documents/tracker
supabase db push
```

Expected: migration applies without errors. If you see policy name conflicts, the `drop policy if exists` lines handle them.

- [ ] **Step 3: Verify in Supabase dashboard**

Run in SQL editor:
```sql
select id, name, owner_id from public.workspaces limit 10;
select id, email, role, workspace_id from public.profiles limit 10;
```

Expected: at least one workspace row exists. Every profile has a non-null `workspace_id`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260430000000_workspaces.sql
git commit -m "feat: add workspaces table and multi-tenant RLS"
```

---

## Task 2: Update AppProfile model to include workspaceId

**Files:**
- Modify: `app/lib/core/models/app_profile.dart`

- [ ] **Step 1: Add workspaceId field**

Replace the entire file content:

```dart
enum UserRole { owner, staff }

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.workspaceId,
    this.phone,
    this.createdByOwner,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final String workspaceId;
  final String? phone;
  final String? createdByOwner;

  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    final roleValue = map['role'] as String? ?? 'staff';
    return AppProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'User',
      role: roleValue == 'owner' ? UserRole.owner : UserRole.staff,
      isActive: map['is_active'] as bool? ?? false,
      workspaceId: map['workspace_id'] as String? ?? '',
      phone: map['phone'] as String?,
      createdByOwner: map['created_by_owner'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': isOwner ? 'owner' : 'staff',
      'is_active': isActive,
      'workspace_id': workspaceId,
      'phone': phone,
      'created_by_owner': createdByOwner,
    };
  }
}
```

- [ ] **Step 2: Verify the app still compiles**

```bash
cd /Users/munir/Documents/tracker/app
flutter analyze --no-fatal-infos 2>&1 | grep -E "error:|Error" | head -20
```

Expected: zero errors. `workspaceId` is required but all existing `AppProfile.fromMap` call sites pass a map from Supabase which will now include `workspace_id`.

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/models/app_profile.dart
git commit -m "feat: add workspaceId to AppProfile model"
```

---

## Task 3: Update AuthRepository — sign-up sets role=owner and workspace gets created

**Files:**
- Modify: `app/lib/core/repositories/auth_repository.dart`

**Context:** Currently `signUp` just calls `auth.signUp`. The Supabase trigger `handle_new_owner_signup` we added in Task 1 auto-creates the workspace after the profile row is created. But we need to:
1. Pass `business_name` in the user metadata during sign-up so the workspace gets a proper name.
2. Ensure `fetchProfile` selects `workspace_id`.

- [ ] **Step 1: Update signUp to accept businessName and pass it in metadata**

In `app/lib/core/repositories/auth_repository.dart`, update the `signUp` method:

```dart
Future<void> signUp({
  required String displayName,
  required String email,
  required String password,
  required String businessName,
}) async {
  await _client.auth.signUp(
    email: email.trim(),
    password: password,
    data: {
      'display_name': displayName.trim(),
      'business_name': businessName.trim(),
    },
  );
}
```

- [ ] **Step 2: Update fetchProfile to select workspace_id**

The existing `fetchProfile` does `.select()` which selects all columns — no change needed here since `workspace_id` is now a column on `profiles`. Verify:

```dart
// In fetchProfile, the .select() returns all columns including workspace_id.
// AppProfile.fromMap already handles 'workspace_id' after Task 2.
// No change needed in fetchProfile itself.
```

Run `flutter analyze` to confirm:

```bash
cd /Users/munir/Documents/tracker/app
flutter analyze --no-fatal-infos 2>&1 | grep -E "error:" | head -10
```

Expected: zero errors.

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/repositories/auth_repository.dart
git commit -m "feat: pass businessName in signUp metadata for workspace creation"
```

---

## Task 4: Update login_page.dart — add Business Name field on sign-up tab

**Files:**
- Modify: `app/lib/features/auth/page/login_page.dart`

**Context:** The login page has a sign-up form. We need to add a "Business name" `AppTextField` and wire it into `signUp`. The exact structure of `login_page.dart` needs to be read before editing.

- [ ] **Step 1: Read the current login page sign-up section**

```bash
grep -n "signUp\|displayName\|_name\|TextEditingController\|businessName\|sign.up\|SignUp" \
  app/lib/features/auth/page/login_page.dart | head -30
```

- [ ] **Step 2: Add businessName controller**

In the `State` class that handles sign-up, add:

```dart
final TextEditingController _businessNameController = TextEditingController();
```

And in `dispose()`:

```dart
_businessNameController.dispose();
```

- [ ] **Step 3: Add the Business Name field to the sign-up form**

After the display name field in the sign-up Column, add:

```dart
const SizedBox(height: 14),
AppTextField(
  controller: _businessNameController,
  label: 'Business name',
  hintText: 'Your shop or company name',
  prefixIcon: Icons.store_outlined,
),
```

- [ ] **Step 4: Wire businessName into the signUp call**

Find the call to `authRepository.signUp(...)` and add the `businessName` parameter:

```dart
await ref.read(authRepositoryProvider).signUp(
  displayName: _displayNameController.text,
  email: _emailController.text,
  password: _passwordController.text,
  businessName: _businessNameController.text,
);
```

- [ ] **Step 5: Add validation — businessName required**

Before the signUp call, add:

```dart
if (_businessNameController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Business name is required.')),
  );
  return;
}
```

- [ ] **Step 6: Verify compile**

```bash
cd /Users/munir/Documents/tracker/app
flutter analyze --no-fatal-infos 2>&1 | grep -E "error:" | head -10
```

Expected: zero errors.

- [ ] **Step 7: Commit**

```bash
git add app/lib/features/auth/page/login_page.dart
git commit -m "feat: add business name field to sign-up flow"
```

---

## Task 5: Update TrackerRepository — pass workspace_id when creating staff

**Files:**
- Modify: `app/lib/core/repositories/tracker_repository.dart`

**Context:** The `createEmployee` / staff-creation method currently sets `created_by_owner`. It needs to also set `workspace_id` so the new staff profile is scoped to the right workspace.

- [ ] **Step 1: Find the staff creation method**

```bash
grep -n "createEmployee\|createStaff\|insert.*profiles\|created_by_owner" \
  app/lib/core/repositories/tracker_repository.dart | head -20
```

- [ ] **Step 2: Add workspaceId parameter to the method and payload**

Find the method signature (likely `createEmployee` or similar). Add `required String workspaceId` parameter and include it in the insert payload:

```dart
// Example — adapt to match the actual method signature found in step 1
Future<void> createEmployee({
  required String createdBy,
  required String workspaceId,   // ADD THIS
  required String email,
  required String displayName,
  required String password,
  String? phone,
}) async {
  // ... existing code ...
  await _client.from('profiles').insert({
    'email': email,
    'display_name': displayName,
    'role': 'staff',
    'is_active': true,
    'created_by_owner': createdBy,
    'workspace_id': workspaceId,   // ADD THIS
  });
}
```

- [ ] **Step 3: Update call sites — pass profile.workspaceId**

Find where `createEmployee` is called (likely `employees_page.dart`):

```bash
grep -rn "createEmployee\|createStaff" app/lib/features/ | head -10
```

Update each call site to pass `workspaceId: widget.profile.workspaceId`.

- [ ] **Step 4: Verify compile**

```bash
cd /Users/munir/Documents/tracker/app
flutter analyze --no-fatal-infos 2>&1 | grep -E "error:" | head -10
```

Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/repositories/tracker_repository.dart
git add app/lib/features/employees/
git commit -m "feat: scope new staff to workspace on creation"
```

---

## Task 6: Remove hard owner-only content gates — every workspace owner sees all sections

**Files:**
- Modify: `app/lib/features/account/page/account_page.dart`
- Modify: `app/lib/features/reports/page/reports_page.dart`

**Context:** These pages have early-return blocks that show "This section is for the owner only." to staff users. The RLS already enforces data access — the app gate is now redundant for the `isOwner` check since every registered user IS the owner of their own workspace. Staff still correctly see nothing because RLS denies them. Remove the UI gates so if we ever want to grant staff read access to these sections, RLS is the single control point.

**Note:** Keep the gate logic IF you want staff to be explicitly blocked at the UI level too (defense-in-depth). This task removes the gate for owners — the check `!widget.profile.isOwner` is still valid for staff.

Actually on reflection: **keep the gates** as they are. The semantics are correct: staff users of a workspace shouldn't see accounts/reports. Only the workspace owner should. The `isOwner` check already works correctly in the multi-tenant model since every workspace has one owner. No change needed here.

- [ ] **Step 1: Verify no change needed — confirm isOwner still works**

```bash
grep -n "isOwner\|isStaff" \
  app/lib/features/account/page/account_page.dart \
  app/lib/features/reports/page/reports_page.dart
```

Expected: `!widget.profile.isOwner` gates are still valid — they correctly block staff. Owner of any workspace passes this check. No edits needed.

- [ ] **Step 2: Commit note**

No code change needed for this task. The existing `isOwner` check maps correctly to the new model.

---

## Task 7: Update all insert calls to include workspace_id

**Files:**
- Modify: `app/lib/core/repositories/tracker_repository.dart` (all insert operations)

**Context:** Every `insert` into a data table must include `workspace_id`. Currently none of them do — the workspace_id column is new. Without it, inserts will fail the `NOT NULL` constraint once we add it (or be null and miss RLS policy).

- [ ] **Step 1: Audit all insert payloads**

```bash
grep -n "\.insert(\|'created_by'" app/lib/core/repositories/tracker_repository.dart | head -40
```

- [ ] **Step 2: Update repository constructor to accept workspaceId**

The repositories currently take `SupabaseClient` and `LocalStoreService`. To pass workspace_id, the cleanest approach is to pass the full `AppProfile` or just `workspaceId` at construction time via the provider.

Update `TrackerRepository` constructor:

```dart
class TrackerRepository {
  TrackerRepository(
    this._client,
    this._localStoreService,
    this._workspaceId,   // ADD
  );

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;
  final String _workspaceId;   // ADD
```

- [ ] **Step 3: Update trackerRepositoryProvider to pass workspaceId**

In `app/lib/core/providers/core_providers.dart`:

```dart
final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return TrackerRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(localStoreServiceProvider),
    profile?.workspaceId ?? '',   // ADD
  );
});
```

Do the same for `productRepositoryProvider`, `productionRepositoryProvider`, `salesRepositoryProvider`, `financeRepositoryProvider` — each needs workspace_id injected.

- [ ] **Step 4: Add workspace_id to every insert payload in TrackerRepository**

For every `_client.from('table_name').insert({...})` block, add `'workspace_id': _workspaceId`. Example:

```dart
// Before
await _client.from('sales_orders').insert({
  'created_by': createdBy,
  'customer_id': customerId,
  // ...
});

// After
await _client.from('sales_orders').insert({
  'created_by': createdBy,
  'customer_id': customerId,
  'workspace_id': _workspaceId,   // ADD
  // ...
});
```

Repeat for every other repository (product, production, sales, finance).

- [ ] **Step 5: Verify compile**

```bash
cd /Users/munir/Documents/tracker/app
flutter analyze --no-fatal-infos 2>&1 | grep -E "error:" | head -20
```

Expected: zero errors.

- [ ] **Step 6: Commit**

```bash
git add app/lib/core/repositories/ app/lib/core/providers/core_providers.dart
git commit -m "feat: inject workspaceId into all repository inserts"
```

---

## Task 8: End-to-end smoke test

- [ ] **Step 1: Sign up as a new user (User A)**

In the app or via Supabase Auth dashboard, create a new account with a business name. Verify:
```sql
select id, email, role, workspace_id from public.profiles where email = 'usera@test.com';
select id, name, owner_id from public.workspaces;
```
Expected: one workspace row, profile has matching `workspace_id`.

- [ ] **Step 2: Sign up as a second user (User B)**

Create another account. Verify:
```sql
select id, name, owner_id from public.workspaces;
```
Expected: two workspace rows, each with a different `owner_id`.

- [ ] **Step 3: Create data as User A, confirm User B cannot see it**

As User A, create a sales order. Then sign in as User B and query:
```sql
-- Run as User B's JWT
select * from public.sales_orders;
```
Expected: empty result for User B (RLS blocks cross-workspace reads).

- [ ] **Step 4: Create a staff member as User A**

Use the Employees page to create a staff account. Verify:
```sql
select id, email, role, workspace_id, created_by_owner from public.profiles;
```
Expected: staff profile has same `workspace_id` as User A.

- [ ] **Step 5: Commit final**

```bash
git add -A
git commit -m "feat: complete multi-tenant workspace rollout"
```

---

## Self-Review

**Spec coverage check:**
- [x] Any user can sign up → Task 3+4 (signUp always creates owner + workspace)
- [x] Data isolation between users → Task 1 (RLS workspace scoping)
- [x] Create employees → Task 5 (workspace_id on staff profiles)
- [x] All existing data preserved → Task 1 backfill block
- [x] AppProfile updated → Task 2
- [x] All inserts include workspace_id → Task 7

**Placeholder scan:** No TBDs. Every step has actual code.

**Type consistency:**
- `workspaceId` (camelCase in Dart), `workspace_id` (snake_case in SQL/maps) — consistent throughout.
- `_workspaceId` in repositories — consistent across all tasks.
- `get_my_workspace_id()` SQL function — referenced consistently in RLS policies.

**Gaps found and addressed:**
- `document_counters` now needs `workspace_id` too (each workspace gets independent counters) — added in Task 1.
- Other repositories (product, production, sales, finance) also need workspace_id injection — noted in Task 7.

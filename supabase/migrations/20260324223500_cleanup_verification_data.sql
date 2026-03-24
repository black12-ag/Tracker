delete from public.activity_logs
where actor_id in (
  select id
  from public.profiles
  where email like 'verify-%@example.com'
)
or message like '%verify-%';

delete from public.payment_records
where sale_finance_id in (
  select sf.id
  from public.sale_finance sf
  join public.sales_dispatches sd on sd.id = sf.dispatch_id
  join public.profiles p on p.id = sd.created_by
  where p.email like 'verify-%@example.com'
);

delete from public.sale_finance
where dispatch_id in (
  select sd.id
  from public.sales_dispatches sd
  join public.profiles p on p.id = sd.created_by
  where p.email like 'verify-%@example.com'
);

delete from public.expense_entries
where created_by in (
  select id
  from public.profiles
  where email like 'verify-%@example.com'
);

delete from public.sales_dispatches
where created_by in (
  select id
  from public.profiles
  where email like 'verify-%@example.com'
);

delete from public.production_entries
where created_by in (
  select id
  from public.profiles
  where email like 'verify-%@example.com'
);

delete from public.customers c
where c.name like 'Verify Customer verify-%'
and not exists (
  select 1
  from public.sales_dispatches sd
  where sd.customer_id = c.id
);

update auth.users
set
  email = concat('archived-', replace(id::text, '-', ''), '@disabled.local'),
  raw_user_meta_data = jsonb_set(
    coalesce(raw_user_meta_data, '{}'::jsonb),
    '{display_name}',
    to_jsonb('Archived user'::text),
    true
  )
where email like 'verify-%@example.com';

update public.profiles
set
  email = concat('archived-', replace(id::text, '-', ''), '@disabled.local'),
  role = 'operator',
  is_active = false,
  display_name = 'Archived user'
where email like 'verify-%@example.com';

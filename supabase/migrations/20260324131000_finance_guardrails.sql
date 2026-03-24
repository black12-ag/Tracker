create or replace function public.normalize_sale_finance()
returns trigger
language plpgsql
as $$
begin
  if new.paid_amount > new.total_amount then
    raise exception 'paid amount cannot exceed total amount'
      using errcode = '23514';
  end if;

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

create or replace function public.sync_sale_finance_totals()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_finance_id uuid;
  total_paid numeric(12, 2);
  finance_total numeric(12, 2);
begin
  target_finance_id := coalesce(new.sale_finance_id, old.sale_finance_id);

  select coalesce(sum(amount), 0)
  into total_paid
  from public.payment_records
  where sale_finance_id = target_finance_id;

  select total_amount
  into finance_total
  from public.sale_finance
  where id = target_finance_id;

  if finance_total is not null and total_paid > finance_total then
    raise exception 'payment total cannot exceed sale total'
      using errcode = '23514';
  end if;

  update public.sale_finance
  set paid_amount = total_paid
  where id = target_finance_id;

  return coalesce(new, old);
end;
$$;

insert into public.size_prices (size_id, unit_price)
select s.id, 0
from public.product_sizes s
on conflict (size_id) do nothing;

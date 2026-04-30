-- ============================================================
-- 1. Rate limits table: one row per (user_id, action, minute_bucket)
-- ============================================================
create table if not exists public.rate_limits (
  id         bigserial primary key,
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  action     text        not null,
  bucket     timestamptz not null,
  hit_count  int         not null default 1,
  created_at timestamptz not null default now(),
  constraint rate_limits_user_action_bucket_key unique (user_id, action, bucket)
);

alter table public.rate_limits enable row level security;
-- No client policies: deny all direct client access

create index if not exists rate_limits_bucket_idx on public.rate_limits (bucket);

-- ============================================================
-- 2. check_rate_limit function
--    Raises P0001 if user exceeded max_per_minute for the action.
--    Prunes rows older than 10 minutes.
-- ============================================================
create or replace function public.check_rate_limit(
  p_user_id     uuid,
  p_action      text,
  p_max_per_min int default 10
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bucket timestamptz := date_trunc('minute', now() at time zone 'utc');
  v_count  int;
begin
  insert into public.rate_limits (user_id, action, bucket, hit_count)
  values (p_user_id, p_action, v_bucket, 1)
  on conflict (user_id, action, bucket)
  do update set hit_count = rate_limits.hit_count + 1
  returning hit_count into v_count;

  if v_count > p_max_per_min then
    raise exception 'rate_limit_exceeded: too many % requests (% per minute allowed)',
      p_action, p_max_per_min
      using errcode = 'P0001';
  end if;

  -- Prune old buckets
  delete from public.rate_limits
  where bucket < now() - interval '10 minutes';
end;
$$;

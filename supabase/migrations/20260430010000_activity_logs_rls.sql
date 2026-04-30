-- Drop the old too-broad select policy (may not exist — use IF EXISTS)
drop policy if exists "activity_logs_shared_select" on public.activity_logs;
drop policy if exists "Authenticated users can read activity_logs" on public.activity_logs;
drop policy if exists "Owner can read activity_logs" on public.activity_logs;

-- Owner-only workspace-scoped read
create policy "Workspace owner can read activity_logs"
  on public.activity_logs for select
  to authenticated
  using (
    workspace_id = public.get_my_workspace_id()
    and public.is_owner()
  );

-- Fix write_activity_log to stamp workspace_id from the actor's profile
create or replace function public.write_activity_log(
  log_event_type text,
  log_message    text,
  log_actor_id   uuid,
  log_metadata   jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.activity_logs (event_type, message, actor_id, metadata, workspace_id)
  values (
    log_event_type,
    log_message,
    log_actor_id,
    coalesce(log_metadata, '{}'::jsonb),
    (select workspace_id from public.profiles where id = log_actor_id)
  );
$$;

-- Composite index for paginated owner query
create index if not exists activity_logs_workspace_created_at_idx
  on public.activity_logs (workspace_id, created_at desc);

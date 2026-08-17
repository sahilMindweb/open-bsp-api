-- Platform admin via a dedicated flag in agents.extra (not the role column).
-- Keeping this separate from the role system avoids breaking existing
-- owner/admin/member RLS which uses lowercase roles.

create or replace function public.is_platform_admin()
returns boolean
language sql
security definer
set search_path to ''
as $$
  select exists (
    select 1
    from public.agents
    where user_id = auth.uid()
      and ai = false
      and extra->>'is_platform_admin' = 'true'
  );
$$;

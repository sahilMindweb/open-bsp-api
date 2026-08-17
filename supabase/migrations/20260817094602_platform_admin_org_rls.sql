-- Allow platform admins to view all organizations.
-- Idempotent: drop the policy first so this migration can be re-applied safely
-- (e.g. by the GitHub Action after a manual apply).
drop policy if exists "platform admins can read all organizations"
on public.organizations;

create policy "platform admins can read all organizations"
on public.organizations
for select
to authenticated, anon
using (
  public.is_platform_admin()
);

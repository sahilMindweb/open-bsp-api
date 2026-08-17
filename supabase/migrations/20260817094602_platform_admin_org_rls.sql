-- Allow platform admins to view all organizations
create policy "platform admins can read all organizations"
on public.organizations
for select
to authenticated, anon
using (
  public.is_platform_admin()
);

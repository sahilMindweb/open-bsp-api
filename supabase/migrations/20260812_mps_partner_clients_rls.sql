-- MPS: let a parent (reseller) read its sub-tenants (read-only clients list)
-- 1. RLS policy: a user can SELECT orgs whose partner_id is one of their own orgs
-- 2. Helper function: get_partner_clients() -> the parent's sub-tenants + connection status

-- Allow members of the parent org to read sub-tenant orgs (read-only).
drop policy if exists "parent org members can read sub-tenants" on public.organizations;
create policy "parent org members can read sub-tenants"
on public.organizations
for select
to authenticated, anon
using (
  partner_id in (
    select public.get_authorized_orgs('member')
  )
);

-- Helper: returns the caller's sub-tenants with their WhatsApp connection status.
-- Only returns orgs whose partner_id is one of the caller's orgs (RLS on the
-- function body via the same get_authorized_orgs check).
create or replace function public.get_partner_clients()
returns table (
  id uuid,
  name text,
  created_at timestamptz,
  waba_id text,
  phone_number_id text,
  status text
)
language sql
security definer
set search_path to ''
as $$
  select
    o.id,
    o.name,
    o.created_at,
    oa.extra ->> 'waba_id' as waba_id,
    oa.address as phone_number_id,
    oa.status
  from public.organizations o
  left join public.organizations_addresses oa
    on oa.organization_id = o.id
   and oa.service = 'whatsapp'
  where o.partner_id in (
    select public.get_authorized_orgs('member')
  )
  order by o.created_at desc;
$$;

-- Grant execute to the roles that need it (anon/authenticated call it via the UI).
grant execute on function public.get_partner_clients() to anon, authenticated, service_role;

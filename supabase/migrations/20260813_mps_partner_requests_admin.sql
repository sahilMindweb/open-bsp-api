-- MPS: partner onboarding requests + platform admin support
-- 1. partner_requests: prospective partners submit their Meta App ID and await
--    a solution ID. Admins review and issue the solution ID.
-- 2. is_platform_admin(): a user with role owner|admin in any org is a platform
--    admin (scoped admin panel: WhatsApp oversight + partner request review).
-- 3. RLS: partner can read/update own request; admins can read all + issue.

create table public.partner_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  app_id text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  solution_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index partner_requests_organization_id_idx
on public.partner_requests (organization_id);

create trigger set_updated_at
before update
on public.partner_requests
for each row
execute function public.moddatetime('updated_at');

-- Platform admin check: user has role owner or admin in any org.
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
      and (extra->>'role') in ('owner', 'admin')
  );
$$;

grant execute on function public.is_platform_admin() to anon, authenticated, service_role;

-- RLS
alter table public.partner_requests enable row level security;

-- Partner (org member) can read their own requests
create policy "members can read their org partner requests"
on public.partner_requests
for select
to authenticated, anon
using (
  organization_id in ( select public.get_authorized_orgs('member') )
);

-- Partner (owner/admin of the org) can create a request
create policy "owners can create partner requests"
on public.partner_requests
for insert
to authenticated, anon
with check (
  organization_id in ( select public.get_authorized_orgs('owner') )
);

-- Platform admins can read all requests
create policy "platform admins can read all partner requests"
on public.partner_requests
for select
to authenticated, anon
using (
  public.is_platform_admin()
);

-- Platform admins can update requests (approve/reject/issue solution id)
create policy "platform admins can update partner requests"
on public.partner_requests
for update
to authenticated, anon
using (
  public.is_platform_admin()
)
with check (
  public.is_platform_admin()
);

-- Admin oversight: WhatsApp accounts across all orgs (for the admin panel).
create or replace function public.admin_whatsapp_overview()
returns table (
  organization_id uuid,
  organization_name text,
  waba_id text,
  phone_number_id text,
  status text,
  partner_name text,
  created_at timestamptz
)
language sql
security definer
set search_path to ''
as $$
  select
    oa.organization_id,
    o.name as organization_name,
    oa.extra ->> 'waba_id' as waba_id,
    oa.address as phone_number_id,
    oa.status,
    p.name as partner_name,
    oa.created_at
  from public.organizations_addresses oa
  join public.organizations o on o.id = oa.organization_id
  left join public.organizations p on p.id = o.partner_id
  where oa.service = 'whatsapp'
  order by oa.created_at desc;
$$;

grant execute on function public.admin_whatsapp_overview() to anon, authenticated, service_role;

-- MPS: Multi-Partner Solutions support
-- 1. partner_solutions: maps a Meta Solution ID to the reseller organization
-- 2. organizations.partner_id: parent link from a client org to its reseller
--
-- Idempotent (IF NOT EXISTS): safe to run whether or not it was already
-- applied manually to a project.

create table if not exists public.partner_solutions (
  id uuid primary key default gen_random_uuid(),
  solution_id text not null unique,
  partner_organization_id uuid not null references public.organizations(id),
  created_at timestamptz not null default now()
);

alter table public.organizations
add column if not exists partner_id uuid references public.organizations(id);

-- When a partner request is approved with a solution_id, register it in
-- partner_solutions so the PARTNER_ADDED webhook can resolve the solution ID
-- back to the partner's organization.

create or replace function public.sync_partner_solution_on_approval() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.status = 'approved' and new.solution_id is not null then
    insert into public.partner_solutions (solution_id, partner_organization_id)
    values (trim(new.solution_id), new.organization_id)
    on conflict (solution_id) do update
      set partner_organization_id = excluded.partner_organization_id;
  end if;

  return new;
end;
$$;

create trigger sync_partner_solution_on_approval
after insert or update of status, solution_id
on public.partner_requests
for each row
when (new.status = 'approved')
execute function public.sync_partner_solution_on_approval();

-- Enforce that an approved partner request must have a solution_id.
-- Defense-in-depth: the admin UI now requires it too, but the DB must not
-- allow an approved request with an empty/blank solution ID.

-- Reject any update/insert where status='approved' and solution_id is blank.
create or replace function public.enforce_partner_request_solution_id() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.status = 'approved' and (
    new.solution_id is null
    or length(trim(new.solution_id)) = 0
  ) then
    raise exception 'Approved partner requests must include a solution_id';
  end if;

  -- Cleaner: a rejected request should not carry a solution_id.
  if new.status = 'rejected' and new.solution_id is not null then
    new.solution_id := null;
  end if;

  return new;
end;
$$;

create trigger enforce_partner_request_solution_id
before insert or update
on public.partner_requests
for each row
execute function public.enforce_partner_request_solution_id();

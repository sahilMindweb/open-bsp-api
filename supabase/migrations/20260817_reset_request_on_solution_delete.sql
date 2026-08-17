-- Revocation consistency: when a partner_solutions row is deleted, reset the
-- matching partner_requests back to pending so the tenant sees the
-- "become a partner" form again and the webhook no longer resolves the solution.

create or replace function public.reset_partner_request_on_solution_delete() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  update public.partner_requests
  set status = 'pending', solution_id = null
  where lower(trim(solution_id)) = lower(trim(old.solution_id));

  return old;
end;
$$;

create trigger reset_partner_request_on_solution_delete
after delete
on public.partner_solutions
for each row
execute function public.reset_partner_request_on_solution_delete();

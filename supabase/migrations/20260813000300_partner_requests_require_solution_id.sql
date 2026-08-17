-- Require non-null, non-empty solution_id when status is 'approved'
-- and reset status back to pending in database if approved without solution_id.

alter table public.partner_requests
drop constraint if exists partner_requests_approved_solution_id_check;

alter table public.partner_requests
add constraint partner_requests_approved_solution_id_check
check (
  status != 'approved' or (solution_id is not null and length(trim(solution_id)) > 0)
);

-- Fix any existing invalid approvals in database
update public.partner_requests
set status = 'pending', solution_id = null
where status = 'approved' and (solution_id is null or length(trim(solution_id)) = 0);

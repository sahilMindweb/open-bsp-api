-- Prevent duplicate App ID submissions: an App ID that already has a pending
-- or approved partner request must not be submitted again (pending = already
-- in the queue; approved = solution already issued). Rejected stays
-- resubmittable so the org can fix and retry.

create or replace function public.prevent_duplicate_app_id_on_partner_request() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if exists (
    select 1
    from public.partner_requests
    where lower(trim(app_id)) = lower(trim(new.app_id))
      and status in ('pending', 'approved')
  ) then
    raise exception 'The App ID % already has a pending or approved partner request', new.app_id;
  end if;

  return new;
end;
$$;

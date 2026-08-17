-- Prevent duplicate App ID submissions: an App ID that already has an
-- approved partner request must not be submitted again (it already maps to a
-- solution ID).

create or replace function public.prevent_duplicate_app_id_on_partner_request() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if exists (
    select 1
    from public.partner_requests
    where lower(trim(app_id)) = lower(trim(new.app_id))
      and status = 'approved'
  ) then
    raise exception 'The App ID % already has an approved partner request (solution ID already issued)', new.app_id;
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_duplicate_app_id_on_partner_request on public.partner_requests;

create trigger prevent_duplicate_app_id_on_partner_request
before insert
on public.partner_requests
for each row
execute function public.prevent_duplicate_app_id_on_partner_request();

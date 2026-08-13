-- agents.email: denormalized copy of auth.users.email for display convenience.
-- Source of truth stays auth.users; this is kept in sync via trigger + backfill.

alter table public.agents
add column if not exists email text;

-- Backfill existing agents from auth.users (via user_id) or invitation email.
update public.agents a
set email = coalesce(
  (select u.email from auth.users u where u.id = a.user_id),
  a.extra->'invitation'->>'email'
)
where a.email is null
  and a.ai = false;

-- Keep email in sync: when an agent gets a user_id (org creation insert, or
-- invitation acceptance update), populate email from auth.users if not set.
create or replace function public.set_agent_email_from_auth_user() returns trigger
language plpgsql
security definer
set search_path to ''
as $$
begin
  if new.user_id is not null and new.email is null then
    select email into new.email from auth.users where id = new.user_id;
  end if;
  return new;
end;
$$;

create trigger set_agent_email
before insert or update of user_id
on public.agents
for each row
when (new.ai = false)
execute function public.set_agent_email_from_auth_user();

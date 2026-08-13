-- Restrict platform admin to a specific operator email.
-- Overrides the earlier is_platform_admin() (owner|admin in any org), which
-- was too broad and granted the admin panel to everyone with a role.

create or replace function public.is_platform_admin()
returns boolean
language sql
security definer
set search_path to ''
as $$
  select exists (
    select 1
    from auth.users
    where id = auth.uid()
      and lower(email) = lower('sahil@mindwebtree.com')
  );
$$;

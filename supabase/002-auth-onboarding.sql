-- JDS Keyhold: auth onboarding trigger
-- Run AFTER schema.sql on a fresh development project.
-- This creates a profile for every user and a private workspace for landlord sign-ups.
-- Tenant accounts must be linked to a tenancy through a separately authorized invitation flow.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  full_name_value text;
  workspace_name_value text;
  new_org_id uuid;
begin
  full_name_value := nullif(trim(coalesce(new.raw_user_meta_data->>'full_name','')), '');
  workspace_name_value := nullif(trim(coalesce(new.raw_user_meta_data->>'workspace_name','')), '');

  insert into public.profiles (id, full_name)
  values (new.id, full_name_value)
  on conflict (id) do update set full_name = coalesce(excluded.full_name, public.profiles.full_name);

  if coalesce(new.raw_user_meta_data->>'account_type','landlord') = 'landlord' then
    if workspace_name_value is null then
      workspace_name_value := 'My Property Workspace';
    end if;
    insert into public.organizations (name, created_by)
    values (left(workspace_name_value,120), new.id)
    returning id into new_org_id;

    insert into public.organization_members (organization_id, user_id, role)
    values (new_org_id, new.id, 'owner')
    on conflict (organization_id,user_id) do nothing;
  end if;

  return new;
end;
$$;

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_jds_keyhold on auth.users;
create trigger on_auth_user_created_jds_keyhold
after insert on auth.users
for each row execute function public.handle_new_auth_user();

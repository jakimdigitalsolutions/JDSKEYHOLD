-- JDS Keyhold: SAFE one-time workspace repair for an EXISTING landlord account.
-- Run this in Supabase SQL Editor as project owner. It does not drop or truncate anything.
-- It keeps any existing membership and creates a workspace only if none exists.
do $$
declare
  target_user_id uuid;
  target_org_id uuid;
  target_name text;
begin
  select id, coalesce(nullif(raw_user_meta_data->>'full_name',''), split_part(email,'@',1))
    into target_user_id, target_name
  from auth.users
  where lower(email) = lower('kyeyunejakim@gmail.com')
  order by created_at asc
  limit 1;

  if target_user_id is null then
    raise exception 'No Supabase Auth user found for kyeyunejakim@gmail.com. Verify the account email before running this script.';
  end if;

  insert into public.profiles (id, full_name)
  values (target_user_id, target_name)
  on conflict (id) do update
    set full_name = coalesce(public.profiles.full_name, excluded.full_name);

  select organization_id into target_org_id
  from public.organization_members
  where user_id = target_user_id
  order by created_at asc
  limit 1;

  if target_org_id is null then
    select id into target_org_id
    from public.organizations
    where created_by = target_user_id
    order by created_at asc
    limit 1;

    if target_org_id is null then
      insert into public.organizations (name, created_by)
      values (left(coalesce(target_name, 'JDS Keyhold') || ' Property Workspace', 120), target_user_id)
      returning id into target_org_id;
    end if;

    insert into public.organization_members (organization_id, user_id, role)
    values (target_org_id, target_user_id, 'owner')
    on conflict (organization_id, user_id) do nothing;
  end if;

  raise notice 'Workspace repair complete. Existing data was preserved.';
end $$;

-- Verify the result:
select o.name as workspace_name, m.role, m.user_id, m.organization_id
from public.organization_members m
join public.organizations o on o.id = m.organization_id
join auth.users u on u.id = m.user_id
where lower(u.email) = lower('kyeyunejakim@gmail.com');

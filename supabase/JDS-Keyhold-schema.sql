-- JDS Keyhold initial schema for Supabase PostgreSQL.
-- Apply only to a fresh development project after reviewing this file.
-- All monetary values are integer UGX; do not use floating point for money.
create extension if not exists pgcrypto;

create type public.member_role as enum ('owner','admin','property_manager','caretaker','accountant');
create type public.lease_status as enum ('draft','active','ended','terminated');
create type public.invoice_status as enum ('draft','issued','partially_paid','paid','void');
create type public.payment_method as enum ('cash','mobile_money','bank_transfer','card','other');
create type public.payment_status as enum ('pending','confirmed','failed','reversed');
create type public.charge_kind as enum ('rent','water','electricity','garbage','wifi','service_charge','deposit','other');

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  currency_code char(3) not null default 'UGX',
  timezone text not null default 'Africa/Kampala',
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null default 'owner',
  created_at timestamptz not null default now(),
  primary key (organization_id,user_id)
);
create table public.properties (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  address_line text,
  area text,
  city text,
  property_type text not null default 'residential',
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,name)
);
create table public.units (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  unit_code text not null,
  display_name text,
  bedrooms smallint,
  bathrooms numeric(3,1),
  market_rent_ugx bigint not null default 0 check (market_rent_ugx >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(property_id,unit_code),
  unique(id,organization_id)
);
create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  auth_user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text,
  phone text,
  identity_reference text,
  emergency_contact jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(id,organization_id)
);
create index tenants_auth_user_id_idx on public.tenants(auth_user_id);
create table public.leases (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  unit_id uuid not null,
  tenant_id uuid not null,
  lease_reference text,
  start_date date not null,
  end_date date,
  rent_amount_ugx bigint not null check (rent_amount_ugx >= 0),
  rent_due_day smallint not null default 1 check (rent_due_day between 1 and 28),
  deposit_amount_ugx bigint not null default 0 check (deposit_amount_ugx >= 0),
  billing_frequency text not null default 'monthly' check (billing_frequency in ('weekly','monthly','quarterly','annually','custom')),
  status public.lease_status not null default 'draft',
  agreement_object_path text,
  terms jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key(unit_id,organization_id) references public.units(id,organization_id),
  foreign key(tenant_id,organization_id) references public.tenants(id,organization_id)
);
create index leases_tenant_idx on public.leases(tenant_id,status);
create index leases_unit_idx on public.leases(unit_id,status);
create table public.charge_rules (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid references public.leases(id) on delete cascade,
  unit_id uuid references public.units(id) on delete cascade,
  kind public.charge_kind not null,
  label text not null,
  amount_ugx bigint check (amount_ugx >= 0),
  frequency text not null default 'monthly',
  starts_on date not null,
  ends_on date,
  allocation_method text,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id) on delete restrict,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  invoice_number text not null,
  period_start date,
  period_end date,
  issued_at timestamptz,
  due_date date not null,
  currency_code char(3) not null default 'UGX',
  subtotal_ugx bigint not null default 0 check (subtotal_ugx >= 0),
  adjustment_ugx bigint not null default 0,
  total_ugx bigint not null check (total_ugx >= 0),
  status public.invoice_status not null default 'draft',
  tax_document_status text not null default 'not_integrated',
  tax_document_reference text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(organization_id,invoice_number)
);
create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  kind public.charge_kind not null,
  description text not null,
  quantity numeric(14,3) not null default 1 check (quantity >= 0),
  unit_label text,
  unit_rate_ugx bigint not null default 0 check (unit_rate_ugx >= 0),
  amount_ugx bigint not null check (amount_ugx >= 0),
  calculation_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  amount_ugx bigint not null check (amount_ugx > 0),
  method public.payment_method not null,
  status public.payment_status not null default 'pending',
  received_at timestamptz not null default now(),
  external_reference text,
  idempotency_key text not null,
  recorded_by uuid references auth.users(id) on delete set null,
  notes text,
  reversed_payment_id uuid references public.payments(id) on delete restrict,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(organization_id,idempotency_key)
);
create index payments_tenant_date_idx on public.payments(tenant_id,received_at desc);
create table public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  payment_id uuid not null references public.payments(id) on delete restrict,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  amount_ugx bigint not null check (amount_ugx > 0),
  created_at timestamptz not null default now(),
  unique(payment_id,invoice_id)
);
create table public.meters (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  unit_id uuid references public.units(id) on delete cascade,
  meter_code text not null,
  utility_kind public.charge_kind not null check (utility_kind in ('water','electricity','other')),
  measurement_unit text not null default 'm3',
  is_master_meter boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(property_id,meter_code)
);
create table public.meter_readings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  meter_id uuid not null references public.meters(id) on delete restrict,
  reading_value numeric(16,3) not null check (reading_value >= 0),
  read_at timestamptz not null,
  rate_ugx bigint not null check (rate_ugx >= 0),
  rate_source text,
  reading_photo_path text,
  entered_by uuid references auth.users(id) on delete set null,
  correction_note text,
  created_at timestamptz not null default now()
);
create index meter_readings_history_idx on public.meter_readings(meter_id,read_at desc);
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid references public.properties(id) on delete cascade,
  unit_id uuid references public.units(id) on delete cascade,
  tenant_id uuid references public.tenants(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete cascade,
  payment_id uuid references public.payments(id) on delete cascade,
  document_kind text not null,
  title text not null,
  object_path text not null,
  visibility text not null default 'tenant_and_staff' check (visibility in ('staff_only','tenant_and_staff')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table public.audit_events (
  id bigint generated always as identity primary key,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

-- Helper: current user is a member of an organization.
create or replace function public.is_org_member(target_org uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.organization_members m where m.organization_id=target_org and m.user_id=auth.uid()) $$;
create or replace function public.has_org_role(target_org uuid, allowed public.member_role[])
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.organization_members m where m.organization_id=target_org and m.user_id=auth.uid() and m.role=any(allowed)) $$;
create or replace function public.is_tenant_for(target_tenant uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.tenants t where t.id=target_tenant and t.auth_user_id=auth.uid()) $$;

-- Enable RLS everywhere that contains tenant or business information.
do $$ declare t text; begin
  foreach t in array array['organizations','profiles','organization_members','properties','units','tenants','leases','charge_rules','invoices','invoice_items','payments','payment_allocations','meters','meter_readings','documents','audit_events'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;

create policy "profiles read own" on public.profiles for select using (id=auth.uid());
create policy "profiles insert own" on public.profiles for insert with check (id=auth.uid());
create policy "profiles update own" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy "org members read org" on public.organizations for select using (public.is_org_member(id));
create policy "org creator insert" on public.organizations for insert with check (created_by=auth.uid());
create policy "org admins update" on public.organizations for update using (public.has_org_role(id,array['owner','admin']::public.member_role[])) with check (public.has_org_role(id,array['owner','admin']::public.member_role[]));
create policy "members can read membership" on public.organization_members for select using (public.is_org_member(organization_id) or user_id=auth.uid());
-- Membership creation/invites should be performed by a trusted server-side function after authorization.
create policy "members manage members" on public.organization_members for all using (public.has_org_role(organization_id,array['owner','admin']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin']::public.member_role[]));

-- Workspace members can read records in their organization. Mutations are limited by role.
create policy "properties member read" on public.properties for select using (public.is_org_member(organization_id));
create policy "properties manager insert" on public.properties for insert with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "properties manager update" on public.properties for update using (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "properties admin delete" on public.properties for delete using (public.has_org_role(organization_id,array['owner','admin']::public.member_role[]));

-- Tenant visibility is limited to the tenant's own record; staff access is organization-scoped.
create policy "tenants own or staff read" on public.tenants for select using (auth_user_id=auth.uid() or public.is_org_member(organization_id));
create policy "tenant staff insert" on public.tenants for insert with check (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[]));
create policy "tenant staff update" on public.tenants for update using (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[]));
create policy "tenant admin delete" on public.tenants for delete using (public.has_org_role(organization_id,array['owner','admin']::public.member_role[]));

-- Tenant portal is read-only. Staff can view/manage the workspace records they are allowed to access.
create policy "units member or own lease read" on public.units for select using (public.is_org_member(organization_id) or exists(select 1 from public.leases l join public.tenants t on t.id=l.tenant_id where l.unit_id=units.id and t.auth_user_id=auth.uid() and l.status='active'));
create policy "units manager write" on public.units for all using (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "leases own or staff read" on public.leases for select using (public.is_tenant_for(tenant_id) or public.is_org_member(organization_id));
create policy "leases staff write" on public.leases for all using (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "charges own lease or staff read" on public.charge_rules for select using (public.is_org_member(organization_id) or exists(select 1 from public.leases l join public.tenants t on t.id=l.tenant_id where l.id=charge_rules.lease_id and t.auth_user_id=auth.uid()));
create policy "charges manager write" on public.charge_rules for all using (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "invoices own or staff read" on public.invoices for select using (public.is_tenant_for(tenant_id) or public.is_org_member(organization_id));
create policy "invoices staff write" on public.invoices for all using (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[]));
create policy "invoice items own or staff read" on public.invoice_items for select using (public.is_org_member(organization_id) or exists(select 1 from public.invoices i where i.id=invoice_id and public.is_tenant_for(i.tenant_id)));
create policy "invoice items staff write" on public.invoice_items for all using (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[]));
create policy "payments own or staff read" on public.payments for select using (public.is_tenant_for(tenant_id) or public.is_org_member(organization_id));
create policy "payments staff insert" on public.payments for insert with check (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker','accountant']::public.member_role[]));
create policy "payments staff update" on public.payments for update using (public.has_org_role(organization_id,array['owner','admin','accountant']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','accountant']::public.member_role[]));
create policy "allocations own or staff read" on public.payment_allocations for select using (public.is_org_member(organization_id) or exists(select 1 from public.invoices i where i.id=invoice_id and public.is_tenant_for(i.tenant_id)));
create policy "allocations finance write" on public.payment_allocations for all using (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[]));
create policy "meters staff read" on public.meters for select using (public.is_org_member(organization_id));
create policy "meters staff write" on public.meters for all using (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[]));
create policy "readings staff read" on public.meter_readings for select using (public.is_org_member(organization_id));
create policy "readings staff insert" on public.meter_readings for insert with check (public.has_org_role(organization_id,array['owner','admin','property_manager','caretaker']::public.member_role[]));
create policy "readings correction restricted" on public.meter_readings for update using (public.has_org_role(organization_id,array['owner','admin']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin']::public.member_role[]));
create policy "documents tenant or staff read" on public.documents for select using ((public.is_org_member(organization_id)) or (visibility='tenant_and_staff' and tenant_id is not null and public.is_tenant_for(tenant_id)));
create policy "documents staff insert" on public.documents for insert with check (public.has_org_role(organization_id,array['owner','admin','property_manager','accountant']::public.member_role[]));
create policy "documents staff update" on public.documents for update using (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[])) with check (public.has_org_role(organization_id,array['owner','admin','property_manager']::public.member_role[]));
create policy "audit staff read" on public.audit_events for select using (public.has_org_role(organization_id,array['owner','admin','accountant']::public.member_role[]));
-- Audit events should be written by server-side functions; do not permit ordinary client inserts.

-- Important launch hardening still required:
-- 1) Add tenant-specific storage.objects policies for private buckets.
-- 2) Add SECURITY DEFINER RPCs for atomic payment allocation, invoice status changes,
--    membership invitation/acceptance, audit events, and safe tenant account linking.
-- 3) Validate role hierarchy and org_id ownership on every write, including invoice_items and meter relationships.
-- 4) Never expose the Supabase service-role key to the browser or mobile app.
-- 5) Add DB constraints/triggers that ensure allocations cannot exceed payment or invoice balances.

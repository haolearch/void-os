-- ============================================================
-- VOID OS
-- Migration: 005_crm.sql
-- Purpose:
--   Create the customer relationship management foundation.
--
-- Tables:
--   1. customers
--   2. contacts
--   3. customer_addresses
-- ============================================================

begin;

-- ============================================================
-- CUSTOMERS
-- Stores individual and company clients.
-- ============================================================

create table public.customers (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,

  customer_type public.customer_type not null default 'individual',
  status public.customer_status not null default 'lead',
  source public.customer_source not null default 'other',

  display_name text not null,
  legal_name text,

  tax_code text,
  email extensions.citext,
  phone text,
  website text,

  representative_name text,
  representative_title text,

  industry text,

  notes text,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint customers_code_not_blank
    check (length(trim(code)) > 0),

  constraint customers_display_name_not_blank
    check (length(trim(display_name)) > 0),

  constraint customers_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint customers_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.customers is
  'Individual and company customers managed by an organization.';

comment on column public.customers.code is
  'Organization-scoped customer code, for example KH000001.';

comment on column public.customers.display_name is
  'Primary name displayed throughout VOID OS.';

comment on column public.customers.legal_name is
  'Registered legal name when the customer is a company.';

comment on column public.customers.representative_name is
  'Primary legal or business representative for a company customer.';

-- Required for same-organization composite relationships later.
alter table public.customers
  add constraint customers_id_organization_unique
  unique (id, organization_id);

-- One active customer code per organization.
create unique index customers_active_code_unique
  on public.customers (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

-- One active tax code per organization when provided.
create unique index customers_active_tax_code_unique
  on public.customers (
    organization_id,
    tax_code
  )
  where tax_code is not null
    and deleted_at is null;

create index customers_organization_idx
  on public.customers (organization_id)
  where deleted_at is null;

create index customers_status_idx
  on public.customers (
    organization_id,
    status
  )
  where deleted_at is null;

create index customers_type_idx
  on public.customers (
    organization_id,
    customer_type
  )
  where deleted_at is null;

create index customers_source_idx
  on public.customers (
    organization_id,
    source
  )
  where deleted_at is null;

create index customers_created_at_idx
  on public.customers (
    organization_id,
    created_at desc
  )
  where deleted_at is null;

create index customers_name_search_idx
  on public.customers
  using gin (display_name gin_trgm_ops)
  where deleted_at is null;

create index customers_phone_idx
  on public.customers (phone)
  where phone is not null
    and deleted_at is null;

create index customers_email_idx
  on public.customers (email)
  where email is not null
    and deleted_at is null;

-- ============================================================
-- CONTACTS
-- Stores people associated with a customer.
--
-- Examples:
--   Owner
--   Director
--   Accountant
--   Project representative
--   Site contact
-- ============================================================

create table public.contacts (
  id uuid primary key default gen_random_uuid(),

  customer_id uuid not null
    references public.customers(id)
    on delete restrict,

  full_name text not null,
  job_title text,
  department text,

  email extensions.citext,
  phone text,
  alternate_phone text,

  is_primary boolean not null default false,
  is_active boolean not null default true,

  notes text,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint contacts_full_name_not_blank
    check (length(trim(full_name)) > 0),

  constraint contacts_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.contacts is
  'Individual contacts associated with customer records.';

comment on column public.contacts.is_primary is
  'Marks the primary contact person for the customer.';

-- Only one active primary contact per customer.
create unique index contacts_primary_contact_unique
  on public.contacts (customer_id)
  where is_primary = true
    and deleted_at is null;

create index contacts_customer_idx
  on public.contacts (customer_id)
  where deleted_at is null;

create index contacts_customer_active_idx
  on public.contacts (
    customer_id,
    is_active
  )
  where deleted_at is null;

create index contacts_name_search_idx
  on public.contacts
  using gin (full_name gin_trgm_ops)
  where deleted_at is null;

create index contacts_phone_idx
  on public.contacts (phone)
  where phone is not null
    and deleted_at is null;

create index contacts_email_idx
  on public.contacts (email)
  where email is not null
    and deleted_at is null;

-- ============================================================
-- CUSTOMER ADDRESSES
-- Stores billing, office, home and project-related addresses.
-- ============================================================

create table public.customer_addresses (
  id uuid primary key default gen_random_uuid(),

  customer_id uuid not null
    references public.customers(id)
    on delete restrict,

  address_type text not null default 'other',
  label text,

  recipient_name text,
  recipient_phone text,

  address_line text not null,
  ward text,
  district text,
  province text,
  postal_code text,
  country_code text not null default 'VN',

  latitude numeric(10, 7),
  longitude numeric(10, 7),

  is_default boolean not null default false,
  notes text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint customer_addresses_address_not_blank
    check (length(trim(address_line)) > 0),

  constraint customer_addresses_type_valid
    check (
      address_type in (
        'home',
        'office',
        'billing',
        'site',
        'shipping',
        'other'
      )
    ),

  constraint customer_addresses_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),

  constraint customer_addresses_latitude_valid
    check (
      latitude is null
      or latitude between -90 and 90
    ),

  constraint customer_addresses_longitude_valid
    check (
      longitude is null
      or longitude between -180 and 180
    ),

  constraint customer_addresses_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.customer_addresses is
  'Addresses associated with customer records.';

comment on column public.customer_addresses.address_type is
  'Address purpose such as home, office, billing, site or shipping.';

-- One default address for each address type per customer.
create unique index customer_addresses_default_type_unique
  on public.customer_addresses (
    customer_id,
    address_type
  )
  where is_default = true
    and deleted_at is null;

create index customer_addresses_customer_idx
  on public.customer_addresses (customer_id)
  where deleted_at is null;

create index customer_addresses_type_idx
  on public.customer_addresses (
    customer_id,
    address_type
  )
  where deleted_at is null;

create index customer_addresses_province_idx
  on public.customer_addresses (province)
  where province is not null
    and deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
--
-- Policies will be added later in 014_policies.sql.
-- Contacts and addresses inherit organization ownership through
-- their linked customer.
-- ============================================================

alter table public.customers enable row level security;
alter table public.contacts enable row level security;
alter table public.customer_addresses enable row level security;

commit;
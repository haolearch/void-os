-- ============================================================
-- VOID OS
-- Migration: 003_system.sql
-- Purpose:
--   Create the multi-tenant system foundation.
--
-- Tables:
--   1. organizations
--   2. organization_members
-- ============================================================

begin;

-- ============================================================
-- ORGANIZATIONS
-- Represents a company or workspace using VOID OS.
-- ============================================================

create table public.organizations (
  id uuid primary key default gen_random_uuid(),

  code text not null,
  name text not null,
  legal_name text,

  tax_code text,
  email extensions.citext,
  phone text,
  website text,

  address_line text,
  ward text,
  district text,
  province text,
  country_code text not null default 'VN',

  logo_url text,

  timezone text not null default 'Asia/Ho_Chi_Minh',
  currency_code text not null default 'VND',
  locale text not null default 'vi-VN',

  status public.organization_status not null default 'active',

  settings jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint organizations_code_not_blank
    check (length(trim(code)) > 0),

  constraint organizations_name_not_blank
    check (length(trim(name)) > 0),

  constraint organizations_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint organizations_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),

  constraint organizations_currency_code_format
    check (currency_code ~ '^[A-Z]{3}$'),

  constraint organizations_settings_is_object
    check (jsonb_typeof(settings) = 'object'),

  constraint organizations_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.organizations is
  'Companies or business workspaces using VOID OS.';

comment on column public.organizations.code is
  'Short organization identifier, for example VOID.';

comment on column public.organizations.settings is
  'Organization-level configurable settings stored as a JSON object.';

comment on column public.organizations.metadata is
  'Additional non-core organization metadata stored as a JSON object.';

-- Organization codes must be unique among records that have not been
-- soft deleted. This allows an old deleted code to be reused if needed.
create unique index organizations_active_code_unique
  on public.organizations (upper(code))
  where deleted_at is null;

-- Tax codes are unique within active organization records when provided.
create unique index organizations_active_tax_code_unique
  on public.organizations (tax_code)
  where tax_code is not null
    and deleted_at is null;

create index organizations_status_idx
  on public.organizations (status)
  where deleted_at is null;

create index organizations_created_at_idx
  on public.organizations (created_at desc);

-- ============================================================
-- ORGANIZATION MEMBERS
-- Links Supabase Auth users to organizations.
--
-- A user may belong to multiple organizations.
-- Each user can only have one membership record per organization.
-- ============================================================

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  role public.organization_member_role not null default 'member',
  status public.organization_member_status not null default 'invited',

  display_name text,
  job_title text,

  invited_at timestamptz,
  joined_at timestamptz,
  last_active_at timestamptz,

  permissions_context jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint organization_members_permissions_context_is_object
    check (jsonb_typeof(permissions_context) = 'object'),

  constraint organization_members_metadata_is_object
    check (jsonb_typeof(metadata) = 'object'),

  constraint organization_members_joined_after_invitation
    check (
      joined_at is null
      or invited_at is null
      or joined_at >= invited_at
    )
);

comment on table public.organization_members is
  'Membership records linking Supabase Auth users to organizations.';

comment on column public.organization_members.role is
  'The member role within this organization.';

comment on column public.organization_members.permissions_context is
  'Optional per-member permission overrides or contextual access data.';

-- A user can only have one non-deleted membership in an organization.
create unique index organization_members_active_membership_unique
  on public.organization_members (organization_id, user_id)
  where deleted_at is null;

create index organization_members_organization_idx
  on public.organization_members (organization_id)
  where deleted_at is null;

create index organization_members_user_idx
  on public.organization_members (user_id)
  where deleted_at is null;

create index organization_members_status_idx
  on public.organization_members (organization_id, status)
  where deleted_at is null;

create index organization_members_role_idx
  on public.organization_members (organization_id, role)
  where deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
--
-- Policies will be created later in 014_policies.sql.
-- Enabling RLS now prevents accidental public data access.
-- ============================================================

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;

commit;
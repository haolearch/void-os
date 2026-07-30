-- ============================================================
-- VOID OS
-- Migration: 004_people.sql
-- Purpose:
--   Create the people and employee management foundation.
--
-- Tables:
--   1. employee_positions
--   2. employees
-- ============================================================

begin;

-- ============================================================
-- EMPLOYEE POSITIONS
-- Standard job positions used within one organization.
--
-- Examples:
--   Founder
--   Architect
--   Interior Designer
--   Site Supervisor
--   Accountant
--   Intern
-- ============================================================

create table public.employee_positions (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,
  name text not null,
  description text,

  sort_order integer not null default 0,
  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint employee_positions_code_not_blank
    check (length(trim(code)) > 0),

  constraint employee_positions_name_not_blank
    check (length(trim(name)) > 0),

  constraint employee_positions_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint employee_positions_sort_order_non_negative
    check (sort_order >= 0)
);

comment on table public.employee_positions is
  'Standard employee job positions defined within an organization.';

comment on column public.employee_positions.code is
  'Organization-scoped position code, for example ARCHITECT or INTERN.';

comment on column public.employee_positions.sort_order is
  'Controls display ordering in employee forms and reports.';

create unique index employee_positions_active_code_unique
  on public.employee_positions (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create unique index employee_positions_active_name_unique
  on public.employee_positions (
    organization_id,
    lower(name)
  )
  where deleted_at is null;

create index employee_positions_organization_idx
  on public.employee_positions (organization_id)
  where deleted_at is null;

create index employee_positions_active_idx
  on public.employee_positions (
    organization_id,
    is_active,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- EMPLOYEES
-- Stores staff, interns, freelancers and collaborators.
--
-- An employee may optionally be linked to an authenticated
-- organization member.
--
-- This separation allows VOID OS to manage people who do not
-- yet need a login account.
-- ============================================================

create table public.employees (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  organization_member_id uuid,

  position_id uuid
    references public.employee_positions(id)
    on delete set null,

  code text not null,

  full_name text not null,
  preferred_name text,

  email extensions.citext,
  phone text,

  date_of_birth date,
  gender text,

  employee_type public.employee_type not null default 'full_time',
  status public.employee_status not null default 'active',

  hire_date date,
  termination_date date,

  base_salary numeric(18, 2),
  salary_notes text,

  identity_number text,
  tax_code text,

  address_line text,
  ward text,
  district text,
  province text,
  country_code text not null default 'VN',

  emergency_contact_name text,
  emergency_contact_phone text,
  emergency_contact_relationship text,

  avatar_url text,
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

  constraint employees_code_not_blank
    check (length(trim(code)) > 0),

  constraint employees_full_name_not_blank
    check (length(trim(full_name)) > 0),

  constraint employees_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint employees_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),

  constraint employees_base_salary_non_negative
    check (
      base_salary is null
      or base_salary >= 0
    ),

  constraint employees_termination_after_hire
    check (
      termination_date is null
      or hire_date is null
      or termination_date >= hire_date
    ),

  constraint employees_metadata_is_object
    check (jsonb_typeof(metadata) = 'object'),

  constraint employees_gender_valid
    check (
      gender is null
      or gender in (
        'male',
        'female',
        'other',
        'prefer_not_to_say'
      )
    ),

  constraint employees_organization_member_unique
    unique (organization_member_id)
);

comment on table public.employees is
  'Employees, interns, contractors, freelancers and collaborators managed by an organization.';

comment on column public.employees.organization_member_id is
  'Optional link to the employee login membership in organization_members.';

comment on column public.employees.base_salary is
  'Current reference base salary. Full payroll history is outside V1 scope.';

comment on column public.employees.metadata is
  'Additional non-core employee data stored as a JSON object.';

-- ------------------------------------------------------------
-- Composite relationship:
-- Ensures that an employee can only link to an organization
-- membership belonging to the same organization.
-- ------------------------------------------------------------

alter table public.organization_members
  add constraint organization_members_id_organization_unique
  unique (id, organization_id);

alter table public.employees
  add constraint employees_member_same_organization_fk
  foreign key (
    organization_member_id,
    organization_id
  )
  references public.organization_members (
    id,
    organization_id
  )
  on delete set null;

-- ------------------------------------------------------------
-- Composite relationship:
-- Ensures that the selected employee position belongs to the
-- same organization as the employee.
-- ------------------------------------------------------------

alter table public.employee_positions
  add constraint employee_positions_id_organization_unique
  unique (id, organization_id);

alter table public.employees
  add constraint employees_position_same_organization_fk
  foreign key (
    position_id,
    organization_id
  )
  references public.employee_positions (
    id,
    organization_id
  )
  on delete set null;

-- One active employee code per organization.
create unique index employees_active_code_unique
  on public.employees (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

-- Email should not be duplicated within one organization.
create unique index employees_active_email_unique
  on public.employees (
    organization_id,
    email
  )
  where email is not null
    and deleted_at is null;

-- Identity number should not be duplicated within one organization.
create unique index employees_active_identity_number_unique
  on public.employees (
    organization_id,
    identity_number
  )
  where identity_number is not null
    and deleted_at is null;

create index employees_organization_idx
  on public.employees (organization_id)
  where deleted_at is null;

create index employees_position_idx
  on public.employees (
    organization_id,
    position_id
  )
  where deleted_at is null;

create index employees_status_idx
  on public.employees (
    organization_id,
    status
  )
  where deleted_at is null;

create index employees_type_idx
  on public.employees (
    organization_id,
    employee_type
  )
  where deleted_at is null;

create index employees_name_search_idx
  on public.employees
  using gin (full_name gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
--
-- Policies will be defined later in 014_policies.sql.
-- ============================================================

alter table public.employee_positions enable row level security;
alter table public.employees enable row level security;

commit;
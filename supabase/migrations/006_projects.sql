-- ============================================================
-- VOID OS
-- Migration: 006_projects.sql
-- Purpose:
--   Create the project delivery and task management module.
--
-- Tables:
--   1. projects
--   2. project_phases
--   3. project_members
--   4. milestones
--   5. tasks
--   6. project_status_history
--
-- Multi-tenant rule:
--   Every table stores organization_id.
--   Composite foreign keys prevent cross-organization relations.
-- ============================================================

begin;

-- ============================================================
-- EMPLOYEES: PREPARE COMPOSITE FOREIGN KEY
-- Allows other tables to validate employee organization ownership.
-- ============================================================

alter table public.employees
  add constraint employees_id_organization_unique
  unique (id, organization_id);

-- ============================================================
-- PROJECTS
-- Main record for an architecture, interior or construction job.
-- ============================================================

create table public.projects (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  customer_id uuid not null,

  code text not null,
  name text not null,
  description text,

  project_type public.project_type not null default 'other',
  status public.project_status not null default 'lead',
  priority public.project_priority not null default 'normal',

  site_address text,
  ward text,
  district text,
  province text,
  country_code text not null default 'VN',

  site_area numeric(14, 2),
  construction_area numeric(14, 2),

  start_date date,
  expected_end_date date,
  actual_end_date date,

  estimated_value numeric(18, 2),

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

  constraint projects_code_not_blank
    check (length(trim(code)) > 0),

  constraint projects_name_not_blank
    check (length(trim(name)) > 0),

  constraint projects_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint projects_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),

  constraint projects_site_area_non_negative
    check (
      site_area is null
      or site_area >= 0
    ),

  constraint projects_construction_area_non_negative
    check (
      construction_area is null
      or construction_area >= 0
    ),

  constraint projects_estimated_value_non_negative
    check (
      estimated_value is null
      or estimated_value >= 0
    ),

  constraint projects_expected_dates_valid
    check (
      expected_end_date is null
      or start_date is null
      or expected_end_date >= start_date
    ),

  constraint projects_actual_dates_valid
    check (
      actual_end_date is null
      or start_date is null
      or actual_end_date >= start_date
    ),

  constraint projects_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.projects is
  'Architecture, interior design, construction and related projects.';

comment on column public.projects.code is
  'Organization-scoped display code, for example DA000001.';

-- Required for tenant-safe composite foreign keys.
alter table public.projects
  add constraint projects_id_organization_unique
  unique (id, organization_id);

-- Project and customer must belong to the same organization.
alter table public.projects
  add constraint projects_customer_same_organization_fk
  foreign key (
    customer_id,
    organization_id
  )
  references public.customers (
    id,
    organization_id
  )
  on delete restrict;

create unique index projects_active_code_unique
  on public.projects (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index projects_organization_idx
  on public.projects (organization_id)
  where deleted_at is null;

create index projects_customer_idx
  on public.projects (
    organization_id,
    customer_id
  )
  where deleted_at is null;

create index projects_status_idx
  on public.projects (
    organization_id,
    status
  )
  where deleted_at is null;

create index projects_priority_idx
  on public.projects (
    organization_id,
    priority
  )
  where deleted_at is null;

create index projects_expected_end_date_idx
  on public.projects (
    organization_id,
    expected_end_date
  )
  where expected_end_date is not null
    and deleted_at is null;

create index projects_name_search_idx
  on public.projects
  using gin (name gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- PROJECT PHASES
-- Examples:
--   Concept design
--   Technical design
--   Construction
--   Handover
--   Warranty
-- ============================================================

create table public.project_phases (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,

  name text not null,
  description text,

  sort_order integer not null default 0,
  status public.phase_status not null default 'not_started',

  start_date date,
  due_date date,
  completed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint project_phases_name_not_blank
    check (length(trim(name)) > 0),

  constraint project_phases_sort_order_non_negative
    check (sort_order >= 0),

  constraint project_phases_dates_valid
    check (
      due_date is null
      or start_date is null
      or due_date >= start_date
    )
);

comment on table public.project_phases is
  'Ordered delivery phases belonging to a project.';

alter table public.project_phases
  add constraint project_phases_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

-- Used by milestones and tasks to verify they belong to the same project.
alter table public.project_phases
  add constraint project_phases_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

create unique index project_phases_active_name_unique
  on public.project_phases (
    project_id,
    lower(name)
  )
  where deleted_at is null;

create index project_phases_project_idx
  on public.project_phases (
    organization_id,
    project_id,
    sort_order
  )
  where deleted_at is null;

create index project_phases_status_idx
  on public.project_phases (
    organization_id,
    project_id,
    status
  )
  where deleted_at is null;

create index project_phases_due_date_idx
  on public.project_phases (
    organization_id,
    due_date
  )
  where due_date is not null
    and deleted_at is null;

-- ============================================================
-- PROJECT MEMBERS
-- Connects employees to projects.
-- ============================================================

create table public.project_members (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,
  employee_id uuid not null,

  role public.project_member_role not null default 'collaborator',

  is_primary boolean not null default false,
  is_active boolean not null default true,

  assigned_at timestamptz not null default now(),
  removed_at timestamptz,

  notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint project_members_removed_after_assigned
    check (
      removed_at is null
      or removed_at >= assigned_at
    )
);

comment on table public.project_members is
  'Employees and collaborators assigned to projects.';

alter table public.project_members
  add constraint project_members_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_members
  add constraint project_members_employee_same_organization_fk
  foreign key (
    employee_id,
    organization_id
  )
  references public.employees (
    id,
    organization_id
  )
  on delete restrict;

-- One active assignment for an employee in one project.
-- A soft-deleted assignment can later be recreated.
create unique index project_members_active_project_employee_unique
  on public.project_members (
    project_id,
    employee_id
  )
  where deleted_at is null;

-- Only one primary member for each project role.
create unique index project_members_primary_role_unique
  on public.project_members (
    project_id,
    role
  )
  where is_primary = true
    and is_active = true
    and deleted_at is null;

create index project_members_project_idx
  on public.project_members (
    organization_id,
    project_id,
    is_active
  )
  where deleted_at is null;

create index project_members_employee_idx
  on public.project_members (
    organization_id,
    employee_id,
    is_active
  )
  where deleted_at is null;

create index project_members_role_idx
  on public.project_members (
    organization_id,
    project_id,
    role
  )
  where deleted_at is null;

-- ============================================================
-- MILESTONES
-- Major project delivery checkpoints.
-- ============================================================

create table public.milestones (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,
  project_phase_id uuid,

  title text not null,
  description text,

  status public.milestone_status not null default 'pending',

  due_date date,
  completed_at timestamptz,

  sort_order integer not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid
    references auth.users(id)
    on delete set null,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  constraint milestones_title_not_blank
    check (length(trim(title)) > 0),

  constraint milestones_sort_order_non_negative
    check (sort_order >= 0)
);

comment on table public.milestones is
  'Major delivery checkpoints within a project.';

alter table public.milestones
  add constraint milestones_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

-- The phase must belong to the same project and organization.
alter table public.milestones
  add constraint milestones_phase_same_project_fk
  foreign key (
    project_phase_id,
    project_id,
    organization_id
  )
  references public.project_phases (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

-- Used by tasks for same-project validation.
alter table public.milestones
  add constraint milestones_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

create index milestones_project_idx
  on public.milestones (
    organization_id,
    project_id,
    sort_order
  )
  where deleted_at is null;

create index milestones_phase_idx
  on public.milestones (
    organization_id,
    project_phase_id
  )
  where project_phase_id is not null
    and deleted_at is null;

create index milestones_status_idx
  on public.milestones (
    organization_id,
    project_id,
    status
  )
  where deleted_at is null;

create index milestones_due_date_idx
  on public.milestones (
    organization_id,
    due_date
  )
  where due_date is not null
    and deleted_at is null;

-- ============================================================
-- TASKS
-- Actionable work items within projects.
-- Supports phases, milestones, assignees and subtasks.
-- ============================================================

create table public.tasks (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,

  project_phase_id uuid,
  milestone_id uuid,
  assignee_employee_id uuid,
  parent_task_id uuid,

  title text not null,
  description text,

  status public.task_status not null default 'todo',
  priority public.project_priority not null default 'normal',

  start_date date,
  due_date date,
  completed_at timestamptz,

  estimated_hours numeric(10, 2),
  actual_hours numeric(10, 2),

  sort_order integer not null default 0,
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

  constraint tasks_title_not_blank
    check (length(trim(title)) > 0),

  constraint tasks_dates_valid
    check (
      due_date is null
      or start_date is null
      or due_date >= start_date
    ),

  constraint tasks_estimated_hours_non_negative
    check (
      estimated_hours is null
      or estimated_hours >= 0
    ),

  constraint tasks_actual_hours_non_negative
    check (
      actual_hours is null
      or actual_hours >= 0
    ),

  constraint tasks_sort_order_non_negative
    check (sort_order >= 0),

  constraint tasks_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.tasks is
  'Actionable project work items, assignments and subtasks.';

alter table public.tasks
  add constraint tasks_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

-- Optional phase must belong to the same project.
alter table public.tasks
  add constraint tasks_phase_same_project_fk
  foreign key (
    project_phase_id,
    project_id,
    organization_id
  )
  references public.project_phases (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

-- Optional milestone must belong to the same project.
alter table public.tasks
  add constraint tasks_milestone_same_project_fk
  foreign key (
    milestone_id,
    project_id,
    organization_id
  )
  references public.milestones (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

-- Optional assignee must belong to the same organization.
alter table public.tasks
  add constraint tasks_assignee_same_organization_fk
  foreign key (
    assignee_employee_id,
    organization_id
  )
  references public.employees (
    id,
    organization_id
  )
  on delete restrict;

-- Required for tenant-safe task hierarchy.
alter table public.tasks
  add constraint tasks_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

-- A parent task must belong to the same project and organization.
alter table public.tasks
  add constraint tasks_parent_same_project_fk
  foreign key (
    parent_task_id,
    project_id,
    organization_id
  )
  references public.tasks (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

create index tasks_project_idx
  on public.tasks (
    organization_id,
    project_id,
    status
  )
  where deleted_at is null;

create index tasks_phase_idx
  on public.tasks (
    organization_id,
    project_phase_id
  )
  where project_phase_id is not null
    and deleted_at is null;

create index tasks_milestone_idx
  on public.tasks (
    organization_id,
    milestone_id
  )
  where milestone_id is not null
    and deleted_at is null;

create index tasks_assignee_idx
  on public.tasks (
    organization_id,
    assignee_employee_id,
    status
  )
  where assignee_employee_id is not null
    and deleted_at is null;

create index tasks_due_date_idx
  on public.tasks (
    organization_id,
    due_date
  )
  where due_date is not null
    and deleted_at is null;

create index tasks_parent_idx
  on public.tasks (
    organization_id,
    parent_task_id
  )
  where parent_task_id is not null
    and deleted_at is null;

create index tasks_title_search_idx
  on public.tasks
  using gin (title gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- PROJECT STATUS HISTORY
-- Stores every project status change.
-- ============================================================

create table public.project_status_history (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,

  previous_status public.project_status,
  new_status public.project_status not null,

  changed_by uuid
    references auth.users(id)
    on delete set null,

  changed_at timestamptz not null default now(),

  reason text,
  metadata jsonb not null default '{}'::jsonb,

  constraint project_status_history_status_changed
    check (
      previous_status is null
      or previous_status <> new_status
    ),

  constraint project_status_history_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.project_status_history is
  'Immutable history of project status changes.';

alter table public.project_status_history
  add constraint project_status_history_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

create index project_status_history_project_idx
  on public.project_status_history (
    organization_id,
    project_id,
    changed_at desc
  );

create index project_status_history_status_idx
  on public.project_status_history (
    organization_id,
    new_status,
    changed_at desc
  );

-- ============================================================
-- ROW LEVEL SECURITY
-- Policies will be created in a later migration.
-- ============================================================

alter table public.projects enable row level security;
alter table public.project_phases enable row level security;
alter table public.project_members enable row level security;
alter table public.milestones enable row level security;
alter table public.tasks enable row level security;
alter table public.project_status_history enable row level security;

commit;
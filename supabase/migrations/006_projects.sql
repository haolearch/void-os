-- ============================================================
-- VOID OS
-- Migration: 006_projects.sql
-- Purpose:
--   Create project delivery and task management tables.
--
-- Tables:
--   1. projects
--   2. project_phases
--   3. project_members
--   4. milestones
--   5. tasks
--   6. project_status_history
-- ============================================================

begin;

-- ============================================================
-- PROJECTS
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

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint projects_code_not_blank
    check (length(trim(code)) > 0),

  constraint projects_name_not_blank
    check (length(trim(name)) > 0),

  constraint projects_code_format
    check (code ~ '^[A-Z0-9][A-Z0-9_-]*$'),

  constraint projects_country_code_format
    check (country_code ~ '^[A-Z]{2}$'),

  constraint projects_site_area_non_negative
    check (site_area is null or site_area >= 0),

  constraint projects_construction_area_non_negative
    check (construction_area is null or construction_area >= 0),

  constraint projects_estimated_value_non_negative
    check (estimated_value is null or estimated_value >= 0),

  constraint projects_dates_valid
    check (
      expected_end_date is null
      or start_date is null
      or expected_end_date >= start_date
    ),

  constraint projects_actual_end_date_valid
    check (
      actual_end_date is null
      or start_date is null
      or actual_end_date >= start_date
    ),

  constraint projects_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

alter table public.projects
  add constraint projects_id_organization_unique
  unique (id, organization_id);

alter table public.projects
  add constraint projects_customer_same_organization_fk
  foreign key (customer_id, organization_id)
  references public.customers (id, organization_id)
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

create index projects_name_search_idx
  on public.projects
  using gin (name gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- PROJECT PHASES
-- ============================================================

create table public.project_phases (
  id uuid primary key default gen_random_uuid(),

  project_id uuid not null
    references public.projects(id)
    on delete restrict,

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

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

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

create unique index project_phases_active_name_unique
  on public.project_phases (
    project_id,
    lower(name)
  )
  where deleted_at is null;

create index project_phases_project_idx
  on public.project_phases (
    project_id,
    sort_order
  )
  where deleted_at is null;

create index project_phases_status_idx
  on public.project_phases (
    project_id,
    status
  )
  where deleted_at is null;

-- ============================================================
-- PROJECT MEMBERS
-- ============================================================

create table public.project_members (
  id uuid primary key default gen_random_uuid(),

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

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint project_members_removed_after_assigned
    check (
      removed_at is null
      or removed_at >= assigned_at
    )
);

alter table public.project_members
  add constraint project_members_project_employee_unique
  unique (project_id, employee_id);

alter table public.project_members
  add constraint project_members_project_same_organization_fk
  foreign key (project_id)
  references public.projects(id)
  on delete restrict;

alter table public.project_members
  add constraint project_members_employee_fk
  foreign key (employee_id)
  references public.employees(id)
  on delete restrict;

create index project_members_project_idx
  on public.project_members (
    project_id,
    is_active
  )
  where deleted_at is null;

create index project_members_employee_idx
  on public.project_members (
    employee_id,
    is_active
  )
  where deleted_at is null;

create unique index project_members_primary_role_unique
  on public.project_members (
    project_id,
    role
  )
  where is_primary = true
    and is_active = true
    and deleted_at is null;

-- ============================================================
-- MILESTONES
-- ============================================================

create table public.milestones (
  id uuid primary key default gen_random_uuid(),

  project_id uuid not null
    references public.projects(id)
    on delete restrict,

  project_phase_id uuid
    references public.project_phases(id)
    on delete set null,

  title text not null,
  description text,

  status public.milestone_status not null default 'pending',
  due_date date,
  completed_at timestamptz,
  sort_order integer not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint milestones_title_not_blank
    check (length(trim(title)) > 0),

  constraint milestones_sort_order_non_negative
    check (sort_order >= 0)
);

create index milestones_project_idx
  on public.milestones (
    project_id,
    sort_order
  )
  where deleted_at is null;

create index milestones_phase_idx
  on public.milestones (
    project_phase_id
  )
  where project_phase_id is not null
    and deleted_at is null;

create index milestones_status_idx
  on public.milestones (
    project_id,
    status
  )
  where deleted_at is null;

create index milestones_due_date_idx
  on public.milestones (
    due_date
  )
  where due_date is not null
    and deleted_at is null;

-- ============================================================
-- TASKS
-- ============================================================

create table public.tasks (
  id uuid primary key default gen_random_uuid(),

  project_id uuid not null
    references public.projects(id)
    on delete restrict,

  project_phase_id uuid
    references public.project_phases(id)
    on delete set null,

  milestone_id uuid
    references public.milestones(id)
    on delete set null,

  assignee_employee_id uuid
    references public.employees(id)
    on delete set null,

  parent_task_id uuid
    references public.tasks(id)
    on delete set null,

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

  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,

  constraint tasks_title_not_blank
    check (length(trim(title)) > 0),

  constraint tasks_dates_valid
    check (
      due_date is null
      or start_date is null
      or due_date >= start_date
    ),

  constraint tasks_estimated_hours_non_negative
    check (estimated_hours is null or estimated_hours >= 0),

  constraint tasks_actual_hours_non_negative
    check (actual_hours is null or actual_hours >= 0),

  constraint tasks_sort_order_non_negative
    check (sort_order >= 0),

  constraint tasks_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

create index tasks_project_idx
  on public.tasks (
    project_id,
    status
  )
  where deleted_at is null;

create index tasks_phase_idx
  on public.tasks (
    project_phase_id
  )
  where project_phase_id is not null
    and deleted_at is null;

create index tasks_milestone_idx
  on public.tasks (
    milestone_id
  )
  where milestone_id is not null
    and deleted_at is null;

create index tasks_assignee_idx
  on public.tasks (
    assignee_employee_id,
    status
  )
  where assignee_employee_id is not null
    and deleted_at is null;

create index tasks_due_date_idx
  on public.tasks (
    due_date
  )
  where due_date is not null
    and deleted_at is null;

create index tasks_parent_idx
  on public.tasks (
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
-- ============================================================

create table public.project_status_history (
  id uuid primary key default gen_random_uuid(),

  project_id uuid not null
    references public.projects(id)
    on delete restrict,

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

create index project_status_history_project_idx
  on public.project_status_history (
    project_id,
    changed_at desc
  );

create index project_status_history_new_status_idx
  on public.project_status_history (
    new_status,
    changed_at desc
  );

-- ============================================================
-- ROW LEVEL SECURITY
-- Policies will be created later.
-- ============================================================

alter table public.projects enable row level security;
alter table public.project_phases enable row level security;
alter table public.project_members enable row level security;
alter table public.milestones enable row level security;
alter table public.tasks enable row level security;
alter table public.project_status_history enable row level security;

commit;
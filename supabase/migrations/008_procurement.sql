-- ============================================================
-- VOID OS
-- Migration: 008_procurement.sql
-- Purpose:
--   Create the procurement, supplier, material catalogue,
--   budgeting, purchasing and project expense module.
--
-- Tables:
--   1. units
--   2. suppliers
--   3. supplier_contacts
--   4. material_categories
--   5. materials
--   6. material_suppliers
--   7. material_prices
--   8. work_categories
--   9. project_budgets
--   10. project_budget_items
--   11. purchase_orders
--   12. purchase_order_items
--   13. project_expenses
-- ============================================================

begin;

-- ============================================================
-- ENUMS
-- Guarded creation for procurement-specific enum types.
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'supplier_type'
  ) then
    create type public.supplier_type as enum (
      'material_supplier',
      'subcontractor',
      'service_provider',
      'consultant',
      'equipment_rental',
      'other'
    );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'budget_item_type'
  ) then
    create type public.budget_item_type as enum (
      'group',
      'material',
      'labour',
      'subcontractor',
      'service',
      'equipment',
      'transport',
      'other'
    );
  end if;
end
$$;

-- ============================================================
-- UNITS
-- Organization-scoped measurement units.
-- ============================================================

create table public.units (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,
  name text not null,
  symbol text,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,

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

  constraint units_code_not_blank
    check (length(trim(code)) > 0),

  constraint units_name_not_blank
    check (length(trim(name)) > 0),

  constraint units_sort_order_non_negative
    check (sort_order >= 0),

  constraint units_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.units is
  'Measurement units used across an organization for material, budget and purchasing workflows.';

comment on column public.units.code is
  'Short unit code such as m2, m, md, kg, item, set or hour.';

alter table public.units
  add constraint units_id_organization_unique
  unique (id, organization_id);

create unique index units_active_code_unique
  on public.units (
    organization_id,
    upper(code)
  )
  where is_active = true
    and deleted_at is null;

create index units_organization_idx
  on public.units (organization_id)
  where deleted_at is null;

create index units_active_idx
  on public.units (
    organization_id,
    is_active,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- SUPPLIERS
-- Suppliers, vendors and subcontractors for procurement.
-- ============================================================

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,
  name text not null,
  supplier_type public.supplier_type not null default 'other',
  status public.supplier_status not null default 'active',

  tax_code text,
  phone text,
  email extensions.citext,
  website text,
  representative text,
  billing_address text,
  payment_terms text,
  credit_days integer,
  credit_limit numeric(18, 2),
  bank_name text,
  bank_account_number text,
  bank_account_name text,
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

  constraint suppliers_code_not_blank
    check (length(trim(code)) > 0),

  constraint suppliers_name_not_blank
    check (length(trim(name)) > 0),

  constraint suppliers_credit_days_non_negative
    check (
      credit_days is null
      or credit_days >= 0
    ),

  constraint suppliers_credit_limit_non_negative
    check (
      credit_limit is null
      or credit_limit >= 0
    ),

  constraint suppliers_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.suppliers is
  'Suppliers, vendors and subcontractors used by procurement and project cost management.';

comment on column public.suppliers.supplier_type is
  'Classification of the supplier or subcontractor.';

comment on column public.suppliers.credit_days is
  'Allowed payment days for the supplier agreement.';

comment on column public.suppliers.credit_limit is
  'Optional credit line available to the supplier.';

alter table public.suppliers
  add constraint suppliers_id_organization_unique
  unique (id, organization_id);

create unique index suppliers_active_code_unique
  on public.suppliers (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create unique index suppliers_active_tax_code_unique
  on public.suppliers (
    organization_id,
    tax_code
  )
  where tax_code is not null
    and deleted_at is null;

create index suppliers_organization_idx
  on public.suppliers (organization_id)
  where deleted_at is null;

create index suppliers_status_idx
  on public.suppliers (
    organization_id,
    status
  )
  where deleted_at is null;

create index suppliers_type_idx
  on public.suppliers (
    organization_id,
    supplier_type
  )
  where deleted_at is null;

create index suppliers_name_search_idx
  on public.suppliers
  using gin (name gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- SUPPLIER CONTACTS
-- Contacts associated with one supplier.
-- ============================================================

create table public.supplier_contacts (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  supplier_id uuid not null,

  full_name text not null,
  job_title text,
  phone text,
  email extensions.citext,
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

  constraint supplier_contacts_full_name_not_blank
    check (length(trim(full_name)) > 0),

  constraint supplier_contacts_primary_is_active
    check (
      is_primary = false
      or is_active = true
    ),

  constraint supplier_contacts_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.supplier_contacts is
  'Contacts attached to suppliers and subcontractors.';

alter table public.supplier_contacts
  add constraint supplier_contacts_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

create unique index supplier_contacts_primary_contact_unique
  on public.supplier_contacts (supplier_id)
  where is_primary = true
    and is_active = true
    and deleted_at is null;

create index supplier_contacts_supplier_idx
  on public.supplier_contacts (
    organization_id,
    supplier_id
  )
  where deleted_at is null;

create index supplier_contacts_active_idx
  on public.supplier_contacts (
    organization_id,
    is_active
  )
  where deleted_at is null;

-- ============================================================
-- MATERIAL CATEGORIES
-- Hierarchical catalogue groups for materials and services.
-- ============================================================

create table public.material_categories (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  parent_id uuid,

  code text,
  name text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,

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

  constraint material_categories_name_not_blank
    check (length(trim(name)) > 0),

  constraint material_categories_sort_order_non_negative
    check (sort_order >= 0),

  constraint material_categories_no_self_parent
    check (
      parent_id is null
      or parent_id <> id
    ),

  constraint material_categories_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.material_categories is
  'Hierarchical categories for materials and related procurement catalog items.';

alter table public.material_categories
  add constraint material_categories_id_organization_unique
  unique (id, organization_id);

alter table public.material_categories
  add constraint material_categories_parent_same_organization_fk
  foreign key (
    parent_id,
    organization_id
  )
  references public.material_categories (
    id,
    organization_id
  )
  on delete restrict;

create unique index material_categories_active_name_unique
  on public.material_categories (
    organization_id,
    coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(name)
  )
  where is_active = true
    and deleted_at is null;

create unique index material_categories_active_code_unique
  on public.material_categories (
    organization_id,
    upper(code)
  )
  where code is not null
    and is_active = true
    and deleted_at is null;

create index material_categories_organization_idx
  on public.material_categories (organization_id)
  where deleted_at is null;

create index material_categories_parent_idx
  on public.material_categories (
    organization_id,
    parent_id,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- MATERIALS
-- Central material, product and service catalogue.
-- ============================================================

create table public.materials (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  material_category_id uuid,
  unit_id uuid,

  code text not null,
  sku text,
  barcode text,
  name text not null,
  description text,
  specification text,
  brand text,
  model text,
  image_url text,

  reference_sale_price numeric(18, 2) not null default 0,
  reference_cost_price numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  status public.material_status not null default 'active',

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

  constraint materials_code_not_blank
    check (length(trim(code)) > 0),

  constraint materials_name_not_blank
    check (length(trim(name)) > 0),

  constraint materials_reference_sale_price_non_negative
    check (reference_sale_price >= 0),

  constraint materials_reference_cost_price_non_negative
    check (reference_cost_price >= 0),

  constraint materials_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint materials_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.materials is
  'Central material, product and service catalogue for procurement and project planning.';

comment on column public.materials.reference_sale_price is
  'Reference sale price used in quotes and procurement planning.';

comment on column public.materials.reference_cost_price is
  'Reference cost price used in budgeting and margin analysis.';

alter table public.materials
  add constraint materials_id_organization_unique
  unique (id, organization_id);

alter table public.materials
  add constraint materials_category_same_organization_fk
  foreign key (
    material_category_id,
    organization_id
  )
  references public.material_categories (
    id,
    organization_id
  )
  on delete restrict;

alter table public.materials
  add constraint materials_unit_same_organization_fk
  foreign key (
    unit_id,
    organization_id
  )
  references public.units (
    id,
    organization_id
  )
  on delete restrict;

create unique index materials_active_code_unique
  on public.materials (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create unique index materials_active_sku_unique
  on public.materials (
    organization_id,
    sku
  )
  where sku is not null
    and deleted_at is null;

create unique index materials_active_barcode_unique
  on public.materials (
    organization_id,
    barcode
  )
  where barcode is not null
    and deleted_at is null;

create index materials_organization_idx
  on public.materials (organization_id)
  where deleted_at is null;

create index materials_category_idx
  on public.materials (
    organization_id,
    material_category_id
  )
  where material_category_id is not null
    and deleted_at is null;

create index materials_unit_idx
  on public.materials (
    organization_id,
    unit_id
  )
  where unit_id is not null
    and deleted_at is null;

create index materials_status_idx
  on public.materials (
    organization_id,
    status
  )
  where deleted_at is null;

create index materials_name_search_idx
  on public.materials
  using gin (name gin_trgm_ops)
  where deleted_at is null;

create index materials_code_search_idx
  on public.materials
  using gin (coalesce(code, '') gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- MATERIAL SUPPLIERS
-- Many-to-many supplier relationships for materials.
-- ============================================================

create table public.material_suppliers (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  material_id uuid not null,
  supplier_id uuid not null,

  supplier_product_code text,
  supplier_product_name text,
  lead_time_days integer,
  minimum_order_quantity numeric(18, 4),
  is_preferred boolean not null default false,
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

  constraint material_suppliers_lead_time_days_non_negative
    check (
      lead_time_days is null
      or lead_time_days >= 0
    ),

  constraint material_suppliers_minimum_order_quantity_non_negative
    check (
      minimum_order_quantity is null
      or minimum_order_quantity >= 0
    ),

  constraint material_suppliers_preferred_requires_active
    check (
      is_preferred = false
      or is_active = true
    ),

  constraint material_suppliers_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.material_suppliers is
  'Many-to-many relationship between materials and suppliers.';

alter table public.material_suppliers
  add constraint material_suppliers_material_same_organization_fk
  foreign key (
    material_id,
    organization_id
  )
  references public.materials (
    id,
    organization_id
  )
  on delete restrict;

alter table public.material_suppliers
  add constraint material_suppliers_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.material_suppliers
  add constraint material_suppliers_id_material_supplier_organization_unique
  unique (
    id,
    material_id,
    supplier_id,
    organization_id
  );

create unique index material_suppliers_active_material_supplier_unique
  on public.material_suppliers (
    material_id,
    supplier_id
  )
  where is_active = true
    and deleted_at is null;

create unique index material_suppliers_active_preferred_unique
  on public.material_suppliers (material_id)
  where is_preferred = true
    and is_active = true
    and deleted_at is null;

create index material_suppliers_material_idx
  on public.material_suppliers (
    organization_id,
    material_id,
    is_active
  )
  where deleted_at is null;

create index material_suppliers_supplier_idx
  on public.material_suppliers (
    organization_id,
    supplier_id,
    is_active
  )
  where deleted_at is null;

-- ============================================================
-- MATERIAL PRICES
-- Historical supplier pricing for materials.
-- ============================================================

create table public.material_prices (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  material_supplier_id uuid not null,
  material_id uuid not null,
  supplier_id uuid not null,
  unit_id uuid,

  price numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  effective_from date not null default current_date,
  effective_until date,
  currency_code text not null default 'VND',
  minimum_quantity numeric(18, 4),
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

  constraint material_prices_price_non_negative
    check (price >= 0),

  constraint material_prices_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint material_prices_effective_until_valid
    check (
      effective_until is null
      or effective_until >= effective_from
    ),

  constraint material_prices_currency_code_format
    check (currency_code ~ '^[A-Z]{3}$'),

  constraint material_prices_minimum_quantity_non_negative
    check (
      minimum_quantity is null
      or minimum_quantity >= 0
    ),

  constraint material_prices_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.material_prices is
  'Historical supplier pricing for materials without overwriting earlier rates.';

alter table public.material_prices
  add constraint material_prices_id_organization_unique
  unique (id, organization_id);

alter table public.material_prices
  add constraint material_prices_material_supplier_same_org_fk
  foreign key (
    material_supplier_id,
    material_id,
    supplier_id,
    organization_id
  )
  references public.material_suppliers (
    id,
    material_id,
    supplier_id,
    organization_id
  )
  on delete restrict;

alter table public.material_prices
  add constraint material_prices_material_same_organization_fk
  foreign key (
    material_id,
    organization_id
  )
  references public.materials (
    id,
    organization_id
  )
  on delete restrict;

alter table public.material_prices
  add constraint material_prices_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.material_prices
  add constraint material_prices_unit_same_organization_fk
  foreign key (
    unit_id,
    organization_id
  )
  references public.units (
    id,
    organization_id
  )
  on delete restrict;

create index material_prices_material_idx
  on public.material_prices (
    organization_id,
    material_id,
    effective_from desc
  )
  where deleted_at is null;

create index material_prices_supplier_idx
  on public.material_prices (
    organization_id,
    supplier_id,
    effective_from desc
  )
  where deleted_at is null;

create index material_prices_material_supplier_idx
  on public.material_prices (
    organization_id,
    material_supplier_id,
    effective_from desc
  )
  where deleted_at is null;

create index material_prices_effective_dates_idx
  on public.material_prices (
    organization_id,
    effective_from,
    effective_until
  )
  where deleted_at is null;

-- ============================================================
-- WORK CATEGORIES
-- Hierarchical work and service breakdown categories.
-- ============================================================

create table public.work_categories (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  parent_id uuid,

  code text not null,
  name text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,

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

  constraint work_categories_code_not_blank
    check (length(trim(code)) > 0),

  constraint work_categories_name_not_blank
    check (length(trim(name)) > 0),

  constraint work_categories_sort_order_non_negative
    check (sort_order >= 0),

  constraint work_categories_no_self_parent
    check (
      parent_id is null
      or parent_id <> id
    ),

  constraint work_categories_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.work_categories is
  'Hierarchical work categories for project budgets and construction scopes.';

alter table public.work_categories
  add constraint work_categories_id_organization_unique
  unique (id, organization_id);

alter table public.work_categories
  add constraint work_categories_parent_same_organization_fk
  foreign key (
    parent_id,
    organization_id
  )
  references public.work_categories (
    id,
    organization_id
  )
  on delete restrict;

create unique index work_categories_active_code_unique
  on public.work_categories (
    organization_id,
    upper(code)
  )
  where is_active = true
    and deleted_at is null;

create unique index work_categories_active_sibling_name_unique
  on public.work_categories (
    organization_id,
    coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(name)
  )
  where is_active = true
    and deleted_at is null;

create index work_categories_organization_idx
  on public.work_categories (organization_id)
  where deleted_at is null;

create index work_categories_parent_idx
  on public.work_categories (
    organization_id,
    parent_id,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- PROJECT BUDGETS
-- Versioned project budgets and estimates.
-- ============================================================

create table public.project_budgets (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,

  code text not null,
  title text not null,
  version_number integer not null,
  status public.budget_status not null default 'draft',

  subtotal numeric(18, 2) not null default 0,
  contingency_amount numeric(18, 2) not null default 0,
  discount_amount numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,
  internal_cost numeric(18, 2) not null default 0,
  expected_profit numeric(18, 2) not null default 0,
  expected_margin_percent numeric(7, 4),
  approved_at timestamptz,
  approved_by uuid
    references auth.users(id)
    on delete set null,
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

  constraint project_budgets_code_not_blank
    check (length(trim(code)) > 0),

  constraint project_budgets_title_not_blank
    check (length(trim(title)) > 0),

  constraint project_budgets_version_positive
    check (version_number > 0),

  constraint project_budgets_subtotal_non_negative
    check (subtotal >= 0),

  constraint project_budgets_contingency_non_negative
    check (contingency_amount >= 0),

  constraint project_budgets_discount_non_negative
    check (discount_amount >= 0),

  constraint project_budgets_discount_not_above_subtotal
    check (discount_amount <= subtotal + contingency_amount),

  constraint project_budgets_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint project_budgets_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint project_budgets_total_non_negative
    check (total_amount >= 0),

  constraint project_budgets_internal_cost_non_negative
    check (internal_cost >= 0),

  constraint project_budgets_expected_profit_non_negative
    check (expected_profit >= 0),

  constraint project_budgets_expected_margin_valid
    check (
      expected_margin_percent is null
      or expected_margin_percent between 0 and 100
    ),

  constraint project_budgets_total_matches_formula
    check (total_amount = subtotal + contingency_amount - discount_amount + tax_amount),

  constraint project_budgets_approved_at_required
    check (
      status <> 'approved'
      or approved_at is not null
    ),

  constraint project_budgets_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.project_budgets is
  'Versioned project budgets and estimates belonging to a project.';

alter table public.project_budgets
  add constraint project_budgets_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budgets
  add constraint project_budgets_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

create unique index project_budgets_active_code_unique
  on public.project_budgets (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create unique index project_budgets_active_version_unique
  on public.project_budgets (
    project_id,
    version_number
  )
  where deleted_at is null;

create unique index project_budgets_one_approved_unique
  on public.project_budgets (project_id)
  where status = 'approved'
    and deleted_at is null;

create index project_budgets_project_idx
  on public.project_budgets (
    organization_id,
    project_id,
    version_number desc
  )
  where deleted_at is null;

create index project_budgets_status_idx
  on public.project_budgets (
    organization_id,
    status
  )
  where deleted_at is null;

create index project_budgets_approved_idx
  on public.project_budgets (
    organization_id,
    approved_at desc
  )
  where approved_at is not null
    and deleted_at is null;

-- ============================================================
-- PROJECT BUDGET ITEMS
-- Detailed estimate lines with optional parent-child structure.
-- ============================================================

create table public.project_budget_items (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_budget_id uuid not null,
  project_id uuid not null,
  parent_item_id uuid,

  work_category_id uuid,
  material_id uuid,
  material_supplier_id uuid,
  supplier_id uuid,
  unit_id uuid,

  item_type public.budget_item_type not null default 'other',
  code text,
  description text not null,
  quantity numeric(18, 4) not null default 0,
  unit_price numeric(18, 2) not null default 0,
  material_cost numeric(18, 2) not null default 0,
  labour_cost numeric(18, 2) not null default 0,
  other_cost numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,
  sort_order integer not null default 0,
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

  constraint project_budget_items_description_not_blank
    check (length(trim(description)) > 0),

  constraint project_budget_items_quantity_non_negative
    check (quantity >= 0),

  constraint project_budget_items_unit_price_non_negative
    check (unit_price >= 0),

  constraint project_budget_items_material_cost_non_negative
    check (material_cost >= 0),

  constraint project_budget_items_labour_cost_non_negative
    check (labour_cost >= 0),

  constraint project_budget_items_other_cost_non_negative
    check (other_cost >= 0),

  constraint project_budget_items_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint project_budget_items_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint project_budget_items_total_non_negative
    check (total_amount >= 0),

  constraint project_budget_items_sort_order_non_negative
    check (sort_order >= 0),

  constraint project_budget_items_material_supplier_fields_required
    check (
      material_supplier_id is null
      or (
        material_id is not null
        and supplier_id is not null
      )
    ),

  constraint project_budget_items_group_quantity_rule
    check (
      item_type = 'group'
      or quantity > 0
    ),

  constraint project_budget_items_no_self_parent
    check (
      parent_item_id is null
      or parent_item_id <> id
    ),

  constraint project_budget_items_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.project_budget_items is
  'Detailed project budget and estimate lines with optional grouping.';

alter table public.project_budget_items
  add constraint project_budget_items_budget_same_project_fk
  foreign key (
    project_budget_id,
    project_id,
    organization_id
  )
  references public.project_budgets (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_work_category_same_organization_fk
  foreign key (
    work_category_id,
    organization_id
  )
  references public.work_categories (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_material_same_organization_fk
  foreign key (
    material_id,
    organization_id
  )
  references public.materials (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_material_supplier_same_org_fk
  foreign key (
    material_supplier_id,
    material_id,
    supplier_id,
    organization_id
  )
  references public.material_suppliers (
    id,
    material_id,
    supplier_id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_unit_same_organization_fk
  foreign key (
    unit_id,
    organization_id
  )
  references public.units (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_budget_items
  add constraint project_budget_items_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

alter table public.project_budget_items
  add constraint project_budget_items_id_budget_project_organization_unique
  unique (
    id,
    project_budget_id,
    project_id,
    organization_id
  );

alter table public.project_budget_items
  add constraint project_budget_items_parent_same_budget_fk
  foreign key (
    parent_item_id,
    project_budget_id,
    project_id,
    organization_id
  )
  references public.project_budget_items (
    id,
    project_budget_id,
    project_id,
    organization_id
  )
  on delete restrict;

create index project_budget_items_budget_idx
  on public.project_budget_items (
    organization_id,
    project_budget_id,
    sort_order
  )
  where deleted_at is null;

create index project_budget_items_project_idx
  on public.project_budget_items (
    organization_id,
    project_id
  )
  where deleted_at is null;

create index project_budget_items_parent_idx
  on public.project_budget_items (
    organization_id,
    parent_item_id
  )
  where parent_item_id is not null
    and deleted_at is null;

create index project_budget_items_category_idx
  on public.project_budget_items (
    organization_id,
    work_category_id
  )
  where work_category_id is not null
    and deleted_at is null;

create index project_budget_items_type_idx
  on public.project_budget_items (
    organization_id,
    item_type
  )
  where deleted_at is null;

-- ============================================================
-- PURCHASE ORDERS
-- Purchase orders issued to suppliers.
-- ============================================================

create table public.purchase_orders (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,
  supplier_id uuid not null,
  project_budget_id uuid,

  code text not null,
  title text not null,
  status public.purchase_order_status not null default 'draft',

  order_date date not null default current_date,
  expected_delivery_date date,
  actual_delivery_date date,

  subtotal numeric(18, 2) not null default 0,
  discount_amount numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,

  payment_terms text,
  delivery_address text,
  approved_at timestamptz,
  approved_by uuid
    references auth.users(id)
    on delete set null,
  cancelled_at timestamptz,
  cancellation_reason text,
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

  constraint purchase_orders_code_not_blank
    check (length(trim(code)) > 0),

  constraint purchase_orders_title_not_blank
    check (length(trim(title)) > 0),

  constraint purchase_orders_subtotal_non_negative
    check (subtotal >= 0),

  constraint purchase_orders_discount_non_negative
    check (discount_amount >= 0),

  constraint purchase_orders_discount_not_above_subtotal
    check (discount_amount <= subtotal),

  constraint purchase_orders_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint purchase_orders_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint purchase_orders_total_non_negative
    check (total_amount >= 0),

  constraint purchase_orders_total_matches_formula
    check (total_amount = subtotal - discount_amount + tax_amount),

  constraint purchase_orders_delivery_dates_valid
    check (
      expected_delivery_date is null
      or order_date is null
      or expected_delivery_date >= order_date
    ),

  constraint purchase_orders_actual_delivery_dates_valid
    check (
      actual_delivery_date is null
      or order_date is null
      or actual_delivery_date >= order_date
    ),

  constraint purchase_orders_approved_at_required
    check (
      status <> 'approved'
      or approved_at is not null
    ),

  constraint purchase_orders_cancelled_at_required
    check (
      status <> 'cancelled'
      or (
        cancelled_at is not null
        and length(trim(cancellation_reason)) > 0
      )
    ),

  constraint purchase_orders_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.purchase_orders is
  'Purchase orders issued to suppliers for projects.';

alter table public.purchase_orders
  add constraint purchase_orders_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_orders
  add constraint purchase_orders_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_orders
  add constraint purchase_orders_budget_same_project_fk
  foreign key (
    project_budget_id,
    project_id,
    organization_id
  )
  references public.project_budgets (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_orders
  add constraint purchase_orders_id_project_organization_unique
  unique (
    id,
    project_id,
    organization_id
  );

alter table public.purchase_orders
  add constraint purchase_orders_id_project_supplier_organization_unique
  unique (
    id,
    project_id,
    supplier_id,
    organization_id
  );

create unique index purchase_orders_active_code_unique
  on public.purchase_orders (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index purchase_orders_project_idx
  on public.purchase_orders (
    organization_id,
    project_id,
    status
  )
  where deleted_at is null;

create index purchase_orders_supplier_idx
  on public.purchase_orders (
    organization_id,
    supplier_id,
    status
  )
  where deleted_at is null;

create index purchase_orders_order_date_idx
  on public.purchase_orders (
    organization_id,
    order_date desc
  )
  where deleted_at is null;

create index purchase_orders_expected_delivery_idx
  on public.purchase_orders (
    organization_id,
    expected_delivery_date
  )
  where expected_delivery_date is not null
    and deleted_at is null;

create index purchase_orders_title_search_idx
  on public.purchase_orders
  using gin (title gin_trgm_ops)
  where deleted_at is null;

-- ============================================================
-- PURCHASE ORDER ITEMS
-- Detailed lines contained in purchase orders.
-- ============================================================

create table public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  purchase_order_id uuid not null,
  project_id uuid not null,
  supplier_id uuid not null,
  material_id uuid,
  material_supplier_id uuid,
  unit_id uuid,
  project_budget_item_id uuid,

  description text not null,
  quantity numeric(18, 4) not null default 1,
  unit_price numeric(18, 2) not null default 0,
  discount_amount numeric(18, 2) not null default 0,
  tax_rate numeric(7, 4) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,
  received_quantity numeric(18, 4) not null default 0,
  over_receipt_reason text,
  sort_order integer not null default 0,
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

  constraint purchase_order_items_description_not_blank
    check (length(trim(description)) > 0),

  constraint purchase_order_items_quantity_non_negative
    check (quantity > 0),

  constraint purchase_order_items_unit_price_non_negative
    check (unit_price >= 0),

  constraint purchase_order_items_discount_non_negative
    check (discount_amount >= 0),

  constraint purchase_order_items_tax_rate_valid
    check (tax_rate between 0 and 100),

  constraint purchase_order_items_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint purchase_order_items_total_non_negative
    check (total_amount >= 0),

  constraint purchase_order_items_received_quantity_non_negative
    check (received_quantity >= 0),

  constraint purchase_order_items_sort_order_non_negative
    check (sort_order >= 0),

  constraint purchase_order_items_material_supplier_fields_required
    check (
      material_supplier_id is null
      or (
        material_id is not null
        and supplier_id is not null
      )
    ),

  constraint purchase_order_items_discount_not_above_line_total
    check (discount_amount <= quantity * unit_price),

  constraint purchase_order_items_total_matches_formula
    check (total_amount = (quantity * unit_price) - discount_amount + tax_amount),

  constraint purchase_order_items_received_not_above_ordered
    check (
      received_quantity <= quantity
      or (
        over_receipt_reason is not null
        and length(trim(over_receipt_reason)) > 0
      )
    ),

  constraint purchase_order_items_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.purchase_order_items is
  'Detailed line items contained in purchase orders.';

alter table public.purchase_order_items
  add constraint purchase_order_items_order_same_organization_fk
  foreign key (
    purchase_order_id,
    project_id,
    organization_id
  )
  references public.purchase_orders (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_material_same_organization_fk
  foreign key (
    material_id,
    organization_id
  )
  references public.materials (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_material_supplier_same_org_fk
  foreign key (
    material_supplier_id,
    material_id,
    supplier_id,
    organization_id
  )
  references public.material_suppliers (
    id,
    material_id,
    supplier_id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_unit_same_organization_fk
  foreign key (
    unit_id,
    organization_id
  )
  references public.units (
    id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_budget_item_same_project_fk
  foreign key (
    project_budget_item_id,
    project_id,
    organization_id
  )
  references public.project_budget_items (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

alter table public.purchase_order_items
  add constraint purchase_order_items_id_purchase_order_project_org_unique
  unique (
    id,
    purchase_order_id,
    project_id,
    organization_id
  );

create index purchase_order_items_order_idx
  on public.purchase_order_items (
    organization_id,
    purchase_order_id,
    sort_order
  )
  where deleted_at is null;

create index purchase_order_items_project_idx
  on public.purchase_order_items (
    organization_id,
    project_id
  )
  where deleted_at is null;

create index purchase_order_items_material_idx
  on public.purchase_order_items (
    organization_id,
    material_id
  )
  where material_id is not null
    and deleted_at is null;

create index purchase_order_items_supplier_idx
  on public.purchase_order_items (
    organization_id,
    supplier_id,
    sort_order
  )
  where deleted_at is null;

create index purchase_order_items_budget_item_idx
  on public.purchase_order_items (
    organization_id,
    project_budget_item_id
  )
  where project_budget_item_id is not null
    and deleted_at is null;

-- ============================================================
-- PROJECT EXPENSES
-- Actual project expenses incurred during delivery.
-- ============================================================

create table public.project_expenses (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  project_id uuid not null,
  supplier_id uuid,
  purchase_order_id uuid,
  purchase_order_item_id uuid,
  project_budget_item_id uuid,

  code text not null,
  expense_date date not null default current_date,
  category public.expense_type not null default 'other',
  description text not null,
  amount_before_tax numeric(18, 2) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,
  payment_status public.expense_status not null default 'pending',
  payment_method public.payment_method,
  paid_at timestamptz,
  paid_by uuid
    references auth.users(id)
    on delete set null,
  reference_code text,
  receipt_number text,
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

  constraint project_expenses_code_not_blank
    check (length(trim(code)) > 0),

  constraint project_expenses_description_not_blank
    check (length(trim(description)) > 0),

  constraint project_expenses_amount_non_negative
    check (amount_before_tax >= 0),

  constraint project_expenses_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint project_expenses_total_non_negative
    check (total_amount >= 0),

  constraint project_expenses_total_matches_formula
    check (total_amount = amount_before_tax + tax_amount),

  constraint project_expenses_purchase_order_supplier_required
    check (
      purchase_order_id is null
      or supplier_id is not null
    ),

  constraint project_expenses_purchase_order_item_order_required
    check (
      purchase_order_item_id is null
      or purchase_order_id is not null
    ),

  constraint project_expenses_purchase_order_item_supplier_required
    check (
      purchase_order_item_id is null
      or supplier_id is not null
    ),

  constraint project_expenses_payment_audit_paid_fields_required
    check (
      payment_status <> 'paid'
      or (
        paid_at is not null
        and paid_by is not null
      )
    ),

  constraint project_expenses_payment_audit_unpaid_fields_cleared
    check (
      payment_status = 'paid'
      or (
        paid_at is null
        and paid_by is null
      )
    ),

  constraint project_expenses_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.project_expenses is
  'Actual project expenses incurred during delivery and procurement.';

alter table public.project_expenses
  add constraint project_expenses_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_expenses
  add constraint project_expenses_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.project_expenses
  add constraint project_expenses_purchase_order_same_project_supplier_fk
  foreign key (
    purchase_order_id,
    project_id,
    supplier_id,
    organization_id
  )
  references public.purchase_orders (
    id,
    project_id,
    supplier_id,
    organization_id
  )
  on delete restrict;

alter table public.project_expenses
  add constraint project_expenses_purchase_order_item_same_order_fk
  foreign key (
    purchase_order_item_id,
    purchase_order_id,
    project_id,
    organization_id
  )
  references public.purchase_order_items (
    id,
    purchase_order_id,
    project_id,
    organization_id
  )
  on delete restrict;

alter table public.project_expenses
  add constraint project_expenses_budget_item_same_project_fk
  foreign key (
    project_budget_item_id,
    project_id,
    organization_id
  )
  references public.project_budget_items (
    id,
    project_id,
    organization_id
  )
  on delete restrict;

create unique index project_expenses_active_code_unique
  on public.project_expenses (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index project_expenses_project_idx
  on public.project_expenses (
    organization_id,
    project_id,
    expense_date desc
  )
  where deleted_at is null;

create index project_expenses_supplier_idx
  on public.project_expenses (
    organization_id,
    supplier_id,
    payment_status
  )
  where supplier_id is not null
    and deleted_at is null;

create index project_expenses_purchase_order_idx
  on public.project_expenses (
    organization_id,
    purchase_order_id,
    expense_date desc
  )
  where purchase_order_id is not null
    and deleted_at is null;

create index project_expenses_status_idx
  on public.project_expenses (
    organization_id,
    payment_status
  )
  where deleted_at is null;

create index project_expenses_date_idx
  on public.project_expenses (
    organization_id,
    expense_date desc
  )
  where deleted_at is null;

create index project_expenses_reference_code_idx
  on public.project_expenses (
    organization_id,
    reference_code
  )
  where reference_code is not null
    and deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
-- Policies will be added in a later migration.
-- ============================================================

alter table public.units enable row level security;
alter table public.suppliers enable row level security;
alter table public.supplier_contacts enable row level security;
alter table public.material_categories enable row level security;
alter table public.materials enable row level security;
alter table public.material_suppliers enable row level security;
alter table public.material_prices enable row level security;
alter table public.work_categories enable row level security;
alter table public.project_budgets enable row level security;
alter table public.project_budget_items enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_order_items enable row level security;
alter table public.project_expenses enable row level security;

commit;
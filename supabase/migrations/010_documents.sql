-- ============================================================
-- VOID OS
-- Migration: 010_documents.sql
-- Purpose:
--   Create the document, file attachment and document-versioning foundation.
--
-- Tables:
--   1. document_categories
--   2. documents
--   3. document_versions
--   4. document_links
--   5. document_access_grants
--
-- Notes:
--   - Files are stored in Supabase Storage.
--   - PostgreSQL stores metadata, classification, version history and audit data only.
-- ============================================================

begin;

-- ============================================================
-- ENUMS
-- Guarded creation for document-specific enum types.
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'document_status'
  ) then
    create type public.document_status as enum (
      'draft',
      'active',
      'archived',
      'superseded',
      'cancelled'
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
      and t.typname = 'document_visibility'
  ) then
    create type public.document_visibility as enum (
      'internal',
      'client',
      'supplier',
      'public'
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
      and t.typname = 'document_source'
  ) then
    create type public.document_source as enum (
      'uploaded',
      'generated',
      'external_link'
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
      and t.typname = 'document_version_status'
  ) then
    create type public.document_version_status as enum (
      'draft',
      'current',
      'superseded',
      'rejected'
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
      and t.typname = 'attachment_role'
  ) then
    create type public.attachment_role as enum (
      'primary',
      'supporting',
      'receipt',
      'invoice',
      'contract',
      'drawing',
      'photo',
      'report',
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
      and t.typname = 'document_access_level'
  ) then
    create type public.document_access_level as enum (
      'view',
      'download',
      'edit',
      'manage'
    );
  end if;
end
$$;

-- ============================================================
-- PREPARE EXISTING TABLES FOR COMPOSITE FOREIGN KEYS
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'customers'
      and c.conname = 'customers_id_organization_unique'
  ) then
    alter table public.customers
      add constraint customers_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'suppliers'
      and c.conname = 'suppliers_id_organization_unique'
  ) then
    alter table public.suppliers
      add constraint suppliers_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'projects'
      and c.conname = 'projects_id_organization_unique'
  ) then
    alter table public.projects
      add constraint projects_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'quotations'
      and c.conname = 'quotations_id_organization_unique'
  ) then
    alter table public.quotations
      add constraint quotations_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'contracts'
      and c.conname = 'contracts_id_organization_unique'
  ) then
    alter table public.contracts
      add constraint contracts_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'payments'
      and c.conname = 'payments_id_organization_unique'
  ) then
    alter table public.payments
      add constraint payments_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'purchase_orders'
      and c.conname = 'purchase_orders_id_organization_unique'
  ) then
    alter table public.purchase_orders
      add constraint purchase_orders_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'project_expenses'
      and c.conname = 'project_expenses_id_organization_unique'
  ) then
    alter table public.project_expenses
      add constraint project_expenses_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'office_expenses'
      and c.conname = 'office_expenses_id_organization_unique'
  ) then
    alter table public.office_expenses
      add constraint office_expenses_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'financial_transactions'
      and c.conname = 'financial_transactions_id_organization_unique'
  ) then
    alter table public.financial_transactions
      add constraint financial_transactions_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'organization_members'
      and c.conname = 'organization_members_user_id_organization_unique'
  ) then
    alter table public.organization_members
      add constraint organization_members_user_id_organization_unique
      unique (user_id, organization_id);
  end if;
end
$$;

-- ============================================================
-- 1. DOCUMENT CATEGORIES
-- Organization-defined classification for documents.
-- ============================================================

create table public.document_categories (
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

  constraint document_categories_code_not_blank
    check (length(trim(code)) > 0),

  constraint document_categories_name_not_blank
    check (length(trim(name)) > 0),

  constraint document_categories_sort_order_non_negative
    check (sort_order >= 0),

  constraint document_categories_no_self_parent
    check (
      parent_id is null
      or parent_id <> id
    ),

  constraint document_categories_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.document_categories is
  'Organization-defined classification hierarchy for documents and related files.';

alter table public.document_categories
  add constraint document_categories_id_organization_unique
  unique (id, organization_id);

alter table public.document_categories
  add constraint document_categories_parent_same_organization_fk
  foreign key (
    parent_id,
    organization_id
  )
  references public.document_categories (
    id,
    organization_id
  )
  on delete restrict;

create unique index document_categories_active_code_unique
  on public.document_categories (
    organization_id,
    upper(code)
  )
  where is_active = true
    and deleted_at is null;

create unique index document_categories_active_sibling_name_unique
  on public.document_categories (
    organization_id,
    coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(name)
  )
  where is_active = true
    and deleted_at is null;

create index document_categories_organization_idx
  on public.document_categories (organization_id)
  where deleted_at is null;

create index document_categories_hierarchy_idx
  on public.document_categories (
    organization_id,
    parent_id,
    sort_order
  )
  where deleted_at is null;

create index document_categories_active_list_idx
  on public.document_categories (
    organization_id,
    is_active,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- 2. DOCUMENTS
-- One logical document independent from its file versions.
-- ============================================================

create table public.documents (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  document_category_id uuid,
  code text not null,
  title text not null,
  description text,
  status public.document_status not null default 'draft',
  visibility public.document_visibility not null default 'internal',
  source public.document_source not null default 'uploaded',
  external_url text,
  current_version_id uuid,
  effective_date date,
  expiry_date date,
  issued_at timestamptz,
  issued_by uuid
    references auth.users(id)
    on delete set null,
  archived_at timestamptz,
  archived_by uuid
    references auth.users(id)
    on delete set null,
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

  constraint documents_code_not_blank
    check (length(trim(code)) > 0),

  constraint documents_title_not_blank
    check (length(trim(title)) > 0),

  constraint documents_external_url_rule
    check (
      (
        source = 'external_link'
        and external_url is not null
        and external_url ~ '^https?://'
      )
      or (
        source <> 'external_link'
        and external_url is null
      )
    ),

  constraint documents_expiry_after_effective
    check (
      expiry_date is null
      or effective_date is null
      or expiry_date >= effective_date
    ),

  constraint documents_archived_fields_required
    check (
      status <> 'archived'
      or (
        archived_at is not null
        and archived_by is not null
      )
    ),

  constraint documents_unarchived_fields_cleared
    check (
      status = 'archived'
      or (
        archived_at is null
        and archived_by is null
      )
    ),

  constraint documents_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.documents is
  'One logical document record independent from its file versions and storage locations.';

comment on column public.documents.external_url is
  'Used only when the document source is an external link.';

alter table public.documents
  add constraint documents_id_organization_unique
  unique (id, organization_id);

alter table public.documents
  add constraint documents_category_same_organization_fk
  foreign key (
    document_category_id,
    organization_id
  )
  references public.document_categories (
    id,
    organization_id
  )
  on delete restrict;

create unique index documents_active_code_unique
  on public.documents (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index documents_category_idx
  on public.documents (
    organization_id,
    document_category_id,
    status
  )
  where deleted_at is null;

create index documents_status_idx
  on public.documents (
    organization_id,
    status
  )
  where deleted_at is null;

create index documents_visibility_idx
  on public.documents (
    organization_id,
    visibility
  )
  where deleted_at is null;

create index documents_source_idx
  on public.documents (
    organization_id,
    source
  )
  where deleted_at is null;

create index documents_effective_date_idx
  on public.documents (
    organization_id,
    effective_date
  )
  where effective_date is not null
    and deleted_at is null;

create index documents_expiry_date_idx
  on public.documents (
    organization_id,
    expiry_date
  )
  where expiry_date is not null
    and deleted_at is null;

-- ============================================================
-- 3. DOCUMENT VERSIONS
-- Immutable metadata for each uploaded or generated file version.
-- ============================================================

create table public.document_versions (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  document_id uuid not null,
  version_number integer not null,
  version_label text,
  status public.document_version_status not null default 'draft',
  file_name text not null,
  original_file_name text,
  storage_bucket text not null,
  storage_path text not null,
  mime_type text,
  file_extension text,
  file_size_bytes bigint not null default 0,
  checksum_sha256 text,
  page_count integer,
  width_px integer,
  height_px integer,
  uploaded_at timestamptz,
  uploaded_by uuid
    references auth.users(id)
    on delete set null,
  generated_by uuid
    references auth.users(id)
    on delete set null,
  change_summary text,
  rejection_reason text,
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

  constraint document_versions_version_number_positive
    check (version_number > 0),

  constraint document_versions_file_name_not_blank
    check (length(trim(file_name)) > 0),

  constraint document_versions_storage_bucket_not_blank
    check (length(trim(storage_bucket)) > 0),

  constraint document_versions_storage_path_not_blank
    check (length(trim(storage_path)) > 0),

  constraint document_versions_storage_path_not_absolute
    check (storage_path !~ '^/'),

  constraint document_versions_file_size_non_negative
    check (file_size_bytes >= 0),

  constraint document_versions_page_count_positive
    check (
      page_count is null
      or page_count > 0
    ),

  constraint document_versions_width_positive
    check (
      width_px is null
      or width_px > 0
    ),

  constraint document_versions_height_positive
    check (
      height_px is null
      or height_px > 0
    ),

  constraint document_versions_checksum_format
    check (
      checksum_sha256 is null
      or checksum_sha256 ~ '^[a-f0-9]{64}$'
    ),

  constraint document_versions_file_extension_format
    check (
      file_extension is null
      or (
        file_extension = lower(file_extension)
        and file_extension !~ '^\.'
        and file_extension ~ '^[a-z0-9]+$'
      )
    ),

  constraint document_versions_rejection_reason_rule
    check (
      status <> 'rejected'
      or (
        rejection_reason is not null
        and length(trim(rejection_reason)) > 0
      )
    ),

  constraint document_versions_rejection_reason_cleared
    check (
      status = 'rejected'
      or rejection_reason is null
    ),

  constraint document_versions_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.document_versions is
  'Immutable file-version metadata linking to Supabase Storage objects.';

comment on column public.document_versions.uploaded_at is
  'Provenance will later be validated by application services or RPC functions; uploaded source should normally populate uploaded_at and uploaded_by, while generated source should normally populate generated_by.';

comment on column public.document_versions.storage_bucket is
  'Supabase Storage bucket name where the file object is stored.';

comment on column public.document_versions.storage_path is
  'Storage object path inside the bucket, such as organization_id/documents/document_id/version_number/file_name.';

alter table public.document_versions
  add constraint document_versions_id_organization_unique
  unique (id, organization_id);

alter table public.document_versions
  add constraint document_versions_document_same_organization_fk
  foreign key (
    document_id,
    organization_id
  )
  references public.documents (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_versions
  add constraint document_versions_id_document_organization_unique
  unique (
    id,
    document_id,
    organization_id
  );

create unique index document_versions_active_document_version_unique
  on public.document_versions (
    document_id,
    version_number
  )
  where deleted_at is null;

create unique index document_versions_current_version_unique
  on public.document_versions (document_id)
  where status = 'current'
    and deleted_at is null;

create unique index document_versions_storage_path_unique
  on public.document_versions (
    organization_id,
    storage_bucket,
    storage_path
  )
  where deleted_at is null;

create index document_versions_document_idx
  on public.document_versions (
    organization_id,
    document_id,
    version_number desc
  )
  where deleted_at is null;

create index document_versions_status_idx
  on public.document_versions (
    organization_id,
    status,
    uploaded_at desc
  )
  where deleted_at is null;

create index document_versions_storage_idx
  on public.document_versions (
    organization_id,
    storage_bucket,
    storage_path
  )
  where deleted_at is null;

create index document_versions_checksum_idx
  on public.document_versions (
    organization_id,
    checksum_sha256
  )
  where checksum_sha256 is not null
    and deleted_at is null;

create index document_versions_upload_date_idx
  on public.document_versions (
    organization_id,
    uploaded_at desc
  )
  where uploaded_at is not null
    and deleted_at is null;

create index document_versions_mime_type_idx
  on public.document_versions (
    organization_id,
    mime_type
  )
  where mime_type is not null
    and deleted_at is null;

-- Application services or RPC functions must only assign current_version_id to a
-- document_version whose status is current. The existing unique partial index
-- ensures at most one current version per document; no trigger is added here.
alter table public.documents
  add constraint documents_current_version_same_document_fk
  foreign key (
    current_version_id,
    id,
    organization_id
  )
  references public.document_versions (
    id,
    document_id,
    organization_id
  )
  on delete restrict;

-- ============================================================
-- 4. DOCUMENT LINKS
-- Explicit links to existing VOID OS business records.
-- ============================================================

create table public.document_links (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  document_id uuid not null,
  attachment_role public.attachment_role not null default 'other',

  customer_id uuid,
  supplier_id uuid,
  project_id uuid,
  quotation_id uuid,
  contract_id uuid,
  payment_id uuid,
  purchase_order_id uuid,
  project_expense_id uuid,
  office_expense_id uuid,
  financial_transaction_id uuid,

  notes text,
  sort_order integer not null default 0,
  is_primary boolean not null default false,
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

  constraint document_links_sort_order_non_negative
    check (sort_order >= 0),

  constraint document_links_target_count_at_least_one
    check (
      (case when customer_id is null then 0 else 1 end)
      + (case when supplier_id is null then 0 else 1 end)
      + (case when project_id is null then 0 else 1 end)
      + (case when quotation_id is null then 0 else 1 end)
      + (case when contract_id is null then 0 else 1 end)
      + (case when payment_id is null then 0 else 1 end)
      + (case when purchase_order_id is null then 0 else 1 end)
      + (case when project_expense_id is null then 0 else 1 end)
      + (case when office_expense_id is null then 0 else 1 end)
      + (case when financial_transaction_id is null then 0 else 1 end) >= 1
    ),

  constraint document_links_target_count_at_most_one
    check (
      (case when customer_id is null then 0 else 1 end)
      + (case when supplier_id is null then 0 else 1 end)
      + (case when project_id is null then 0 else 1 end)
      + (case when quotation_id is null then 0 else 1 end)
      + (case when contract_id is null then 0 else 1 end)
      + (case when payment_id is null then 0 else 1 end)
      + (case when purchase_order_id is null then 0 else 1 end)
      + (case when project_expense_id is null then 0 else 1 end)
      + (case when office_expense_id is null then 0 else 1 end)
      + (case when financial_transaction_id is null then 0 else 1 end) <= 1
    ),

  constraint document_links_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.document_links is
  'Explicit links from a document to one business record in VOID OS.';

alter table public.document_links
  add constraint document_links_id_organization_unique
  unique (id, organization_id);

alter table public.document_links
  add constraint document_links_document_same_organization_fk
  foreign key (
    document_id,
    organization_id
  )
  references public.documents (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_customer_same_organization_fk
  foreign key (
    customer_id,
    organization_id
  )
  references public.customers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_project_same_organization_fk
  foreign key (
    project_id,
    organization_id
  )
  references public.projects (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_quotation_same_organization_fk
  foreign key (
    quotation_id,
    organization_id
  )
  references public.quotations (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_contract_same_organization_fk
  foreign key (
    contract_id,
    organization_id
  )
  references public.contracts (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_payment_same_organization_fk
  foreign key (
    payment_id,
    organization_id
  )
  references public.payments (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_purchase_order_same_organization_fk
  foreign key (
    purchase_order_id,
    organization_id
  )
  references public.purchase_orders (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_project_expense_same_organization_fk
  foreign key (
    project_expense_id,
    organization_id
  )
  references public.project_expenses (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_office_expense_same_organization_fk
  foreign key (
    office_expense_id,
    organization_id
  )
  references public.office_expenses (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_links
  add constraint document_links_financial_transaction_same_organization_fk
  foreign key (
    financial_transaction_id,
    organization_id
  )
  references public.financial_transactions (
    id,
    organization_id
  )
  on delete restrict;

create unique index document_links_active_document_target_role_unique
  on public.document_links (
    document_id,
    customer_id,
    attachment_role
  )
  where customer_id is not null
    and deleted_at is null;

create unique index document_links_active_document_supplier_target_role_unique
  on public.document_links (
    document_id,
    supplier_id,
    attachment_role
  )
  where supplier_id is not null
    and deleted_at is null;

create unique index document_links_active_document_project_target_role_unique
  on public.document_links (
    document_id,
    project_id,
    attachment_role
  )
  where project_id is not null
    and deleted_at is null;

create unique index document_links_active_document_quotation_target_role_unique
  on public.document_links (
    document_id,
    quotation_id,
    attachment_role
  )
  where quotation_id is not null
    and deleted_at is null;

create unique index document_links_active_document_contract_target_role_unique
  on public.document_links (
    document_id,
    contract_id,
    attachment_role
  )
  where contract_id is not null
    and deleted_at is null;

create unique index document_links_active_document_payment_target_role_unique
  on public.document_links (
    document_id,
    payment_id,
    attachment_role
  )
  where payment_id is not null
    and deleted_at is null;

create unique index document_links_active_document_purchase_order_target_role_unique
  on public.document_links (
    document_id,
    purchase_order_id,
    attachment_role
  )
  where purchase_order_id is not null
    and deleted_at is null;

create unique index document_links_active_document_project_expense_target_role_unique
  on public.document_links (
    document_id,
    project_expense_id,
    attachment_role
  )
  where project_expense_id is not null
    and deleted_at is null;

create unique index document_links_active_document_office_expense_target_role_unique
  on public.document_links (
    document_id,
    office_expense_id,
    attachment_role
  )
  where office_expense_id is not null
    and deleted_at is null;

create unique index document_links_active_document_financial_transaction_target_role_unique
  on public.document_links (
    document_id,
    financial_transaction_id,
    attachment_role
  )
  where financial_transaction_id is not null
    and deleted_at is null;

create unique index document_links_active_primary_customer_role_unique
  on public.document_links (customer_id, attachment_role)
  where customer_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_supplier_role_unique
  on public.document_links (supplier_id, attachment_role)
  where supplier_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_project_role_unique
  on public.document_links (project_id, attachment_role)
  where project_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_quotation_role_unique
  on public.document_links (quotation_id, attachment_role)
  where quotation_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_contract_role_unique
  on public.document_links (contract_id, attachment_role)
  where contract_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_payment_role_unique
  on public.document_links (payment_id, attachment_role)
  where payment_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_purchase_order_role_unique
  on public.document_links (purchase_order_id, attachment_role)
  where purchase_order_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_project_expense_role_unique
  on public.document_links (project_expense_id, attachment_role)
  where project_expense_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_office_expense_role_unique
  on public.document_links (office_expense_id, attachment_role)
  where office_expense_id is not null
    and is_primary = true
    and deleted_at is null;

create unique index document_links_active_primary_financial_transaction_role_unique
  on public.document_links (financial_transaction_id, attachment_role)
  where financial_transaction_id is not null
    and is_primary = true
    and deleted_at is null;

create index document_links_document_idx
  on public.document_links (
    organization_id,
    document_id,
    sort_order
  )
  where deleted_at is null;

create index document_links_customer_idx
  on public.document_links (
    organization_id,
    customer_id,
    attachment_role
  )
  where customer_id is not null
    and deleted_at is null;

create index document_links_supplier_idx
  on public.document_links (
    organization_id,
    supplier_id,
    attachment_role
  )
  where supplier_id is not null
    and deleted_at is null;

create index document_links_project_idx
  on public.document_links (
    organization_id,
    project_id,
    attachment_role
  )
  where project_id is not null
    and deleted_at is null;

create index document_links_quotation_idx
  on public.document_links (
    organization_id,
    quotation_id,
    attachment_role
  )
  where quotation_id is not null
    and deleted_at is null;

create index document_links_contract_idx
  on public.document_links (
    organization_id,
    contract_id,
    attachment_role
  )
  where contract_id is not null
    and deleted_at is null;

create index document_links_payment_idx
  on public.document_links (
    organization_id,
    payment_id,
    attachment_role
  )
  where payment_id is not null
    and deleted_at is null;

create index document_links_purchase_order_idx
  on public.document_links (
    organization_id,
    purchase_order_id,
    attachment_role
  )
  where purchase_order_id is not null
    and deleted_at is null;

create index document_links_project_expense_idx
  on public.document_links (
    organization_id,
    project_expense_id,
    attachment_role
  )
  where project_expense_id is not null
    and deleted_at is null;

create index document_links_office_expense_idx
  on public.document_links (
    organization_id,
    office_expense_id,
    attachment_role
  )
  where office_expense_id is not null
    and deleted_at is null;

create index document_links_financial_transaction_idx
  on public.document_links (
    organization_id,
    financial_transaction_id,
    attachment_role
  )
  where financial_transaction_id is not null
    and deleted_at is null;

-- ============================================================
-- 5. DOCUMENT ACCESS GRANTS
-- Business-level sharing intent for future collaboration features.
-- ============================================================

create table public.document_access_grants (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  document_id uuid not null,
  user_id uuid,
  contact_id uuid,
  access_level public.document_access_level not null default 'view',
  granted_at timestamptz not null default now(),
  granted_by uuid
    references auth.users(id)
    on delete set null,
  expires_at timestamptz,
  revoked_at timestamptz,
  revoked_by uuid
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

  constraint document_access_grants_recipient_required
    check (
      (user_id is null and contact_id is not null)
      or (user_id is not null and contact_id is null)
    ),

  constraint document_access_grants_expiry_after_granted
    check (
      expires_at is null
      or expires_at > granted_at
    ),

  constraint document_access_grants_revocation_state_consistent
    check (
      (revoked_at is null and revoked_by is null)
      or (revoked_at is not null and revoked_by is not null)
    ),

  constraint document_access_grants_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.document_access_grants is
  'Business-level sharing records for documents that later RLS policies and services may enforce.';

alter table public.document_access_grants
  add constraint document_access_grants_id_organization_unique
  unique (id, organization_id);

alter table public.document_access_grants
  add constraint document_access_grants_document_same_organization_fk
  foreign key (
    document_id,
    organization_id
  )
  references public.documents (
    id,
    organization_id
  )
  on delete restrict;

alter table public.document_access_grants
  add constraint document_access_grants_user_same_organization_fk
  foreign key (
    user_id,
    organization_id
  )
  references public.organization_members (
    user_id,
    organization_id
  )
  on delete restrict;

-- Same-organization validation for contact recipients must temporarily be enforced
-- in the service/RPC layer until the contacts tenancy model is normalized in a
-- dedicated migration.
alter table public.document_access_grants
  add constraint document_access_grants_contact_id_fk
  foreign key (contact_id)
  references public.contacts (id)
  on delete restrict;

create unique index document_access_grants_active_user_grant_unique
  on public.document_access_grants (
    document_id,
    user_id,
    access_level
  )
  where user_id is not null
    and revoked_at is null
    and deleted_at is null;

create unique index document_access_grants_active_contact_grant_unique
  on public.document_access_grants (
    document_id,
    contact_id,
    access_level
  )
  where contact_id is not null
    and revoked_at is null
    and deleted_at is null;

create index document_access_grants_document_idx
  on public.document_access_grants (
    organization_id,
    document_id,
    granted_at desc
  )
  where deleted_at is null;

create index document_access_grants_user_idx
  on public.document_access_grants (
    organization_id,
    user_id,
    access_level
  )
  where user_id is not null
    and deleted_at is null;

create index document_access_grants_contact_idx
  on public.document_access_grants (
    organization_id,
    contact_id,
    access_level
  )
  where contact_id is not null
    and deleted_at is null;

create index document_access_grants_expires_idx
  on public.document_access_grants (
    organization_id,
    expires_at
  )
  where expires_at is not null
    and deleted_at is null;

create index document_access_grants_revoked_idx
  on public.document_access_grants (
    organization_id,
    revoked_at
  )
  where revoked_at is not null
    and deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
-- Policies will be added in a later migration.
-- ============================================================

alter table public.document_categories enable row level security;
alter table public.documents enable row level security;
alter table public.document_versions enable row level security;
alter table public.document_links enable row level security;
alter table public.document_access_grants enable row level security;

commit;
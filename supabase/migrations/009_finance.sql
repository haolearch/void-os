-- ============================================================
-- VOID OS
-- Migration: 009_finance.sql
-- Purpose:
--   Create the finance and cash-flow foundation for VOID OS.
--
-- Tables:
--   1. finance_accounts
--   2. finance_categories
--   3. office_expenses
--   4. account_transfers
--   5. financial_transactions
--
-- Notes:
--   - Customer receipts remain authoritative in public.payments.
--   - Project-related costs remain authoritative in public.project_expenses.
--   - Purchase commitments remain authoritative in public.purchase_orders.
--   - This module records where money is held and actual cash movements.
-- ============================================================

begin;

-- ============================================================
-- ENUMS
-- Guarded creation for finance-specific enum types.
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'finance_account_type'
  ) then
    create type public.finance_account_type as enum (
      'cash',
      'bank',
      'e_wallet',
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
      and t.typname = 'finance_account_status'
  ) then
    create type public.finance_account_status as enum (
      'active',
      'inactive',
      'closed'
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
      and t.typname = 'finance_category_type'
  ) then
    create type public.finance_category_type as enum (
      'income',
      'expense'
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
      and t.typname = 'office_expense_status'
  ) then
    create type public.office_expense_status as enum (
      'draft',
      'approved',
      'pending',
      'paid',
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
      and t.typname = 'financial_transaction_type'
  ) then
    create type public.financial_transaction_type as enum (
      'income',
      'expense',
      'transfer_in',
      'transfer_out',
      'adjustment_in',
      'adjustment_out'
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
      and t.typname = 'financial_transaction_status'
  ) then
    create type public.financial_transaction_status as enum (
      'draft',
      'posted',
      'voided'
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
      and t.relname = 'project_expenses'
      and c.conname = 'project_expenses_id_organization_unique'
  ) then
    alter table public.project_expenses
      add constraint project_expenses_id_organization_unique
      unique (id, organization_id);
  end if;
end
$$;

-- ============================================================
-- 1. FINANCE ACCOUNTS
-- Places where VOID holds money.
-- ============================================================

create table public.finance_accounts (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,
  name text not null,
  account_type public.finance_account_type not null default 'other',
  status public.finance_account_status not null default 'active',

  bank_name text,
  account_number text,
  account_holder_name text,
  currency_code text not null default 'VND',
  opening_balance numeric(18, 2) not null default 0,
  opening_balance_date date,
  description text,
  is_default boolean not null default false,
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

  constraint finance_accounts_code_not_blank
    check (length(trim(code)) > 0),

  constraint finance_accounts_name_not_blank
    check (length(trim(name)) > 0),

  constraint finance_accounts_opening_balance_non_negative_or_negative_allowed
    check (opening_balance >= -9999999999999999.99),

  constraint finance_accounts_currency_code_format
    check (currency_code ~ '^[A-Z]{3}$'),

  constraint finance_accounts_bank_name_required_for_bank
    check (
      account_type <> 'bank'
      or (
        bank_name is not null
        and length(trim(bank_name)) > 0
      )
    ),

  constraint finance_accounts_closed_not_default
    check (
      status <> 'closed'
      or is_default = false
    ),

  constraint finance_accounts_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.finance_accounts is
  'Cash funds, bank accounts and electronic wallets used to hold organizational money.';

comment on column public.finance_accounts.code is
  'Organization-scoped short account code.';

comment on column public.finance_accounts.opening_balance is
  'Opening balance used as the starting point for balance calculations.';

alter table public.finance_accounts
  add constraint finance_accounts_id_organization_unique
  unique (id, organization_id);

create unique index finance_accounts_active_code_unique
  on public.finance_accounts (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create unique index finance_accounts_active_default_currency_unique
  on public.finance_accounts (
    organization_id,
    currency_code
  )
  where is_default = true
    and status = 'active'
    and deleted_at is null;

create unique index finance_accounts_active_account_number_unique
  on public.finance_accounts (
    organization_id,
    account_number
  )
  where account_number is not null
    and deleted_at is null;

create index finance_accounts_organization_idx
  on public.finance_accounts (organization_id)
  where deleted_at is null;

create index finance_accounts_status_idx
  on public.finance_accounts (
    organization_id,
    status
  )
  where deleted_at is null;

create index finance_accounts_type_idx
  on public.finance_accounts (
    organization_id,
    account_type
  )
  where deleted_at is null;

create index finance_accounts_default_idx
  on public.finance_accounts (
    organization_id,
    is_default,
    currency_code
  )
  where is_default = true
    and deleted_at is null;

-- ============================================================
-- 2. FINANCE CATEGORIES
-- Hierarchical categories for income and expense reporting.
-- ============================================================

create table public.finance_categories (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  parent_id uuid,

  code text not null,
  name text not null,
  category_type public.finance_category_type not null,
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

  constraint finance_categories_code_not_blank
    check (length(trim(code)) > 0),

  constraint finance_categories_name_not_blank
    check (length(trim(name)) > 0),

  constraint finance_categories_sort_order_non_negative
    check (sort_order >= 0),

  constraint finance_categories_no_self_parent
    check (
      parent_id is null
      or parent_id <> id
    ),

  constraint finance_categories_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.finance_categories is
  'Hierarchical categories used to classify income and expense reporting.';

comment on column public.finance_categories.category_type is
  'Whether the category is used for income or expense reporting.';

alter table public.finance_categories
  add constraint finance_categories_id_organization_unique
  unique (id, organization_id);

alter table public.finance_categories
  add constraint finance_categories_id_organization_type_unique
  unique (
    id,
    organization_id,
    category_type
  );

alter table public.finance_categories
  add constraint finance_categories_parent_same_organization_and_type_fk
  foreign key (
    parent_id,
    organization_id,
    category_type
  )
  references public.finance_categories (
    id,
    organization_id,
    category_type
  )
  on delete restrict;

create unique index finance_categories_active_code_unique
  on public.finance_categories (
    organization_id,
    upper(code)
  )
  where is_active = true
    and deleted_at is null;

create unique index finance_categories_active_sibling_name_unique
  on public.finance_categories (
    organization_id,
    coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(name)
  )
  where is_active = true
    and deleted_at is null;

create index finance_categories_organization_idx
  on public.finance_categories (organization_id)
  where deleted_at is null;

create index finance_categories_hierarchy_idx
  on public.finance_categories (
    organization_id,
    parent_id,
    sort_order
  )
  where deleted_at is null;

create index finance_categories_type_idx
  on public.finance_categories (
    organization_id,
    category_type
  )
  where deleted_at is null;

create index finance_categories_active_list_idx
  on public.finance_categories (
    organization_id,
    is_active,
    sort_order
  )
  where deleted_at is null;

-- ============================================================
-- 3. OFFICE EXPENSES
-- Non-project operating expenses for the business.
-- ============================================================

create table public.office_expenses (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  finance_category_id uuid not null,
  supplier_id uuid,
  category_type public.finance_category_type not null default 'expense',

  code text not null,
  expense_date date not null default current_date,
  description text not null,
  amount_before_tax numeric(18, 2) not null default 0,
  tax_amount numeric(18, 2) not null default 0,
  total_amount numeric(18, 2) not null default 0,
  status public.office_expense_status not null default 'draft',
  payment_method public.payment_method,
  due_date date,
  paid_at timestamptz,
  paid_by uuid
    references auth.users(id)
    on delete set null,
  reference_code text,
  receipt_number text,
  recurrence_key text,
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

  constraint office_expenses_code_not_blank
    check (length(trim(code)) > 0),

  constraint office_expenses_description_not_blank
    check (length(trim(description)) > 0),

  constraint office_expenses_amount_non_negative
    check (amount_before_tax >= 0),

  constraint office_expenses_tax_amount_non_negative
    check (tax_amount >= 0),

  constraint office_expenses_total_non_negative
    check (total_amount >= 0),

  constraint office_expenses_total_matches_formula
    check (total_amount = amount_before_tax + tax_amount),

  constraint office_expenses_category_type_expense
    check (category_type = 'expense'),

  constraint office_expenses_paid_fields_required
    check (
      status <> 'paid'
      or (
        paid_at is not null
        and paid_by is not null
      )
    ),

  constraint office_expenses_unpaid_fields_cleared
    check (
      status = 'paid'
      or (
        paid_at is null
        and paid_by is null
      )
    ),

  constraint office_expenses_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.office_expenses is
  'Operating expenses that do not belong directly to a project.';

comment on column public.office_expenses.category_type is
  'The category type must remain expense for all office expenses.';

alter table public.office_expenses
  add constraint office_expenses_id_organization_unique
  unique (id, organization_id);

alter table public.office_expenses
  add constraint office_expenses_category_same_organization_and_type_fk
  foreign key (
    finance_category_id,
    organization_id,
    category_type
  )
  references public.finance_categories (
    id,
    organization_id,
    category_type
  )
  on delete restrict;

alter table public.office_expenses
  add constraint office_expenses_supplier_same_organization_fk
  foreign key (
    supplier_id,
    organization_id
  )
  references public.suppliers (
    id,
    organization_id
  )
  on delete restrict;

create unique index office_expenses_active_code_unique
  on public.office_expenses (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index office_expenses_category_idx
  on public.office_expenses (
    organization_id,
    finance_category_id,
    status
  )
  where deleted_at is null;

create index office_expenses_supplier_idx
  on public.office_expenses (
    organization_id,
    supplier_id,
    status
  )
  where supplier_id is not null
    and deleted_at is null;

create index office_expenses_status_idx
  on public.office_expenses (
    organization_id,
    status,
    due_date
  )
  where deleted_at is null;

create index office_expenses_date_idx
  on public.office_expenses (
    organization_id,
    expense_date desc
  )
  where deleted_at is null;

create index office_expenses_due_date_idx
  on public.office_expenses (
    organization_id,
    due_date
  )
  where due_date is not null
    and deleted_at is null;

create index office_expenses_recurrence_idx
  on public.office_expenses (
    organization_id,
    recurrence_key
  )
  where recurrence_key is not null
    and deleted_at is null;

-- ============================================================
-- 4. ACCOUNT TRANSFERS
-- One logical transfer between two finance accounts.
-- ============================================================

create table public.account_transfers (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  code text not null,
  transfer_date date not null default current_date,
  source_account_id uuid not null,
  destination_account_id uuid not null,
  amount numeric(18, 2) not null,
  transfer_fee numeric(18, 2) not null default 0,
  status public.financial_transaction_status not null default 'draft',
  reference_code text,
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

  posted_at timestamptz,
  posted_by uuid
    references auth.users(id)
    on delete set null,

  constraint account_transfers_code_not_blank
    check (length(trim(code)) > 0),

  constraint account_transfers_accounts_different
    check (source_account_id <> destination_account_id),

  constraint account_transfers_amount_positive
    check (amount > 0),

  constraint account_transfers_fee_non_negative
    check (transfer_fee >= 0),

  constraint account_transfers_posted_fields_required
    check (
      status <> 'posted'
      or (
        posted_at is not null
        and posted_by is not null
      )
    ),

  constraint account_transfers_unposted_fields_cleared
    check (
      status = 'posted'
      or (
        posted_at is null
        and posted_by is null
      )
    ),

  constraint account_transfers_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.account_transfers is
  'Logical money movements between two finance accounts.';

alter table public.account_transfers
  add constraint account_transfers_id_organization_unique
  unique (id, organization_id);

alter table public.account_transfers
  add constraint account_transfers_source_account_same_organization_fk
  foreign key (
    source_account_id,
    organization_id
  )
  references public.finance_accounts (
    id,
    organization_id
  )
  on delete restrict;

alter table public.account_transfers
  add constraint account_transfers_destination_account_same_organization_fk
  foreign key (
    destination_account_id,
    organization_id
  )
  references public.finance_accounts (
    id,
    organization_id
  )
  on delete restrict;

create unique index account_transfers_active_code_unique
  on public.account_transfers (
    organization_id,
    upper(code)
  )
  where deleted_at is null;

create index account_transfers_source_idx
  on public.account_transfers (
    organization_id,
    source_account_id,
    transfer_date desc
  )
  where deleted_at is null;

create index account_transfers_destination_idx
  on public.account_transfers (
    organization_id,
    destination_account_id,
    transfer_date desc
  )
  where deleted_at is null;

create index account_transfers_date_idx
  on public.account_transfers (
    organization_id,
    transfer_date desc
  )
  where deleted_at is null;

create index account_transfers_status_idx
  on public.account_transfers (
    organization_id,
    status
  )
  where deleted_at is null;

-- ============================================================
-- 5. FINANCIAL TRANSACTIONS
-- Actual movements of money into or out of one finance account.
-- ============================================================

create table public.financial_transactions (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id)
    on delete restrict,

  finance_account_id uuid not null,
  finance_category_id uuid,
  transaction_type public.financial_transaction_type not null,
  status public.financial_transaction_status not null default 'draft',
  transaction_date date not null default current_date,
  amount numeric(18, 2) not null,
  currency_code text not null default 'VND',
  description text not null,
  reference_code text,

  payment_id uuid,
  project_expense_id uuid,
  office_expense_id uuid,
  account_transfer_id uuid,

  posted_at timestamptz,
  posted_by uuid
    references auth.users(id)
    on delete set null,
  voided_at timestamptz,
  voided_by uuid
    references auth.users(id)
    on delete set null,
  void_reason text,
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

  constraint financial_transactions_description_not_blank
    check (length(trim(description)) > 0),

  constraint financial_transactions_amount_positive
    check (amount > 0),

  constraint financial_transactions_currency_code_format
    check (currency_code ~ '^[A-Z]{3}$'),

  constraint financial_transactions_type_valid
    check (
      transaction_type in (
        'income',
        'expense',
        'transfer_in',
        'transfer_out',
        'adjustment_in',
        'adjustment_out'
      )
    ),

  constraint financial_transactions_single_source_reference
    check (
      (case when payment_id is null then 0 else 1 end)
      + (case when project_expense_id is null then 0 else 1 end)
      + (case when office_expense_id is null then 0 else 1 end)
      + (case when account_transfer_id is null then 0 else 1 end) <= 1
    ),

  constraint financial_transactions_payment_type_valid
    check (
      payment_id is null
      or transaction_type = 'income'
    ),

  constraint financial_transactions_project_expense_type_valid
    check (
      project_expense_id is null
      or transaction_type = 'expense'
    ),

  constraint financial_transactions_office_expense_type_valid
    check (
      office_expense_id is null
      or transaction_type = 'expense'
    ),

  constraint financial_transactions_transfer_type_valid
    check (
      account_transfer_id is null
      or transaction_type in ('transfer_in', 'transfer_out')
    ),

  constraint financial_transactions_posted_fields_required
    check (
      status <> 'posted'
      or (
        posted_at is not null
        and posted_by is not null
      )
    ),

  constraint financial_transactions_unposted_fields_cleared
    check (
      status = 'posted'
      or (
        posted_at is null
        and posted_by is null
      )
    ),

  constraint financial_transactions_voided_fields_required
    check (
      status <> 'voided'
      or (
        voided_at is not null
        and voided_by is not null
        and length(trim(coalesce(void_reason, ''))) > 0
      )
    ),

  constraint financial_transactions_unvoided_fields_cleared
    check (
      status = 'voided'
      or (
        voided_at is null
        and voided_by is null
        and void_reason is null
      )
    ),

  constraint financial_transactions_metadata_is_object
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.financial_transactions is
  'Actual money movements into or out of finance accounts and their associated source records.';

comment on column public.financial_transactions.transaction_type is
  'Defines whether the movement increases or decreases the account balance.';

alter table public.financial_transactions
  add constraint financial_transactions_id_organization_unique
  unique (id, organization_id);

alter table public.financial_transactions
  add constraint financial_transactions_account_same_organization_fk
  foreign key (
    finance_account_id,
    organization_id
  )
  references public.finance_accounts (
    id,
    organization_id
  )
  on delete restrict;

alter table public.financial_transactions
  add constraint financial_transactions_category_same_organization_fk
  foreign key (
    finance_category_id,
    organization_id
  )
  references public.finance_categories (
    id,
    organization_id
  )
  on delete restrict;

alter table public.financial_transactions
  add constraint financial_transactions_payment_same_organization_fk
  foreign key (
    payment_id,
    organization_id
  )
  references public.payments (
    id,
    organization_id
  )
  on delete restrict;

alter table public.financial_transactions
  add constraint financial_transactions_project_expense_same_organization_fk
  foreign key (
    project_expense_id,
    organization_id
  )
  references public.project_expenses (
    id,
    organization_id
  )
  on delete restrict;

alter table public.financial_transactions
  add constraint financial_transactions_office_expense_same_organization_fk
  foreign key (
    office_expense_id,
    organization_id
  )
  references public.office_expenses (
    id,
    organization_id
  )
  on delete restrict;

alter table public.financial_transactions
  add constraint financial_transactions_transfer_same_organization_fk
  foreign key (
    account_transfer_id,
    organization_id
  )
  references public.account_transfers (
    id,
    organization_id
  )
  on delete restrict;

create unique index financial_transactions_account_date_idx
  on public.financial_transactions (
    organization_id,
    finance_account_id,
    transaction_date desc
  )
  where deleted_at is null;

create index financial_transactions_type_idx
  on public.financial_transactions (
    organization_id,
    transaction_type
  )
  where deleted_at is null;

create index financial_transactions_status_idx
  on public.financial_transactions (
    organization_id,
    status
  )
  where deleted_at is null;

create index financial_transactions_category_idx
  on public.financial_transactions (
    organization_id,
    finance_category_id,
    transaction_date desc
  )
  where finance_category_id is not null
    and deleted_at is null;

create unique index financial_transactions_active_posted_payment_unique
  on public.financial_transactions (payment_id)
  where payment_id is not null
    and status = 'posted'
    and deleted_at is null;

create unique index financial_transactions_active_posted_project_expense_unique
  on public.financial_transactions (project_expense_id)
  where project_expense_id is not null
    and status = 'posted'
    and deleted_at is null;

create unique index financial_transactions_active_posted_office_expense_unique
  on public.financial_transactions (office_expense_id)
  where office_expense_id is not null
    and status = 'posted'
    and deleted_at is null;

create unique index financial_transactions_active_posted_transfer_unique
  on public.financial_transactions (account_transfer_id, transaction_type)
  where account_transfer_id is not null
    and status = 'posted'
    and deleted_at is null;

create index financial_transactions_payment_idx
  on public.financial_transactions (
    organization_id,
    payment_id,
    transaction_date desc
  )
  where payment_id is not null
    and deleted_at is null;

create index financial_transactions_project_expense_idx
  on public.financial_transactions (
    organization_id,
    project_expense_id,
    transaction_date desc
  )
  where project_expense_id is not null
    and deleted_at is null;

create index financial_transactions_office_expense_idx
  on public.financial_transactions (
    organization_id,
    office_expense_id,
    transaction_date desc
  )
  where office_expense_id is not null
    and deleted_at is null;

create index financial_transactions_transfer_idx
  on public.financial_transactions (
    organization_id,
    account_transfer_id,
    transaction_date desc
  )
  where account_transfer_id is not null
    and deleted_at is null;

create index financial_transactions_reference_code_idx
  on public.financial_transactions (
    organization_id,
    reference_code
  )
  where reference_code is not null
    and deleted_at is null;

-- ============================================================
-- ROW LEVEL SECURITY
-- Policies will be added in a later migration.
-- ============================================================

alter table public.finance_accounts enable row level security;
alter table public.finance_categories enable row level security;
alter table public.office_expenses enable row level security;
alter table public.account_transfers enable row level security;
alter table public.financial_transactions enable row level security;

commit;
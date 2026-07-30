# VOID OS Database Dictionary

This document outlines the planned Supabase database modules and tables for the first migration preparation phase. It is a planning reference only and does not contain any SQL statements yet.

## CRM

### customers
Purpose: Store the core client and company records for VOID Design & Build.
Main relationships:
- One customer can have many contacts.
- One customer can be linked to many projects.
- One customer can have many quotations and contracts.

### contacts
Purpose: Store individual people associated with a customer account.
Main relationships:
- Each contact belongs to one customer.
- Contacts may be referenced by quotations, contracts, and project communications.

## Projects

### projects
Purpose: Represent architectural and interior design engagements.
Main relationships:
- Each project belongs to one customer.
- A project can have many project members, milestones, tasks, budgets, expenses, and attachments.

### project_members
Purpose: Track employees or collaborators assigned to a project.
Main relationships:
- Each record links one employee to one project.
- Supports role-based ownership and assignment tracking.

### milestones
Purpose: Capture key project delivery checkpoints.
Main relationships:
- Each milestone belongs to one project.
- Milestones can be used to track progress and deadlines.

### tasks
Purpose: Break down project work into actionable units.
Main relationships:
- Each task belongs to one project.
- Tasks may be linked to milestones and assigned employees.

## Sales

### quotations
Purpose: Store proposal records sent to prospects or clients for a project scope.
Main relationships:
- Each quotation belongs to one project through project_id.
- The customer is derived from the linked project through projects.customer_id; customer_id should not be stored directly on quotations.
- One quotation has many quotation_items.
- The schema should support multiple immutable versions for one project so historical proposals remain intact.
- A quotation may later be referenced by a contract through quotation_id when approved.

### quotation_items
Purpose: Store line items included in a quotation.
Main relationships:
- Each quotation item belongs to one quotation.
- Supports detailed pricing, scope breakdowns, and versioned proposal content.

### contracts
Purpose: Record signed agreements for awarded work.
Main relationships:
- Each contract belongs to one project.
- A contract may reference an approved quotation through quotation_id.
- The customer should be derived from the linked project rather than duplicated in the contract table.
- One contract has many payment_schedules.

### payment_schedules
Purpose: Define expected payment milestones for a contract.
Main relationships:
- Each payment schedule belongs to one contract.
- Include phase_number, title, percentage, planned_amount, due_date, and status.
- The default VOID workflow is three phases with the standard allocation of 30%, 40%, and 30%.
- Supports staged billing, forecasting, and receivable planning.

### payments
Purpose: Record payments received against contract milestones.
Main relationships:
- Each payment belongs to one payment_schedule.
- The design must allow multiple partial payments for a single schedule.
- Include paid_amount, paid_date, payment_method, reference_code, and notes.
- Contract_id should not be duplicated unless there is a documented reporting reason that requires it.


## Construction and procurement

### work_categories
Purpose: Define standard work or service categories used across projects.
Main relationships:
- Work categories should support a hierarchical parent_id relationship for structured cost breakdowns.
- Example hierarchy:
  - Construction
    - Masonry
    - Ceiling
    - Painting
    - Electrical
  - Furniture
    - Woodwork
    - Loose furniture
- Used by budgets, purchase orders, and project planning structures.

### suppliers
Purpose: Store vendor and procurement partner information.
Main relationships:
- Suppliers can be referenced by purchase orders and project expenses.

### project_budgets
Purpose: Hold the approved financial plan for a project.
Main relationships:
- Each budget belongs to one project.
- A project may have multiple budget versions over time.
- Only one budget version can be marked approved at a time.
- Older versions must remain intact and should not be overwritten.

### project_budget_items
Purpose: Break budget totals into detailed line items.
Main relationships:
- Each budget item belongs to one project budget.
- Include work_category_id, description, quantity, unit, estimated_unit_cost, and estimated_total.
- Support parent-child grouping when needed for nested cost structures.
- Used for cost tracking and forecasting.

### purchase_orders
Purpose: Track procurement requests and vendor orders.
Main relationships:
- Each purchase order belongs to one project and one supplier.
- Include status, ordered_date, expected_date, subtotal, tax, and total_amount.
- A purchase order can have many purchase order items.

### purchase_order_items
Purpose: Store line items associated with a purchase order.
Main relationships:
- Each item belongs to one purchase order.
- May reference one project_budget_item for budget comparison.
- Include quantity, unit, unit_price, and total_amount.
- Supports budget validation and procurement detail tracking.

### project_expenses
Purpose: Capture project-related spend outside of formal purchase orders.
Main relationships:
- Each expense belongs to one project.
- May reference supplier_id, expense_category_id, project_budget_item_id, purchase_order_id, or purchase_order_item_id.
- Must support expenses outside formal purchase orders.
- Include amount, paid_amount, expense_date, due_date, status, and notes.

## Office finance

### expense_categories
Purpose: Standardize categories used for office and administrative expenses.
Main relationships:
- Expense categories can be referenced by office expenses and project expenses.

### office_expenses
Purpose: Record non-project operating expenses for the business.
Main relationships:
- Each office expense belongs to one expense category.
- Include amount, paid_amount, expense_date, due_date, status, vendor, and notes.
- Supports monthly finance review and reporting.

## People

### employees
Purpose: Store staff records for the organization.
Main relationships:
- Employees can be assigned to projects through project_members.
- Employees may also be referenced in tasks, approvals, and other operational workflows.

## Documents

### document_categories
Purpose: Define organization-specific classifications for documents and file metadata.
Main relationships:
- Supports hierarchical categories for contracts, drawings, invoices, receipts, supplier documents, legal records, and internal files.
- Each category belongs to one organization and may have a parent category within the same organization.

### documents
Purpose: Represent one logical document independently from the underlying file versions.
Main relationships:
- Each document belongs to one organization and optionally one document category.
- One document has many document_versions and many document_links.
- The current_version_id references the current file version for the document.
- Documents may later be linked to customers, suppliers, projects, quotations, contracts, payments, purchase orders, project expenses, office expenses, and financial transactions through explicit document links.

### document_versions
Purpose: Store immutable metadata for each uploaded or generated file version while keeping the file content in Supabase Storage.
Main relationships:
- Each version belongs to one document and one organization.
- The schema stores storage_bucket, storage_path, mime_type, file size, checksum, and other metadata but not binary content.
- Only one current version is allowed per document, while older versions remain available for history.

### document_links
Purpose: Connect a document to one explicit business record while preserving tenant-safe foreign-key integrity.
Main relationships:
- Each link belongs to one document and one organization.
- The link targets exactly one of the supported business records through explicit nullable foreign-key columns.
- Supports primary and supporting documents, receipts, invoices, contracts, drawings, photos, reports, and other roles.

### document_access_grants
Purpose: Store business-level sharing intent for future collaboration features.
Main relationships:
- Provides access grants for either a user or a contact, but never both.
- Each grant belongs to one document and one organization.
- The structure is separate from RLS and supports later policy or service-driven sharing workflows.

### Supabase Storage model
Purpose: Keep the storage layer separate from PostgreSQL document records.
Main relationships:
- PostgreSQL stores metadata, version history, classification, link targets, and audit information.
- document_versions.storage_bucket and document_versions.storage_path reference the future Supabase Storage object location.
- Binary content, base64 payloads, MIME payloads beyond metadata, and storage policies are intentionally not stored in PostgreSQL.

## Documents and system

### attachments
Purpose: Store links or metadata for supporting documents.
Main relationships:
- Attachments can reference projects, customers, contracts, quotations, or other core records.

### activity_logs
Purpose: Record significant business events and system history.
Main relationships:
- Each log entry can reference a related entity such as a customer, project, employee, or document.
- Supports audit trails and operational visibility.

## System foundation

### organizations
Purpose: Represent a company or business workspace using VOID OS.
Main relationships:
- Every top-level business record must belong to one organization.
- One organization has many employees, customers, projects, suppliers, expense categories, quotations, contracts, and activity logs.
- VOID Design & Build will be the first organization seeded into the database.

### organization_members
Purpose: Link authenticated Supabase users to an organization and define their role context.
Main relationships:
- Each organization member belongs to one organization.
- Each organization member references one Supabase auth user.
- An employee record may optionally be linked to one organization member.
- Supports future role-based access management and eventual Row Level Security policies.

## Multi-tenant data rules
Purpose: Define the organization ownership model for all business records.
Main relationships:
- Every top-level business record belongs to one organization.
- Child records inherit organization ownership from their parent record.
- Cross-organization foreign-key relationships are forbidden.
- organization_id must be used for filtering, indexing, and future Row Level Security enforcement.
- organization_id should not be stored redundantly where it cannot be safely validated.
- Ownership should flow through parent-child tables as follows:
  - customers belongs directly to an organization.
  - projects belongs directly to an organization and one customer in the same organization.
  - quotation_items inherit organization ownership through quotations.
  - purchase_order_items inherit organization ownership through purchase_orders.
  - payments inherit organization ownership through payment_schedules and contracts.
- The same design rule should be applied to all business tables so that every record can be safely scoped to one organization.

## Derived financial metrics
Purpose: Define the financial indicators that should be derivable from the core data model for dashboards and reporting.
Main relationships:
- Contract value: derived from the approved contract value or associated payment schedule totals.
- Planned receivables: derived from payment schedules and their planned amounts.
- Actual revenue: derived from confirmed payments and settlement records.
- Project estimated cost: derived from project budget totals and budget items.
- Project actual cost: derived from project expenses, purchase orders, and related payments.
- Supplier payable: derived from purchase orders and project expenses pending settlement.
- Project gross profit: derived from contract value or revenue minus project actual cost.
- Company net profit: derived from overall revenue minus operating and project expenses.

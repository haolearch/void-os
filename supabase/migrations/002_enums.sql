-- ============================================================
-- VOID OS
-- Migration: 002_enums.sql
-- Purpose: Define shared enum types used across VOID OS.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- SYSTEM
-- ------------------------------------------------------------

create type public.organization_status as enum (
  'active',
  'inactive',
  'suspended'
);

create type public.organization_member_role as enum (
  'owner',
  'admin',
  'manager',
  'member',
  'viewer'
);

create type public.organization_member_status as enum (
  'invited',
  'active',
  'inactive',
  'suspended'
);

-- ------------------------------------------------------------
-- PEOPLE
-- ------------------------------------------------------------

create type public.employee_type as enum (
  'full_time',
  'part_time',
  'intern',
  'contractor',
  'freelancer'
);

create type public.employee_status as enum (
  'active',
  'on_leave',
  'inactive',
  'terminated'
);

-- ------------------------------------------------------------
-- CRM
-- ------------------------------------------------------------

create type public.customer_type as enum (
  'individual',
  'company'
);

create type public.customer_status as enum (
  'lead',
  'prospect',
  'active',
  'inactive',
  'archived'
);

create type public.customer_source as enum (
  'referral',
  'facebook',
  'tiktok',
  'website',
  'walk_in',
  'partner',
  'returning_customer',
  'other'
);

-- ------------------------------------------------------------
-- PROJECTS
-- ------------------------------------------------------------

create type public.project_type as enum (
  'house',
  'apartment',
  'villa',
  'shop',
  'cafe',
  'restaurant',
  'office',
  'hotel',
  'booth',
  'showroom',
  'other'
);

create type public.project_service_type as enum (
  'architecture_design',
  'interior_design',
  'construction',
  'supervision',
  'renovation',
  'consulting'
);

create type public.project_status as enum (
  'lead',
  'planning',
  'quotation',
  'contracted',
  'designing',
  'awaiting_approval',
  'construction',
  'on_hold',
  'completed',
  'warranty',
  'cancelled'
);

create type public.project_priority as enum (
  'low',
  'normal',
  'high',
  'urgent'
);

create type public.project_member_role as enum (
  'project_manager',
  'architect',
  'interior_designer',
  'technical_designer',
  'quantity_surveyor',
  'site_supervisor',
  'construction_manager',
  'accountant',
  'collaborator',
  'viewer'
);

create type public.phase_status as enum (
  'not_started',
  'in_progress',
  'awaiting_approval',
  'completed',
  'on_hold',
  'cancelled'
);

create type public.milestone_status as enum (
  'pending',
  'in_progress',
  'completed',
  'overdue',
  'cancelled'
);

create type public.task_status as enum (
  'todo',
  'in_progress',
  'review',
  'blocked',
  'completed',
  'cancelled'
);

-- ------------------------------------------------------------
-- SALES
-- ------------------------------------------------------------

create type public.quotation_status as enum (
  'draft',
  'sent',
  'viewed',
  'negotiating',
  'approved',
  'rejected',
  'expired',
  'cancelled'
);

create type public.quotation_version_status as enum (
  'draft',
  'issued',
  'approved',
  'rejected',
  'superseded'
);

create type public.quotation_item_type as enum (
  'design',
  'construction',
  'supervision',
  'material',
  'labor',
  'service',
  'discount',
  'other'
);

create type public.contract_status as enum (
  'draft',
  'pending_signature',
  'active',
  'completed',
  'terminated',
  'cancelled'
);

create type public.payment_schedule_status as enum (
  'planned',
  'due',
  'partially_paid',
  'paid',
  'overdue',
  'cancelled'
);

create type public.payment_status as enum (
  'pending',
  'confirmed',
  'refunded',
  'cancelled'
);

create type public.payment_method as enum (
  'cash',
  'bank_transfer',
  'card',
  'e_wallet',
  'other'
);

-- ------------------------------------------------------------
-- PROCUREMENT AND COST
-- ------------------------------------------------------------

create type public.budget_status as enum (
  'draft',
  'submitted',
  'approved',
  'rejected',
  'superseded'
);

create type public.purchase_order_status as enum (
  'draft',
  'submitted',
  'approved',
  'ordered',
  'partially_received',
  'received',
  'cancelled'
);

create type public.expense_status as enum (
  'draft',
  'pending',
  'partially_paid',
  'paid',
  'overdue',
  'cancelled'
);

create type public.expense_type as enum (
  'material',
  'labor',
  'subcontractor',
  'transportation',
  'equipment',
  'service',
  'permit',
  'other'
);

create type public.supplier_status as enum (
  'active',
  'inactive',
  'blacklisted'
);

create type public.material_status as enum (
  'active',
  'inactive',
  'discontinued'
);

-- ------------------------------------------------------------
-- DOCUMENTS
-- ------------------------------------------------------------

create type public.file_status as enum (
  'active',
  'archived',
  'deleted'
);

create type public.file_access_level as enum (
  'private',
  'organization',
  'project_members',
  'public'
);

-- ------------------------------------------------------------
-- NOTIFICATIONS AND TIMELINE
-- ------------------------------------------------------------

create type public.notification_type as enum (
  'info',
  'success',
  'warning',
  'error',
  'deadline',
  'payment',
  'task',
  'project',
  'system'
);

create type public.notification_status as enum (
  'unread',
  'read',
  'archived'
);

create type public.timeline_event_type as enum (
  'created',
  'updated',
  'status_changed',
  'commented',
  'file_uploaded',
  'quotation_issued',
  'quotation_approved',
  'contract_signed',
  'payment_received',
  'expense_recorded',
  'task_completed',
  'other'
);

commit;
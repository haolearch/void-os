-- ============================================================
-- VOID OS
-- Migration: 001_extensions.sql
-- Purpose: Enable PostgreSQL extensions required by the system.
-- ============================================================

begin;

-- Provides cryptographic functions and UUID generation.
-- gen_random_uuid() will be used as the default primary key value.
create extension if not exists pgcrypto
with schema extensions;

-- Supports case-insensitive text values.
-- Useful for emails and other identifiers where casing should not matter.
create extension if not exists citext
with schema extensions;

-- Supports fast similarity search and fuzzy text matching.
-- Useful later for customer, supplier, project and material search.
create extension if not exists pg_trgm
with schema extensions;

-- Supports hierarchical path data.
-- Reserved for future folder trees and structured classifications.
create extension if not exists ltree
with schema extensions;

commit;
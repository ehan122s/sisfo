-- ============================================================
-- E-PKL Database Setup — Step 1: Extensions
-- ============================================================
-- Run this FIRST on a fresh Supabase project.
-- These extensions must be enabled before creating any
-- functions that depend on them.
-- ============================================================

-- Required for password hashing in create_teacher_user()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Required for WhatsApp HTTP calls via check_attendance_violations()
CREATE EXTENSION IF NOT EXISTS "pg_net";

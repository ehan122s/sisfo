-- Migration: Add ip_address, status, and description columns to audit_logs table
-- This adds support for tracking IP address, action status, and descriptions in audit logs

-- Add new columns if they don't exist
ALTER TABLE public.audit_logs
ADD COLUMN IF NOT EXISTS ip_address TEXT,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'BERHASIL' CHECK (status IN ('BERHASIL', 'GAGAL')),
ADD COLUMN IF NOT EXISTS description TEXT;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS audit_logs_status_idx ON public.audit_logs (status);
CREATE INDEX IF NOT EXISTS audit_logs_action_idx ON public.audit_logs (action);
CREATE INDEX IF NOT EXISTS audit_logs_table_name_idx ON public.audit_logs (table_name);

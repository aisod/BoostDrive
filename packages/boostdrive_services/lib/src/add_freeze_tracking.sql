-- SQL Migration: Add Account Freezing Tracking to Profiles Table

-- 1. Add current status tracking columns using 'freeze' terminology
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS freeze_reason TEXT,       -- Stores the reason provided by the admin
ADD COLUMN IF NOT EXISTS frozen_at TIMESTAMPTZ,    -- Stores the exact date/time of freezing
ADD COLUMN IF NOT EXISTS frozen_by UUID REFERENCES public.profiles(id); -- References the admin ID

-- 2. Performance Optimization
-- Speeds up security lookups when viewing a user's freeze history
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target_id ON public.audit_logs(target_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

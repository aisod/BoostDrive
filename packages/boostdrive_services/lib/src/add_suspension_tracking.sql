-- SQL Migration: Add Account Suspension Tracking to Profiles Table

-- 1. Add current status tracking columns using 'suspension' terminology
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS suspension_reason TEXT,       -- Stores the reason provided by the admin
ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ,    -- Stores the exact date/time of suspension
ADD COLUMN IF NOT EXISTS suspended_by UUID REFERENCES public.profiles(id); -- References the admin ID

-- 2. Performance Optimization
-- Speeds up security lookups when viewing a user's suspension history
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target_id ON public.audit_logs(target_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

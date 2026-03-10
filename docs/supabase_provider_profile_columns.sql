-- Provider Profile Settings: columns for operational, specialization, financial, trust, and notification data.
-- Run in Supabase SQL Editor. Safe to run multiple times (IF NOT EXISTS / defaults).

-- Operational & Business Details
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS business_hours_24_7 boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS service_radius_km integer;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workshop_address text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workshop_lat double precision;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workshop_lng double precision;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_facebook text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS social_instagram text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS website_url text DEFAULT '';

-- Service Specializations (filters)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS brand_expertise text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS service_tags text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS towing_capabilities text DEFAULT '';

-- Financial & Payout
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bank_account_number text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bank_branch text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bank_name text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS standard_labor_rate double precision;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tax_vat_number text DEFAULT '';

-- Trust & Experience
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS business_bio text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gallery_urls text DEFAULT '';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS team_size integer;

-- Notification & Alert
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sos_alerts_enabled boolean DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_communication text DEFAULT 'app_chat';

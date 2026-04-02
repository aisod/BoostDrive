-- SQL to enable Admin Creation RPC
-- RUN THIS IN YOUR SUPABASE SQL EDITOR

-- 1. Ensure pgcrypto exists for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. The RPC Function
CREATE OR REPLACE FUNCTION create_admin_user(
  email TEXT,
  password TEXT,
  full_name TEXT,
  admin_id UUID
) RETURNS JSONB
SECURITY DEFINER -- Essential: Allows this function to bypass RLS and interact with auth.users
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- 1. Create Auth User
  -- We manually insert into auth.users to keep it atomic with the profile
  INSERT INTO auth.users (
    instance_id, 
    id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    created_at, 
    updated_at, 
    role, 
    is_super_admin, 
    confirmed_at,
    confirmation_token
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    LOWER(email),
    crypt(password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', full_name, 'role', 'admin'),
    now(),
    now(),
    'authenticated',
    false,
    now(),
    encode(gen_random_bytes(32), 'hex')
  ) RETURNING id INTO new_user_id;

  -- 2. Insert into public.profiles (role: 'admin')
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name, 
    role, 
    status, 
    verification_status, 
    is_buyer, 
    is_seller, 
    created_at, 
    last_active
  )
  VALUES (
    new_user_id,
    LOWER(email),
    full_name,
    'admin',
    'active',
    'approved',
    true,
    false,
    now(),
    now()
  );

  -- 3. Trigger Audit Log
  -- Note: Ensure target_id and admin_id are linked to audit log schema
  INSERT INTO public.audit_logs (
    admin_id, 
    target_id, 
    action_type, 
    notes, 
    metadata, 
    created_at
  )
  VALUES (
    admin_id,
    new_user_id,
    'CREATE_ADMIN',
    'Administrator created new Admin account: ' || email,
    jsonb_build_object('email', LOWER(email), 'category', 'ADMIN_MANAGEMENT'),
    now()
  );

  RETURN jsonb_build_object('success', true, 'user_id', new_user_id);
EXCEPTION WHEN OTHERS THEN
  -- Catch duplicates and other errors
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

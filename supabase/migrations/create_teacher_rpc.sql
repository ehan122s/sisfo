-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Function to create teacher/supervisor account
-- Can only be called by admins (verified via RLS check inside)
CREATE OR REPLACE FUNCTION create_teacher_user(
  email text,
  password text,
  full_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER -- Runs as postgres to bypass RLS on auth.users
SET search_path = public, extensions -- Secure search path including extensions for pgcrypto
AS $$
DECLARE
  new_id uuid;
  encrypted_pw text;
BEGIN
  -- 1. Check if caller is admin
  -- We assume the caller is authenticated and has 'admin' role in profiles
  -- Note: existing RLS policies on profiles allow reading own profile
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only admins can create accounts.';
  END IF;

  -- 2. Check if email exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE auth.users.email = create_teacher_user.email) THEN
    RAISE EXCEPTION 'Email already registered.';
  END IF;

  -- 3. Hash Password using bcrypt
  encrypted_pw := crypt(password, gen_salt('bf'));

  -- 4. Insert into auth.users
  -- This will trigger handle_new_user which creates a profile
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    email,
    encrypted_pw,
    now(), -- Auto confirm email
    null,
    null,
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('full_name', full_name),
    now(),
    now(),
    '',
    '',
    '',
    ''
  )
  RETURNING id INTO new_id;

  -- 5. Update Profile Role to 'teacher'
  -- The trigger 'on_auth_user_created' runs AFTER INSERT on auth.users
  -- So the profile should exist now.
  UPDATE profiles
  SET role = 'teacher',
      nisn = NULL -- Teachers don't need NISN
  WHERE id = new_id;

  RETURN new_id;
END;
$$;

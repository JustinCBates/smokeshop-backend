CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE SCHEMA IF NOT EXISTS auth;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION auth.role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.role', true), '');
$$;

CREATE TABLE IF NOT EXISTS auth.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext NOT NULL UNIQUE,
  encrypted_password text NOT NULL,
  email_confirmed_at timestamptz,
  raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  raw_user_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  last_sign_in_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS auth_users_set_updated_at ON auth.users;
CREATE TRIGGER auth_users_set_updated_at
  BEFORE UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS auth.identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider text NOT NULL,
  provider_user_id text NOT NULL,
  identity_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_user_id)
);

DROP TRIGGER IF EXISTS auth_identities_set_updated_at ON auth.identities;
CREATE TRIGGER auth_identities_set_updated_at
  BEFORE UPDATE ON auth.identities
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS auth.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  access_token text NOT NULL UNIQUE,
  refresh_token text UNIQUE,
  ip_address inet,
  user_agent text,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS auth_sessions_set_updated_at ON auth.sessions;
CREATE TRIGGER auth_sessions_set_updated_at
  BEFORE UPDATE ON auth.sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email citext NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'manager', 'admin', 'owner')),
  first_name text,
  last_name text,
  phone text,
  date_of_birth date,
  age_verified boolean NOT NULL DEFAULT false,
  age_verification_method text,
  id_photo_url text,
  id_review_status text NOT NULL DEFAULT 'pending',
  id_reviewed_by uuid,
  id_reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS profiles_set_updated_at ON public.profiles;
CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    role,
    first_name,
    last_name
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_app_meta_data ->> 'role', 'customer'),
    NULLIF(NEW.raw_user_meta_data ->> 'first_name', ''),
    NULLIF(NEW.raw_user_meta_data ->> 'last_name', '')
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      role = EXCLUDED.role,
      first_name = COALESCE(EXCLUDED.first_name, public.profiles.first_name),
      last_name = COALESCE(EXCLUDED.last_name, public.profiles.last_name),
      updated_at = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE INDEX IF NOT EXISTS idx_auth_users_email ON auth.users (email);
CREATE INDEX IF NOT EXISTS idx_auth_identities_user_id ON auth.identities (user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id ON auth.sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires_at ON auth.sessions (expires_at);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (role);
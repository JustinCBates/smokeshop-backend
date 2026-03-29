-- Profiles: extends Supabase auth.users with app-specific fields
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  date_of_birth DATE,
  role TEXT DEFAULT 'customer',
  phone TEXT,
  age_verified BOOLEAN DEFAULT FALSE,
  age_verification_method TEXT,
  id_photo_url TEXT,
  id_review_status TEXT DEFAULT 'pending',
  id_reviewed_by UUID,
  id_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

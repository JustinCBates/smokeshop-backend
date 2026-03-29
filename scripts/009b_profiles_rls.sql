ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read their own profile
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Insert is open (trigger uses SECURITY DEFINER)
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (true);

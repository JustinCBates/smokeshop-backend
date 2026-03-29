-- Pickup locations with lat/lng coordinates
-- Uses separate lat/lng columns for portability. Migrate to PostGIS Point in production.
CREATE TABLE IF NOT EXISTS public.pickup_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_name TEXT NOT NULL,
  address TEXT NOT NULL,
  state TEXT NOT NULL,
  lat FLOAT NOT NULL,
  lng FLOAT NOT NULL,
  extended_radius_km FLOAT,
  extended_radius_fee_cents INTEGER,
  is_active BOOLEAN DEFAULT TRUE
);

-- Public read, admin write
ALTER TABLE public.pickup_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pickup_locations_public_read" ON public.pickup_locations
  FOR SELECT USING (true);

CREATE POLICY "pickup_locations_admin_insert" ON public.pickup_locations
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "pickup_locations_admin_update" ON public.pickup_locations
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "pickup_locations_admin_delete" ON public.pickup_locations
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

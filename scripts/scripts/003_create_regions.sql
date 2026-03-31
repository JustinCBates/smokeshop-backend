-- Regions table: delivery zones stored as GeoJSON polygons
-- Uses JSONB for portability. Migrate to PostGIS geometry column in production.
CREATE TABLE IF NOT EXISTS public.regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region_name TEXT NOT NULL,
  state TEXT NOT NULL,
  boundary JSONB NOT NULL, -- GeoJSON Polygon, e.g. {"type":"Polygon","coordinates":[[[...]]]}
  center_lat FLOAT,
  center_lng FLOAT,
  partner_id UUID,
  is_active BOOLEAN DEFAULT TRUE
);

-- Public read, admin + owning partner write
ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "regions_public_read" ON public.regions
  FOR SELECT USING (true);

CREATE POLICY "regions_admin_insert" ON public.regions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "regions_admin_update" ON public.regions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR partner_id = auth.uid()
  );

CREATE POLICY "regions_admin_delete" ON public.regions
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

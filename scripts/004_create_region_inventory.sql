-- Region inventory: cross table for delivery stock per region
CREATE TABLE IF NOT EXISTS public.region_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT NOT NULL REFERENCES public.products(sku) ON DELETE CASCADE,
  region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  UNIQUE(sku, region_id)
);

-- Public read, admin + owning partner write
ALTER TABLE public.region_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "region_inventory_public_read" ON public.region_inventory
  FOR SELECT USING (true);

CREATE POLICY "region_inventory_admin_insert" ON public.region_inventory
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "region_inventory_admin_update" ON public.region_inventory
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "region_inventory_admin_delete" ON public.region_inventory
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Pickup inventory: separate stock per pickup location
CREATE TABLE IF NOT EXISTS public.pickup_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT NOT NULL REFERENCES public.products(sku) ON DELETE CASCADE,
  pickup_location_id UUID NOT NULL REFERENCES public.pickup_locations(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  UNIQUE(sku, pickup_location_id)
);

-- Public read, admin write
ALTER TABLE public.pickup_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pickup_inventory_public_read" ON public.pickup_inventory
  FOR SELECT USING (true);

CREATE POLICY "pickup_inventory_admin_insert" ON public.pickup_inventory
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "pickup_inventory_admin_update" ON public.pickup_inventory
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "pickup_inventory_admin_delete" ON public.pickup_inventory
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Delivery fee tiers: partner-managed pricing by speed
CREATE TABLE IF NOT EXISTS public.delivery_fee_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
  tier_name TEXT NOT NULL,
  fee_cents INTEGER NOT NULL,
  estimated_minutes_min INTEGER,
  estimated_minutes_max INTEGER,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE public.delivery_fee_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "delivery_fee_tiers_public_read" ON public.delivery_fee_tiers
  FOR SELECT USING (true);

CREATE POLICY "delivery_fee_tiers_admin_insert" ON public.delivery_fee_tiers
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "delivery_fee_tiers_admin_update" ON public.delivery_fee_tiers
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "delivery_fee_tiers_admin_delete" ON public.delivery_fee_tiers
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Delivery slots: scheduled time windows set by partners
CREATE TABLE IF NOT EXISTS public.delivery_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  fee_cents INTEGER NOT NULL,
  max_orders INTEGER,
  is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE public.delivery_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "delivery_slots_public_read" ON public.delivery_slots
  FOR SELECT USING (true);

CREATE POLICY "delivery_slots_admin_insert" ON public.delivery_slots
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "delivery_slots_admin_update" ON public.delivery_slots
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    OR EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

CREATE POLICY "delivery_slots_admin_delete" ON public.delivery_slots
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

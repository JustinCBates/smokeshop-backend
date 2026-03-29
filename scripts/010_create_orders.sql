-- Orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  fulfillment_type TEXT NOT NULL CHECK (fulfillment_type IN ('delivery', 'pickup')),
  region_id UUID REFERENCES public.regions(id),
  pickup_location_id UUID REFERENCES public.pickup_locations(id),
  delivery_fee_tier_id UUID REFERENCES public.delivery_fee_tiers(id),
  delivery_slot_id UUID REFERENCES public.delivery_slots(id),
  delivery_address TEXT,
  subtotal_cents INTEGER NOT NULL,
  delivery_fee_cents INTEGER NOT NULL DEFAULT 0,
  total_cents INTEGER NOT NULL,
  payment_method TEXT CHECK (payment_method IN ('stripe', 'paypal')),
  payment_id TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'out_for_delivery', 'ready_for_pickup', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Users can read their own orders
CREATE POLICY "orders_select_own" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

-- Admin can read all orders
CREATE POLICY "orders_admin_select" ON public.orders
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Partners can read orders for their region
CREATE POLICY "orders_partner_select" ON public.orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

-- Users can insert their own orders
CREATE POLICY "orders_insert_own" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin can update any order
CREATE POLICY "orders_admin_update" ON public.orders
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Partners can update orders in their region
CREATE POLICY "orders_partner_update" ON public.orders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.regions r
      WHERE r.id = region_id AND r.partner_id = auth.uid()
    )
  );

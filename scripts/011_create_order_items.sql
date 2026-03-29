-- Order items table
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  sku TEXT NOT NULL REFERENCES public.products(sku),
  quantity INTEGER NOT NULL,
  price_in_cents INTEGER NOT NULL
);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Users can read items from their own orders
CREATE POLICY "order_items_select_own" ON public.order_items
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
  );

-- Admin can read all order items
CREATE POLICY "order_items_admin_select" ON public.order_items
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Partners can read order items for their region
CREATE POLICY "order_items_partner_select" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.regions r ON r.id = o.region_id
      WHERE o.id = order_id AND r.partner_id = auth.uid()
    )
  );

-- Users can insert items for their own orders
CREATE POLICY "order_items_insert_own" ON public.order_items
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.orders WHERE id = order_id AND user_id = auth.uid())
  );

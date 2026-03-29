-- Products table: global product catalog
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT UNIQUE NOT NULL,
  product_name TEXT NOT NULL,
  product_description TEXT,
  image_url TEXT,
  category TEXT NOT NULL,
  price_in_cents INTEGER NOT NULL,
  variants JSONB,
  tags TEXT[],
  delivery_eligible BOOLEAN DEFAULT TRUE,
  featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Public read, admin write
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_public_read" ON public.products
  FOR SELECT USING (true);

CREATE POLICY "products_admin_insert" ON public.products
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "products_admin_update" ON public.products
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "products_admin_delete" ON public.products
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

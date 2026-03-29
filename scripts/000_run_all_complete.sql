-- PostGIS extension deferred: using JSONB/lat-lng for geospatial data.
-- When deploying to production Supabase, enable PostGIS via the dashboard
-- and migrate boundary/coordinate columns to geometry types.
-- CREATE EXTENSION IF NOT EXISTS postgis;
SELECT 1;
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
-- Profiles: extends Supabase auth.users with app-specific fields
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  date_of_birth DATE,
  role TEXT DEFAULT 'customer',
  phone TEXT,
  age_verified BOOLEAN DEFAULT FALSE,
  age_verification_method TEXT,
  id_photo_url TEXT,
  id_review_status TEXT DEFAULT 'pending',
  id_reviewed_by UUID,
  id_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);
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
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name)
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', null),
    coalesce(new.raw_user_meta_data ->> 'last_name', null)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
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
-- Create storage bucket for age verification ID photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('age-verification-ids', 'age-verification-ids', false)
ON CONFLICT (id) DO NOTHING;

-- Policy: users can upload their own ID photos
CREATE POLICY "age_verification_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'age-verification-ids'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: users can view their own ID photos
CREATE POLICY "age_verification_view_own" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'age-verification-ids'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: admins can view all ID photos
CREATE POLICY "age_verification_admin_view" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'age-verification-ids'
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );
-- Update orders table to support crypto payments

-- Drop the old payment_method constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;

-- Add updated payment_method constraint including 'crypto'
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_method_check 
  CHECK (payment_method IN ('stripe', 'paypal', 'crypto'));

-- Add optional columns for crypto payment details
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS crypto_charge_code TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tax_cents INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS age_verified BOOLEAN NOT NULL DEFAULT false;

-- Rename payment_id to be more generic (optional, for clarity)
-- This will store Stripe session IDs, PayPal transaction IDs, or Coinbase charge IDs
COMMENT ON COLUMN public.orders.payment_id IS 'Payment provider transaction/session/charge ID';
COMMENT ON COLUMN public.orders.crypto_charge_code IS 'Coinbase Commerce charge code (8-character)';

-- Clover module storage tables
-- Mirrors the Clover module shapes used by frontend types/mocks.

CREATE TABLE IF NOT EXISTS public.clover_merchants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clover_merchant_id TEXT NOT NULL UNIQUE,
  merchant_name TEXT,
  country TEXT,
  currency TEXT,
  timezone TEXT,
  raw_payload JSONB,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.clover_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_customer_id TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  marketing_allowed BOOLEAN,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_customer_id)
);

CREATE TABLE IF NOT EXISTS public.clover_customer_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.clover_customers(id) ON DELETE CASCADE,
  clover_email_id TEXT,
  email_address TEXT NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, email_address)
);

CREATE TABLE IF NOT EXISTS public.clover_customer_phones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.clover_customers(id) ON DELETE CASCADE,
  clover_phone_id TEXT,
  phone_number TEXT NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, phone_number)
);

CREATE TABLE IF NOT EXISTS public.clover_customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.clover_customers(id) ON DELETE CASCADE,
  clover_address_id TEXT,
  address1 TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.clover_employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_employee_id TEXT NOT NULL,
  name TEXT,
  role TEXT,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_employee_id)
);

CREATE TABLE IF NOT EXISTS public.clover_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_category_id TEXT NOT NULL,
  name TEXT NOT NULL,
  sort_order INTEGER,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_category_id)
);

CREATE TABLE IF NOT EXISTS public.clover_discounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_discount_id TEXT NOT NULL,
  name TEXT NOT NULL,
  amount BIGINT,
  percentage BOOLEAN,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_discount_id)
);

CREATE TABLE IF NOT EXISTS public.clover_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_item_id TEXT NOT NULL,
  code TEXT,
  name TEXT NOT NULL,
  description TEXT,
  price BIGINT NOT NULL,
  hidden BOOLEAN,
  stock_count INTEGER,
  quantity INTEGER,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_item_id)
);

CREATE TABLE IF NOT EXISTS public.clover_item_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES public.clover_items(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.clover_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id, category_id)
);

CREATE TABLE IF NOT EXISTS public.clover_stocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES public.clover_items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id)
);

CREATE TABLE IF NOT EXISTS public.clover_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_order_id TEXT NOT NULL,
  state TEXT,
  total BIGINT,
  note TEXT,
  customer_id UUID REFERENCES public.clover_customers(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES public.clover_employees(id) ON DELETE SET NULL,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_order_id)
);

CREATE TABLE IF NOT EXISTS public.clover_order_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.clover_orders(id) ON DELETE CASCADE,
  clover_line_item_id TEXT,
  item_id UUID REFERENCES public.clover_items(id) ON DELETE SET NULL,
  name TEXT,
  price BIGINT,
  quantity INTEGER,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (order_id, clover_line_item_id)
);

CREATE TABLE IF NOT EXISTS public.clover_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.clover_merchants(id) ON DELETE CASCADE,
  clover_payment_id TEXT NOT NULL,
  order_id UUID REFERENCES public.clover_orders(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES public.clover_employees(id) ON DELETE SET NULL,
  amount BIGINT NOT NULL,
  tip_amount BIGINT,
  tax_amount BIGINT,
  cashback_amount BIGINT,
  result TEXT,
  tender_clover_id TEXT,
  tender_label TEXT,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_payment_id)
);

CREATE INDEX IF NOT EXISTS idx_clover_customers_merchant
  ON public.clover_customers (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_employees_merchant
  ON public.clover_employees (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_categories_merchant
  ON public.clover_categories (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_items_merchant
  ON public.clover_items (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_orders_merchant
  ON public.clover_orders (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_payments_merchant
  ON public.clover_payments (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_orders_customer
  ON public.clover_orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_clover_payments_order
  ON public.clover_payments (order_id);

-- Seed sample products across all 6 categories
INSERT INTO public.products (sku, product_name, product_description, category, price_in_cents, delivery_eligible, featured, tags) VALUES
  ('GLASS-001', 'Crystal Clear Beaker Bong', 'Premium 14" beaker bong with ice catcher and percolator. Thick borosilicate glass for durability.', 'glass-pipes-bongs', 7999, true, true, ARRAY['bong', 'beaker', 'glass', 'percolator']),
  ('GLASS-002', 'Emerald Spoon Pipe', 'Hand-blown 4.5" spoon pipe with deep emerald green swirl pattern.', 'glass-pipes-bongs', 2499, true, false, ARRAY['pipe', 'spoon', 'hand pipe']),
  ('GLASS-003', 'Mini Bubbler', 'Compact 6" bubbler with built-in downstem. Perfect for smooth on-the-go hits.', 'glass-pipes-bongs', 3499, true, false, ARRAY['bubbler', 'mini', 'glass']),
  ('GLASS-004', 'Quartz Dab Rig', '8" recycler dab rig with quartz banger included. Medical-grade borosilicate.', 'glass-pipes-bongs', 12999, false, true, ARRAY['dab rig', 'quartz', 'recycler']),

  ('VAPE-001', 'Cloud Chaser Pen', 'Sleek variable voltage vape pen. 510 thread compatible. USB-C charging.', 'vapes-e-cigarettes', 2999, true, true, ARRAY['vape pen', '510 thread', 'battery']),
  ('VAPE-002', 'Ceramic Cartridge 1g', '1 gram empty ceramic cartridge. Lead-free, food-grade materials.', 'vapes-e-cigarettes', 999, true, false, ARRAY['cartridge', 'ceramic', '1g']),
  ('VAPE-003', 'Box Mod 200W', 'Dual 18650 box mod with temperature control. OLED display.', 'vapes-e-cigarettes', 5999, true, false, ARRAY['box mod', '200w', 'temperature control']),
  ('VAPE-004', 'Mango E-Liquid 60ml', 'Premium mango-flavored e-liquid. 70/30 VG/PG. Available in 3mg and 6mg nicotine.', 'vapes-e-cigarettes', 1999, true, false, ARRAY['e-liquid', 'mango', '60ml']),

  ('ROLL-001', 'RAW Classic King Size', 'Unrefined, unbleached king size rolling papers. 32 leaves per pack.', 'rolling-papers-wraps', 399, true, false, ARRAY['rolling papers', 'king size', 'RAW']),
  ('ROLL-002', 'Hemp Blunt Wraps 2-Pack', 'Organic hemp blunt wraps. Slow-burning with natural flavor.', 'rolling-papers-wraps', 299, true, false, ARRAY['blunt wraps', 'hemp', 'organic']),
  ('ROLL-003', 'Pre-Rolled Cones 6-Pack', 'King size pre-rolled cones. Just fill and twist. No rolling skill needed.', 'rolling-papers-wraps', 599, true, true, ARRAY['cones', 'pre-rolled', 'king size']),
  ('ROLL-004', 'Bamboo Rolling Tray', 'Premium bamboo rolling tray with magnetic lid. 7x11 inches.', 'rolling-papers-wraps', 2499, true, false, ARRAY['rolling tray', 'bamboo', 'magnetic']),

  ('ACC-001', '4-Piece Herb Grinder', 'Aircraft-grade aluminum 4-piece grinder with kief catcher. 2.5" diameter.', 'accessories', 1999, true, true, ARRAY['grinder', 'aluminum', 'kief catcher']),
  ('ACC-002', 'Torch Lighter', 'Refillable butane torch lighter with adjustable flame. Wind resistant.', 'accessories', 1499, true, false, ARRAY['lighter', 'torch', 'butane']),
  ('ACC-003', 'Smell-Proof Stash Jar', 'UV-protected glass stash jar with airtight silicone seal. 4oz capacity.', 'accessories', 1299, true, false, ARRAY['storage', 'jar', 'smell-proof']),
  ('ACC-004', 'Silicone Ashtray', 'Heat-resistant silicone ashtray with built-in snuffer. Unbreakable design.', 'accessories', 899, true, false, ARRAY['ashtray', 'silicone', 'heat-resistant']),

  ('CBD-001', 'CBD Gummies 30ct', 'Full-spectrum CBD gummies. 25mg per gummy. Mixed fruit flavors.', 'cbd-delta-products', 3999, true, true, ARRAY['CBD', 'gummies', 'full-spectrum', 'edibles']),
  ('CBD-002', 'Delta-8 Cartridge 1g', '1 gram Delta-8 THC cartridge. Strain-specific terpenes. Lab tested.', 'cbd-delta-products', 2999, true, false, ARRAY['delta-8', 'cartridge', '1g']),
  ('CBD-003', 'CBD Tincture 1000mg', 'Organic CBD oil tincture. 1000mg in 30ml dropper bottle. Natural flavor.', 'cbd-delta-products', 4999, true, false, ARRAY['CBD', 'tincture', 'oil', '1000mg']),
  ('CBD-004', 'CBD Flower 3.5g', 'Premium indoor-grown CBD flower. Under 0.3% THC. Multiple strains available.', 'cbd-delta-products', 2499, false, false, ARRAY['CBD', 'flower', 'hemp']),

  ('CANN-001', 'OG Kush - Indica 3.5g', 'Classic OG Kush. Dense, trichome-rich buds. Earthy pine aroma.', 'cannabis-flower', 3999, false, true, ARRAY['indica', 'OG Kush', '3.5g']),
  ('CANN-002', 'Sour Diesel - Sativa 3.5g', 'Energizing Sour Diesel. Pungent diesel aroma with citrus undertones.', 'cannabis-flower', 4499, false, false, ARRAY['sativa', 'Sour Diesel', '3.5g']),
  ('CANN-003', 'Blue Dream - Hybrid 3.5g', 'Balanced Blue Dream hybrid. Sweet berry aroma. Smooth smoke.', 'cannabis-flower', 4299, false, false, ARRAY['hybrid', 'Blue Dream', '3.5g']),
  ('CANN-004', 'Pre-Roll Pack 5ct', 'Assorted pre-rolls. 0.5g each. Mix of indica and sativa strains.', 'cannabis-flower', 2999, false, true, ARRAY['pre-rolls', 'variety pack', '5ct'])
ON CONFLICT (sku) DO NOTHING;

-- Seed sample regions for Missouri (GeoJSON polygons around major metro areas)
INSERT INTO public.regions (id, region_name, state, boundary, center_lat, center_lng, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Kansas City Metro', 'MO',
   '{"type":"Polygon","coordinates":[[[-94.77,39.12],[-94.77,38.88],[-94.40,38.88],[-94.40,39.12],[-94.77,39.12]]]}',
   39.0, -94.585, true),
  ('b2222222-2222-2222-2222-222222222222', 'St. Louis Metro', 'MO',
   '{"type":"Polygon","coordinates":[[[-90.50,38.75],[-90.50,38.52],[-90.10,38.52],[-90.10,38.75],[-90.50,38.75]]]}',
   38.635, -90.3, true),
  ('c3333333-3333-3333-3333-333333333333', 'Springfield Area', 'MO',
   '{"type":"Polygon","coordinates":[[[-93.40,37.28],[-93.40,37.12],[-93.15,37.12],[-93.15,37.28],[-93.40,37.28]]]}',
   37.2, -93.275, true),
  ('d4444444-4444-4444-4444-444444444444', 'Columbia Area', 'MO',
   '{"type":"Polygon","coordinates":[[[-92.45,39.02],[-92.45,38.88],[-92.20,38.88],[-92.20,39.02],[-92.45,39.02]]]}',
   38.95, -92.325, true)
ON CONFLICT (id) DO NOTHING;

-- Seed pickup locations (using lat/lng columns)
INSERT INTO public.pickup_locations (id, location_name, address, state, lat, lng, is_active) VALUES
  ('e5555555-5555-5555-5555-555555555555', 'Generic Smokeshop - Downtown KC', '123 Main St, Kansas City, MO 64106', 'MO',
   39.0997, -94.5786, true),
  ('f6666666-6666-6666-6666-666666666666', 'Generic Smokeshop - St. Louis', '456 Market St, St. Louis, MO 63101', 'MO',
   38.6270, -90.1994, true),
  ('77777777-7777-7777-7777-777777777777', 'Generic Smokeshop - Springfield', '789 Commercial St, Springfield, MO 65803', 'MO',
   37.2090, -93.2923, true)
ON CONFLICT (id) DO NOTHING;

-- Seed region inventory (KC has everything, StL has most, Springfield limited)
INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'a1111111-1111-1111-1111-111111111111'::uuid, 50
FROM public.products p WHERE p.delivery_eligible = true
ON CONFLICT (sku, region_id) DO NOTHING;

INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'b2222222-2222-2222-2222-222222222222'::uuid, 30
FROM public.products p WHERE p.delivery_eligible = true
ON CONFLICT (sku, region_id) DO NOTHING;

INSERT INTO public.region_inventory (sku, region_id, quantity)
SELECT p.sku, 'c3333333-3333-3333-3333-333333333333'::uuid, 15
FROM public.products p WHERE p.delivery_eligible = true AND p.category IN ('vapes-e-cigarettes', 'rolling-papers-wraps', 'accessories')
ON CONFLICT (sku, region_id) DO NOTHING;

-- Seed pickup inventory (all products at KC/StL, limited at Springfield)
INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, 'e5555555-5555-5555-5555-555555555555'::uuid, 40
FROM public.products p
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, 'f6666666-6666-6666-6666-666666666666'::uuid, 25
FROM public.products p
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

INSERT INTO public.pickup_inventory (sku, pickup_location_id, quantity)
SELECT p.sku, '77777777-7777-7777-7777-777777777777'::uuid, 10
FROM public.products p WHERE p.category IN ('vapes-e-cigarettes', 'rolling-papers-wraps', 'accessories', 'glass-pipes-bongs')
ON CONFLICT (sku, pickup_location_id) DO NOTHING;

-- Seed delivery fee tiers for KC and StL
INSERT INTO public.delivery_fee_tiers (region_id, tier_name, fee_cents, estimated_minutes_min, estimated_minutes_max, sort_order, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Express (Under 1 Hour)', 1499, 30, 60, 1, true),
  ('a1111111-1111-1111-1111-111111111111', 'Same Day', 899, 120, 360, 2, true),
  ('a1111111-1111-1111-1111-111111111111', 'Next Day', 499, 1440, 2880, 3, true),
  ('b2222222-2222-2222-2222-222222222222', 'Express (Under 1 Hour)', 1499, 30, 60, 1, true),
  ('b2222222-2222-2222-2222-222222222222', 'Same Day', 999, 120, 360, 2, true),
  ('b2222222-2222-2222-2222-222222222222', 'Next Day', 599, 1440, 2880, 3, true),
  ('c3333333-3333-3333-3333-333333333333', 'Same Day', 1299, 180, 480, 1, true),
  ('c3333333-3333-3333-3333-333333333333', 'Next Day', 799, 1440, 2880, 2, true)
ON CONFLICT DO NOTHING;

-- Seed delivery slots for KC
INSERT INTO public.delivery_slots (region_id, day_of_week, start_time, end_time, fee_cents, max_orders, is_active) VALUES
  ('a1111111-1111-1111-1111-111111111111', 1, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 1, '14:00', '18:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 3, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 3, '14:00', '18:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 5, '10:00', '14:00', 699, 10, true),
  ('a1111111-1111-1111-1111-111111111111', 5, '14:00', '18:00', 699, 10, true)
ON CONFLICT DO NOTHING;

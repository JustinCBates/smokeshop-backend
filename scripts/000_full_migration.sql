-- ============================================================================
-- FULL DATABASE MIGRATION - Run this entire file in Supabase SQL Editor
-- ============================================================================
-- This combines all migration scripts in the correct order
-- ============================================================================

-- STEP 1: Enable PostGIS (already done, but safe to run again)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- STEP 2: CREATE PROFILES TABLE AND SETUP
-- ============================================================================

-- From 009_create_profiles.sql
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- From 009b_profiles_rls.sql
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- From 009c_profiles_trigger.sql
-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Create function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 3: CREATE PRODUCTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.products (
  id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  in_stock BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to products" ON public.products;
CREATE POLICY "Allow public read access to products"
  ON public.products FOR SELECT
  TO public
  USING (true);

-- ============================================================================
-- STEP 4: CREATE REGIONS TABLE (with PostGIS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.regions (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  geometry GEOMETRY(POLYGON, 4326) NOT NULL,
  delivery_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to regions" ON public.regions;
CREATE POLICY "Allow public read access to regions"
  ON public.regions FOR SELECT
  TO public
  USING (true);

-- Create spatial index
CREATE INDEX IF NOT EXISTS idx_regions_geometry ON public.regions USING GIST (geometry);

-- ============================================================================
-- STEP 5: CREATE REGION_INVENTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.region_inventory (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  UNIQUE(region_id, product_id)
);

-- Enable RLS
ALTER TABLE public.region_inventory ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to region_inventory" ON public.region_inventory;
CREATE POLICY "Allow public read access to region_inventory"
  ON public.region_inventory FOR SELECT
  TO public
  USING (true);

-- ============================================================================
-- STEP 6: CREATE PICKUP_LOCATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pickup_locations (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  zip TEXT NOT NULL,
  location GEOMETRY(POINT, 4326) NOT NULL,
  phone TEXT,
  hours TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.pickup_locations ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to pickup_locations" ON public.pickup_locations;
CREATE POLICY "Allow public read access to pickup_locations"
  ON public.pickup_locations FOR SELECT
  TO public
  USING (true);

-- Create spatial index
CREATE INDEX IF NOT EXISTS idx_pickup_locations_location ON public.pickup_locations USING GIST (location);

-- ============================================================================
-- STEP 7: CREATE PICKUP_INVENTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pickup_inventory (
  id SERIAL PRIMARY KEY,
  location_id INTEGER REFERENCES public.pickup_locations(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  UNIQUE(location_id, product_id)
);

-- Enable RLS
ALTER TABLE public.pickup_inventory ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to pickup_inventory" ON public.pickup_inventory;
CREATE POLICY "Allow public read access to pickup_inventory"
  ON public.pickup_inventory FOR SELECT
  TO public
  USING (true);

-- ============================================================================
-- STEP 8: CREATE DELIVERY_FEE_TIERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.delivery_fee_tiers (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  min_distance_miles DECIMAL(5, 2) NOT NULL,
  max_distance_miles DECIMAL(5, 2),
  fee DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.delivery_fee_tiers ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to delivery_fee_tiers" ON public.delivery_fee_tiers;
CREATE POLICY "Allow public read access to delivery_fee_tiers"
  ON public.delivery_fee_tiers FOR SELECT
  TO public
  USING (true);

-- ============================================================================
-- STEP 9: CREATE DELIVERY_SLOTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.delivery_slots (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.delivery_slots ENABLE ROW LEVEL SECURITY;

-- Allow public read access
DROP POLICY IF EXISTS "Allow public read access to delivery_slots" ON public.delivery_slots;
CREATE POLICY "Allow public read access to delivery_slots"
  ON public.delivery_slots FOR SELECT
  TO public
  USING (true);

-- ============================================================================
-- STEP 10: CREATE ORDERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  fulfillment_type TEXT NOT NULL CHECK (fulfillment_type IN ('delivery', 'pickup')),
  delivery_address TEXT,
  delivery_city TEXT,
  delivery_state TEXT,
  delivery_zip TEXT,
  delivery_location GEOMETRY(POINT, 4326),
  pickup_location_id INTEGER REFERENCES public.pickup_locations(id),
  delivery_slot_id INTEGER REFERENCES public.delivery_slots(id),
  delivery_fee DECIMAL(10, 2),
  subtotal DECIMAL(10, 2) NOT NULL,
  total DECIMAL(10, 2) NOT NULL,
  payment_status TEXT DEFAULT 'pending',
  payment_method TEXT,
  payment_id TEXT,
  coinbase_charge_id TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;

CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders"
  ON public.orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- STEP 11: CREATE ORDER_ITEMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.order_items (
  id SERIAL PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id),
  quantity INTEGER NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Policy
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- ============================================================================
-- STEP 12: CREATE STORAGE BUCKET
-- ============================================================================

-- Insert storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to product images
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;
CREATE POLICY "Public can view product images"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'products');

-- ============================================================================
-- STEP 13: ADD GUEST CHECKOUT SUPPORT
-- ============================================================================

-- Make user_id nullable for guest orders
ALTER TABLE public.orders ALTER COLUMN user_id DROP NOT NULL;

-- Add guest contact fields
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_name TEXT;

-- Add constraint: either user_id or guest_email must be present
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'orders_user_or_guest_check'
  ) THEN
    ALTER TABLE public.orders 
    ADD CONSTRAINT orders_user_or_guest_check 
    CHECK (user_id IS NOT NULL OR guest_email IS NOT NULL);
  END IF;
END $$;

-- Update RLS policies for guest access
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Guests can view orders by email and id" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Guests can insert orders" ON public.orders;

CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Guests can view orders by email and id"
  ON public.orders FOR SELECT
  USING (guest_email IS NOT NULL);

CREATE POLICY "Users can insert own orders"
  ON public.orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Guests can insert orders"
  ON public.orders FOR INSERT
  WITH CHECK (guest_email IS NOT NULL);

-- Update order_items policy for guest orders
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Guests can view order items" ON public.order_items;

CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Guests can view order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.guest_email IS NOT NULL
    )
  );

-- ============================================================================
-- STEP 14: SEED SAMPLE DATA
-- ============================================================================

-- Insert sample products
INSERT INTO public.products (sku, name, description, category, price, in_stock) VALUES
('CBD-FLOWER-001', 'CBD Hemp Flower - Lifter', 'High CBD, low THC hemp flower. Uplifting effects.', 'cbd-delta-products', 29.99, true),
('CBD-FLOWER-002', 'CBD Hemp Flower - Elektra', 'Premium CBD flower with citrus notes.', 'cbd-delta-products', 34.99, true),
('CBD-EDIBLE-001', 'CBD Gummies 25mg - Mixed Fruit', '30 count bottle, 25mg CBD per gummy.', 'cbd-delta-products', 39.99, true),
('CBD-TINCTURE-001', 'Full Spectrum CBD Oil 1000mg', '30ml bottle with dropper.', 'cbd-delta-products', 59.99, true),
('DELTA8-CART-001', 'Delta-8 THC Vape Cart - Pineapple', '1ml cart, premium distillate.', 'cbd-delta-products', 44.99, true),
('DELTA8-GUMMY-001', 'Delta-8 Gummies 25mg', '20 count, tropical flavors.', 'cbd-delta-products', 49.99, true),
('FLOWER-IND-001', 'Granddaddy Purple - Indica', 'Classic indica, relaxing effects. 20% THC.', 'cannabis-flower', 45.00, true),
('FLOWER-IND-002', 'Northern Lights - Indica', 'Legendary strain, full body relaxation. 18% THC.', 'cannabis-flower', 40.00, true),
('FLOWER-SAT-001', 'Sour Diesel - Sativa', 'Energizing sativa, citrus aroma. 22% THC.', 'cannabis-flower', 50.00, true),
('FLOWER-SAT-002', 'Green Crack - Sativa', 'Sharp focus and energy. 21% THC.', 'cannabis-flower', 48.00, true),
('FLOWER-HYB-001', 'Blue Dream - Hybrid', 'Balanced hybrid, fruity flavor. 19% THC.', 'cannabis-flower', 42.00, true),
('FLOWER-HYB-002', 'Wedding Cake - Hybrid', 'Sweet flavor, relaxing yet uplifting. 24% THC.', 'cannabis-flower', 55.00, true),
('PREROLL-IND-001', 'Indica Pre-Roll 2-Pack', 'Premium indica flower, ready to smoke.', 'cannabis-flower', 18.00, true),
('PREROLL-SAT-001', 'Sativa Pre-Roll 2-Pack', 'Energizing sativa, perfectly rolled.', 'cannabis-flower', 18.00, true),
('PREROLL-MIX-001', 'Mixed Pre-Roll 5-Pack', 'Variety pack of indica, sativa, hybrid.', 'cannabis-flower', 40.00, true),
('CONC-SHATTER-001', 'Indica Shatter - 1g', 'Glass-like concentrate, 85% THC.', 'concentrates-extracts', 35.00, true),
('CONC-WAX-001', 'Hybrid Wax - 1g', 'Smooth texture, rich terpenes. 80% THC.', 'concentrates-extracts', 32.00, true),
('CONC-LIVE-001', 'Live Resin - 1g', 'Fresh frozen flower extraction. 88% THC.', 'concentrates-extracts', 50.00, true),
('EDIBLE-GUMMY-001', 'THC Gummies 10mg - Assorted', '10 count, fruit flavors.', 'edibles', 25.00, true),
('EDIBLE-CHOC-001', 'THC Dark Chocolate Bar 100mg', 'Premium Belgian chocolate, 10 pieces.', 'edibles', 20.00, true),
('EDIBLE-COOKIE-001', 'THC Cookie 50mg', 'Chocolate chip cookie, single serve.', 'edibles', 12.00, true),
('ACC-GRINDER-001', '4-Piece Metal Grinder', 'Durable aluminum grinder with kief catcher.', 'accessories', 19.99, true),
('ACC-PIPE-001', 'Glass Hand Pipe', 'Quality borosilicate glass, assorted colors.', 'accessories', 24.99, true),
('ACC-PAPERS-001', 'Rolling Papers King Size', 'Premium hemp papers, 32 leaves per pack.', 'accessories', 5.99, true)
ON CONFLICT (sku) DO NOTHING;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- You can now verify the setup by running:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- ============================================================================

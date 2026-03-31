-- ============================================================================
-- DATABASE SCHEMA AND DATA - Run this AFTER 000a_postgis_setup.sql
-- ============================================================================
-- Prerequisites: PostGIS extension must be enabled
-- ============================================================================

-- Ensure we're using the public schema and PostGIS is available
SET search_path TO public, extensions;

-- Verify PostGIS is available before proceeding
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE EXCEPTION 'PostGIS extension is not enabled. Run Step 1 first!';
  END IF;
END $$;

-- ============================================================================
-- STEP 1: CREATE PROFILES TABLE AND SETUP
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

-- Create function to handle new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name'
  );
  RETURN new;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 2: CREATE PRODUCTS TABLE
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
-- STEP 3: CREATE REGIONS TABLE (with PostGIS)
-- ============================================================================

-- Verify geometry type is available
DO $$
BEGIN
  -- This will fail if PostGIS isn't loaded
  EXECUTE 'SELECT ''POINT(0 0)''::geometry';
EXCEPTION
  WHEN undefined_object THEN
    RAISE EXCEPTION 'PostGIS geometry type not available. Run: CREATE EXTENSION postgis;';
END $$;

CREATE TABLE IF NOT EXISTS public.regions (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  geometry geometry(POLYGON, 4326) NOT NULL,
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
DROP INDEX IF EXISTS idx_regions_geometry;
CREATE INDEX idx_regions_geometry ON public.regions USING GIST (geometry);

-- ============================================================================
-- STEP 4: CREATE REGION_INVENTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.region_inventory (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
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
-- STEP 5: CREATE PICKUP_LOCATIONS TABLE (with PostGIS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pickup_locations (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  location geometry(POINT, 4326) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  hours TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
DROP INDEX IF EXISTS idx_pickup_locations_location;
CREATE INDEX idx_pickup_locations_location ON public.pickup_locations USING GIST (location);

-- ============================================================================
-- STEP 6: CREATE PICKUP_INVENTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pickup_inventory (
  id SERIAL PRIMARY KEY,
  location_id INTEGER REFERENCES public.pickup_locations(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
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
-- STEP 7: CREATE DELIVERY_FEE_TIERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.delivery_fee_tiers (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  min_distance_km DECIMAL(10, 2) NOT NULL,
  max_distance_km DECIMAL(10, 2) NOT NULL,
  fee DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
-- STEP 8: CREATE DELIVERY_SLOTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.delivery_slots (
  id SERIAL PRIMARY KEY,
  region_id INTEGER REFERENCES public.regions(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  max_orders INTEGER DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
-- STEP 9: CREATE ORDERS TABLE (with guest support)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  order_number TEXT UNIQUE NOT NULL,
  
  -- Guest order fields (nullable for authenticated users)
  guest_email TEXT,
  guest_phone TEXT,
  guest_name TEXT,
  
  status TEXT NOT NULL DEFAULT 'pending',
  total DECIMAL(10, 2) NOT NULL,
  delivery_fee DECIMAL(10, 2) DEFAULT 0,
  delivery_address TEXT,
  delivery_type TEXT NOT NULL CHECK (delivery_type IN ('delivery', 'pickup')),
  pickup_location_id INTEGER REFERENCES public.pickup_locations(id) ON DELETE SET NULL,
  delivery_slot_id INTEGER REFERENCES public.delivery_slots(id) ON DELETE SET NULL,
  notes TEXT,
  
  -- Payment fields
  payment_status TEXT DEFAULT 'pending',
  payment_method TEXT,
  coinbase_charge_id TEXT,
  coinbase_charge_code TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraint: must have either user_id OR guest_email
  CONSTRAINT check_user_or_guest CHECK (
    (user_id IS NOT NULL) OR 
    (guest_email IS NOT NULL AND guest_phone IS NOT NULL AND guest_name IS NOT NULL)
  )
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Guests can view own orders by email" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
DROP POLICY IF EXISTS "Guests can create orders" ON public.orders;

-- Policies for authenticated users
CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON public.orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policies for guest orders
CREATE POLICY "Guests can view own orders by email"
  ON public.orders FOR SELECT
  USING (
    guest_email IS NOT NULL AND 
    auth.uid() IS NULL
  );

CREATE POLICY "Guests can create orders"
  ON public.orders FOR INSERT
  WITH CHECK (
    guest_email IS NOT NULL AND 
    guest_phone IS NOT NULL AND 
    guest_name IS NOT NULL AND
    user_id IS NULL
  );

-- Create index on order_number for guest order lookup
DROP INDEX IF EXISTS idx_orders_order_number;
CREATE INDEX idx_orders_order_number ON public.orders(order_number);

-- Create index on guest_email for guest order queries
DROP INDEX IF EXISTS idx_orders_guest_email;
CREATE INDEX idx_orders_guest_email ON public.orders(guest_email);

-- ============================================================================
-- STEP 10: CREATE ORDER_ITEMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.order_items (
  id SERIAL PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES public.products(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;

-- Allow users to view their own order items
CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND (orders.user_id = auth.uid() OR orders.guest_email IS NOT NULL)
    )
  );

-- Allow users to create order items for their own orders
CREATE POLICY "Users can create own order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND (orders.user_id = auth.uid() OR orders.guest_email IS NOT NULL)
    )
  );

-- ============================================================================
-- STEP 11: SEED SAMPLE DATA
-- ============================================================================

-- Insert sample products (24 products across 4 categories)
INSERT INTO public.products (sku, name, description, category, price, image_url, in_stock) VALUES
  -- Flower (8 products)
  ('FLW001', 'Blue Dream', 'Classic sativa-dominant hybrid with sweet berry aroma', 'flower', 35.00, '/images/products/blue-dream.webp', true),
  ('FLW002', 'OG Kush', 'Legendary indica-dominant strain with earthy pine notes', 'flower', 40.00, '/images/products/og-kush.webp', true),
  ('FLW003', 'Girl Scout Cookies', 'Popular hybrid with sweet and earthy flavors', 'flower', 45.00, '/images/products/girl-scout-cookies.webp', true),
  ('FLW004', 'Sour Diesel', 'Energizing sativa with diesel aroma', 'flower', 38.00, '/images/products/sour-diesel.webp', true),
  ('FLW005', 'Granddaddy Purple', 'Relaxing indica with grape and berry notes', 'flower', 42.00, '/images/products/granddaddy-purple.webp', true),
  ('FLW006', 'Jack Herer', 'Uplifting sativa named after cannabis activist', 'flower', 40.00, '/images/products/jack-herer.webp', true),
  ('FLW007', 'Wedding Cake', 'Potent hybrid with vanilla and earthy flavors', 'flower', 48.00, '/images/products/wedding-cake.webp', true),
  ('FLW008', 'Northern Lights', 'Classic indica for relaxation', 'flower', 36.00, '/images/products/northern-lights.webp', true),
  
  -- Edibles (8 products)
  ('EDB001', 'Gummy Bears 100mg', 'Assorted fruit flavored gummies, 10mg per piece', 'edibles', 25.00, '/images/products/gummy-bears.webp', true),
  ('EDB002', 'Chocolate Bar 200mg', 'Premium dark chocolate infused with THC', 'edibles', 30.00, '/images/products/chocolate-bar.webp', true),
  ('EDB003', 'Cookie Bites 150mg', 'Chocolate chip cookie bites, 15mg each', 'edibles', 28.00, '/images/products/cookie-bites.webp', true),
  ('EDB004', 'Hard Candy 100mg', 'Long-lasting hard candies in mixed flavors', 'edibles', 22.00, '/images/products/hard-candy.webp', true),
  ('EDB005', 'Brownie Squares 250mg', 'Fudgy brownies with rich chocolate flavor', 'edibles', 35.00, '/images/products/brownie-squares.webp', true),
  ('EDB006', 'Mints 50mg', 'Discreet breath mints, 5mg each', 'edibles', 18.00, '/images/products/mints.webp', true),
  ('EDB007', 'Caramels 100mg', 'Soft caramels with sea salt, 10mg each', 'edibles', 26.00, '/images/products/caramels.webp', true),
  ('EDB008', 'Fruit Chews 150mg', 'Chewy taffy-style candies', 'edibles', 24.00, '/images/products/fruit-chews.webp', true),
  
  -- Concentrates (4 products)
  ('CON001', 'Live Resin Cart - Hybrid', 'Premium live resin cartridge, 1g', 'concentrates', 55.00, '/images/products/live-resin-cart.webp', true),
  ('CON002', 'Shatter - Sativa', 'High-quality shatter concentrate, 1g', 'concentrates', 45.00, '/images/products/shatter.webp', true),
  ('CON003', 'Wax - Indica', 'Smooth wax concentrate, 1g', 'concentrates', 50.00, '/images/products/wax.webp', true),
  ('CON004', 'Distillate Syringe', 'Pure THC distillate, 1g syringe', 'concentrates', 60.00, '/images/products/distillate.webp', true),
  
  -- Pre-rolls (4 products)
  ('PRE001', 'Indica Pre-Roll 5pk', 'Five premium indica pre-rolls', 'pre-rolls', 32.00, '/images/products/indica-preroll.webp', true),
  ('PRE002', 'Sativa Pre-Roll 5pk', 'Five energizing sativa pre-rolls', 'pre-rolls', 32.00, '/images/products/sativa-preroll.webp', true),
  ('PRE003', 'Hybrid Pre-Roll 5pk', 'Five balanced hybrid pre-rolls', 'pre-rolls', 32.00, '/images/products/hybrid-preroll.webp', true),
  ('PRE004', 'Infused Pre-Roll 3pk', 'Three diamond-infused premium pre-rolls', 'pre-rolls', 45.00, '/images/products/infused-preroll.webp', true)
ON CONFLICT (sku) DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration completed successfully! Database is ready.';
END $$;

-- Add guest checkout support to orders table

-- Make user_id nullable (allow guest orders)
ALTER TABLE public.orders ALTER COLUMN user_id DROP NOT NULL;

-- Add guest contact information
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_email TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS guest_name TEXT;

-- Add constraint: either user_id OR guest_email must be present
ALTER TABLE public.orders ADD CONSTRAINT orders_user_or_guest_check 
  CHECK (user_id IS NOT NULL OR guest_email IS NOT NULL);

-- Update RLS policies to allow guests to insert orders
DROP POLICY IF EXISTS "orders_insert_own" ON public.orders;

CREATE POLICY "orders_insert_authenticated" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "orders_insert_guest" ON public.orders
  FOR INSERT WITH CHECK (user_id IS NULL AND guest_email IS NOT NULL);

-- Allow guests to view their own orders by email
CREATE POLICY "orders_select_guest" ON public.orders
  FOR SELECT USING (
    user_id IS NULL AND 
    guest_email IS NOT NULL
  );

-- Update existing select policy to not conflict
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;

CREATE POLICY "orders_select_own_authenticated" ON public.orders
  FOR SELECT USING (auth.uid() = user_id AND user_id IS NOT NULL);

-- Comment for documentation
COMMENT ON COLUMN public.orders.guest_email IS 'Email for guest checkout orders (when user_id is null)';
COMMENT ON COLUMN public.orders.guest_phone IS 'Phone for guest checkout orders (when user_id is null)';
COMMENT ON COLUMN public.orders.guest_name IS 'Name for guest checkout orders (when user_id is null)';

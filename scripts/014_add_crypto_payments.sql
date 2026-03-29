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

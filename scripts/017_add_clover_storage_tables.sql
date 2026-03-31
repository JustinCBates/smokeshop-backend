-- Clover module storage tables
-- Mirrors the Clover module shapes used by frontend types/mocks.

CREATE TABLE IF NOT EXISTS clover.merchants (
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

CREATE TABLE IF NOT EXISTS clover.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS clover.customer_emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES clover.customers(id) ON DELETE CASCADE,
  clover_email_id TEXT,
  email_address TEXT NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, email_address)
);

CREATE TABLE IF NOT EXISTS clover.customer_phones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES clover.customers(id) ON DELETE CASCADE,
  clover_phone_id TEXT,
  phone_number TEXT NOT NULL,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, phone_number)
);

CREATE TABLE IF NOT EXISTS clover.customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES clover.customers(id) ON DELETE CASCADE,
  clover_address_id TEXT,
  address1 TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clover.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS clover.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS clover.discounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS clover.items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
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

CREATE TABLE IF NOT EXISTS clover.item_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES clover.items(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES clover.categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id, category_id)
);

CREATE TABLE IF NOT EXISTS clover.stocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES clover.items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (item_id)
);

CREATE TABLE IF NOT EXISTS clover.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
  clover_order_id TEXT NOT NULL,
  state TEXT,
  total BIGINT,
  note TEXT,
  customer_id UUID REFERENCES clover.customers(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES clover.employees(id) ON DELETE SET NULL,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (merchant_id, clover_order_id)
);

CREATE TABLE IF NOT EXISTS clover.order_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES clover.orders(id) ON DELETE CASCADE,
  clover_line_item_id TEXT,
  item_id UUID REFERENCES clover.items(id) ON DELETE SET NULL,
  name TEXT,
  price BIGINT,
  quantity INTEGER,
  clover_created_time BIGINT,
  clover_modified_time BIGINT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (order_id, clover_line_item_id)
);

CREATE TABLE IF NOT EXISTS clover.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES clover.merchants(id) ON DELETE CASCADE,
  clover_payment_id TEXT NOT NULL,
  order_id UUID REFERENCES clover.orders(id) ON DELETE SET NULL,
  employee_id UUID REFERENCES clover.employees(id) ON DELETE SET NULL,
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
  ON clover.customers (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_employees_merchant
  ON clover.employees (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_categories_merchant
  ON clover.categories (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_items_merchant
  ON clover.items (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_orders_merchant
  ON clover.orders (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_payments_merchant
  ON clover.payments (merchant_id);

CREATE INDEX IF NOT EXISTS idx_clover_orders_customer
  ON clover.orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_clover_payments_order
  ON clover.payments (order_id);

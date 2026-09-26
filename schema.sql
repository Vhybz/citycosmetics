-- =====================================================
-- COMPLETE SUPABASE SCHEMA FOR CITY POS / COSMETICS
-- Includes all identity, inventory, sales, logistics,
-- payroll, butchery, CRM, and audit tables.
-- =====================================================

-- 1. NUCLEAR RESET (Optional: Wipe and start fresh)
-- Uncomment the two lines below if you want a complete clean slate reset
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- Restore standard schema permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 2. CORE IDENTITY TABLES
-- =====================================================

-- BRANCHES (Shop/Location Registration)
CREATE TABLE IF NOT EXISTS public.branches (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  admin_id UUID,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- USERS (Staff & Admin Profiles)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  surname TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  gender TEXT,
  dob DATE,
  photo_url TEXT,
  role TEXT NOT NULL,
  branch_code TEXT REFERENCES public.branches(code),
  secondary_roles TEXT[] DEFAULT '{}',
  shop_location TEXT,
  status TEXT NOT NULL DEFAULT 'approved',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  last_seen TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,
  temporary_role TEXT,
  temp_role_start TIMESTAMPTZ,
  temp_role_end TIMESTAMPTZ,
  enabled_permissions TEXT[] DEFAULT '{"/settings"}',
  newly_added_permissions TEXT[] DEFAULT '{}',
  salary_amount DECIMAL(10,2),
  salary_day INT,
  last_salary_date DATE,
  last_payment_was_advance BOOLEAN DEFAULT false,
  theme_mode TEXT DEFAULT 'system',
  theme_primary_color BIGINT,
  passcode TEXT,
  passcode_sent_at TIMESTAMPTZ,
  is_passcode_enabled BOOLEAN DEFAULT false,
  total_salary_paid DECIMAL(10,2) DEFAULT 0.00,
  total_advances_taken DECIMAL(10,2) DEFAULT 0.00
);

-- =====================================================
-- 3. INVENTORY & RETAIL TABLES
-- =====================================================

-- PRODUCTS (Master Inventory)
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  name TEXT NOT NULL,
  retail_price DECIMAL(10,2) NOT NULL,
  wholesale_price DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) DEFAULT 0,
  retail_brackets JSONB DEFAULT '[]',
  wholesale_brackets JSONB DEFAULT '[]',
  image_url TEXT,
  category TEXT NOT NULL,
  stock_quantity DECIMAL(10,2) DEFAULT 0,
  unit TEXT DEFAULT 'kg',
  discount_percentage DECIMAL(10,2) DEFAULT 0,
  promo_start TIMESTAMPTZ,
  promo_end TIMESTAMPTZ,
  promo_target TEXT DEFAULT 'both',
  promo_customer_target TEXT DEFAULT 'all',
  target_customer_id TEXT,
  is_deleted BOOLEAN DEFAULT false,
  low_stock_threshold DECIMAL(10,2) DEFAULT 5.0,
  daily_stock_added DECIMAL(10,2) DEFAULT 0,
  is_unlimited BOOLEAN DEFAULT false,
  last_stock_update TIMESTAMPTZ
);

-- SALES (Transactions)
CREATE TABLE IF NOT EXISTS public.sales (
  id TEXT PRIMARY KEY,
  branch_code TEXT REFERENCES public.branches(code),
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL,
  cashier_id UUID REFERENCES public.users(id),
  cashier_name TEXT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  total_discount DECIMAL(10,2) DEFAULT 0,
  total_cost DECIMAL(10,2) DEFAULT 0,
  applied_promo TEXT,
  customer_name TEXT,
  customer_phone TEXT,
  status TEXT DEFAULT 'completed',
  correction_reason TEXT,
  bank_receipt_url TEXT,
  bank_receipt_id TEXT,
  items JSONB NOT NULL,
  payments JSONB NOT NULL,
  is_verified BOOLEAN DEFAULT false
);

-- =====================================================
-- 4. BUTCHERY, WAREHOUSE & PRODUCTION TABLES
-- =====================================================

-- ANIMALS (Farm/Supply Intake)
CREATE TABLE IF NOT EXISTS public.animals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  tag_number TEXT,
  manual_farm_tag TEXT,
  type TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  purchase_price DECIMAL(10,2) DEFAULT 0,
  source_farm TEXT,
  status TEXT DEFAULT 'waiting',
  arrival_time TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- SLAUGHTER LOGS (Processing / Intake Logs)
CREATE TABLE IF NOT EXISTS public.slaughter_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  animal_id UUID REFERENCES public.animals(id),
  tag_number TEXT,
  manual_farm_tag TEXT,
  type TEXT NOT NULL,
  quantity INT DEFAULT 1,
  initial_weight DECIMAL(10,2) NOT NULL,
  price DECIMAL(10,2) DEFAULT 0,
  farm_price DECIMAL(10,2) DEFAULT 0,
  slaughter_time TIMESTAMPTZ,
  carcass_weight DECIMAL(10,2),
  status TEXT DEFAULT 'pending',
  chicken_range_label TEXT,
  source_farm TEXT,
  slaughtered_by TEXT,
  portioned_by TEXT
);

-- MEAT BATCHES (Production Floor / Warehouse Batches)
CREATE TABLE IF NOT EXISTS public.meat_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  animal_id UUID REFERENCES public.animals(id),
  meat_type TEXT NOT NULL,
  batch_number TEXT,
  category TEXT DEFAULT 'Cosmetics',
  initial_weight DECIMAL(10,2) NOT NULL,
  current_weight DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) DEFAULT 0,
  retail_price DECIMAL(10,2) DEFAULT 0.00,
  status TEXT DEFAULT 'transporting',
  source_name TEXT,
  source_location TEXT,
  owner_name TEXT,
  inspected_by TEXT,
  received_by TEXT,
  portioned_by TEXT,
  expiry_date TIMESTAMPTZ,
  shelf_location TEXT,
  barcode TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- MEAT CUTS (Portioned Internal Stock)
CREATE TABLE IF NOT EXISTS public.meat_cuts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  batch_id UUID REFERENCES public.meat_batches(id),
  name TEXT NOT NULL,
  meat_type TEXT,
  weight DECIMAL(10,2) NOT NULL,
  unit TEXT DEFAULT 'kg',
  processed_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- BUTCHER WASTE / LOSS LOGS
CREATE TABLE IF NOT EXISTS public.butcher_waste (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  batch_id UUID REFERENCES public.meat_batches(id),
  product_id UUID REFERENCES public.products(id),
  reason TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- BUTCHER / SPECIAL ORDERS
CREATE TABLE IF NOT EXISTS public.butcher_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  customer_id UUID,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  items JSONB NOT NULL,
  total_weight DECIMAL(10,2) NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- 5. LOGISTICS & EXPENSES
-- =====================================================

-- STOCK TRANSFERS
CREATE TABLE IF NOT EXISTS public.stock_transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  batch_id TEXT NOT NULL,
  meat_type TEXT NOT NULL,
  weight DECIMAL(10,2) NOT NULL,
  unit TEXT DEFAULT 'kg',
  destination TEXT NOT NULL,
  transfer_time TIMESTAMPTZ DEFAULT now() NOT NULL,
  status TEXT DEFAULT 'pending',
  is_individual BOOLEAN DEFAULT false,
  is_paid BOOLEAN DEFAULT false,
  is_third_party BOOLEAN DEFAULT false,
  customer_name TEXT,
  customer_phone TEXT,
  customer_location TEXT
);

-- EXPENSES
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  category TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  notes TEXT,
  receipt_url TEXT,
  date DATE DEFAULT CURRENT_DATE,
  recorded_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- 6. CRM, PAYROLL & SYSTEM AUDIT
-- =====================================================

-- CUSTOMERS (CRM)
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  phone2 TEXT,
  location TEXT,
  is_favorite BOOLEAN DEFAULT false,
  is_bulk_purchaser BOOLEAN DEFAULT false,
  is_wholesaler BOOLEAN DEFAULT false,
  is_special BOOLEAN DEFAULT false,
  special_discount_percentage DECIMAL(10,2),
  last_promo_date TIMESTAMPTZ,
  loyalty_points DECIMAL(10,2) DEFAULT 0.0,
  visit_count INT DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- STAFF PAYMENTS AUDIT (Payroll History)
CREATE TABLE IF NOT EXISTS public.staff_payments_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_advance BOOLEAN NOT NULL DEFAULT false,
  date TIMESTAMPTZ NOT NULL DEFAULT now(),
  target_month TIMESTAMPTZ DEFAULT now(),
  note TEXT
);

-- CUSTOMER PAYMENTS (Debt & Partial Settlement Tracking)
CREATE TABLE IF NOT EXISTS public.customer_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  customer_id UUID REFERENCES public.customers(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL,
  reference TEXT,
  sale_id TEXT REFERENCES public.sales(id),
  collected_by UUID REFERENCES public.users(id),
  payment_date TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- PRODUCT STOCK HISTORY (Inventory Ledger)
CREATE TABLE IF NOT EXISTS public.stock_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  product_id UUID REFERENCES public.products(id),
  change_amount DECIMAL(10,2) NOT NULL,
  new_quantity DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  reference_id TEXT,
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  user_id UUID REFERENCES public.users(id),
  user_name TEXT,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  old_data JSONB,
  new_data JSONB,
  timestamp TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  branch_code TEXT REFERENCES public.branches(code),
  user_id UUID REFERENCES public.users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- DOCUMENTS
CREATE TABLE IF NOT EXISTS public.documentss (
  id TEXT PRIMARY KEY,
  branch_code TEXT REFERENCES public.branches(code),
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- 7. INDEXES FOR HIGH PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_products_branch ON public.products(branch_code);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_sales_branch_time ON public.sales(branch_code, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_sales_cashier ON public.sales(cashier_id);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_branch ON public.stock_transfers(branch_code);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_stock_history_product ON public.stock_history(product_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);

-- =====================================================
-- 8. SECURITY & PERMISSIONS
-- =====================================================

-- Disable RLS for rapid development environment
ALTER TABLE public.branches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transfers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.animals DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.slaughter_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.meat_batches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.meat_cuts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.butcher_waste DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.butcher_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentss DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_payments_audit DISABLE ROW LEVEL SECURITY;

-- Grant permissions to standard API roles
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- =====================================================
-- 9. REALTIME CONFIGURATION
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'products'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE
      public.stock_transfers,
      public.notifications,
      public.products,
      public.meat_batches,
      public.slaughter_logs,
      public.sales,
      public.customers,
      public.expenses,
      public.users,
      public.meat_cuts,
      public.butcher_waste,
      public.butcher_orders,
      public.documentss,
      public.staff_payments_audit;
  END IF;
END $$;

-- =====================================================
-- 10. RPC FUNCTIONS
-- =====================================================

-- Atomic stock increment function (prevents concurrency issues)
CREATE OR REPLACE FUNCTION public.increment_stock(p_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE public.products
  SET
    stock_quantity = stock_quantity + p_amount,
    last_stock_update = now()
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

GRANT ALL ON FUNCTION public.increment_stock TO anon, authenticated, service_role;

-- =====================================================
-- 11. FINAL SCHEMA RELOAD
-- =====================================================

NOTIFY pgrst, 'reload schema';

-- =====================================================
-- 12. STORAGE BUCKETS SETUP
-- =====================================================

-- Create storage buckets for media & file uploads
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('product-images', 'product-images', true),
  ('user-profiles', 'user-profiles', true),
  ('receipts', 'receipts', true),
  ('documents', 'documents', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Public Access Policies for Storage Buckets
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for product-images'
  ) THEN
    CREATE POLICY "Public Access for product-images" ON storage.objects
      FOR ALL USING (bucket_id = 'product-images')
      WITH CHECK (bucket_id = 'product-images');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for user-profiles'
  ) THEN
    CREATE POLICY "Public Access for user-profiles" ON storage.objects
      FOR ALL USING (bucket_id = 'user-profiles')
      WITH CHECK (bucket_id = 'user-profiles');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for receipts'
  ) THEN
    CREATE POLICY "Public Access for receipts" ON storage.objects
      FOR ALL USING (bucket_id = 'receipts')
      WITH CHECK (bucket_id = 'receipts');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for documents'
  ) THEN
    CREATE POLICY "Public Access for documents" ON storage.objects
      FOR ALL USING (bucket_id = 'documents')
      WITH CHECK (bucket_id = 'documents');
  END IF;
END $$;

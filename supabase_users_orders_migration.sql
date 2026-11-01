-- ==============================================================================
-- BUN ATELIER — SUPABASE POSTGRESQL RELATIONAL SCHEMA MIGRATION
-- Relasi: users <--(1:N)--> orders <--(1:N)--> order_items
-- Mendukung relasi multi-user, history pemesanan, e-receipt hash, dan konsistensi data
-- ==============================================================================

-- 1. TABEL PENGGUNA (users)
CREATE TABLE IF NOT EXISTS public.users (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'CUSTOMER',
    username TEXT UNIQUE,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Kolom tambahan untuk users jika tabel sudah ada sebelumnya
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'CUSTOMER';

-- 2. TABEL PESANAN (orders) DENGAN FOREIGN KEY KE users
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    order_number TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    order_type TEXT NOT NULL DEFAULT 'PICKUP',
    payment_method TEXT NOT NULL DEFAULT 'QRIS',
    payment_status TEXT NOT NULL DEFAULT 'PAID',
    status TEXT NOT NULL DEFAULT 'CONFIRMED',
    customer_name TEXT NOT NULL DEFAULT 'Pelanggan Bun Atelier',
    customer_phone TEXT,
    subtotal BIGINT NOT NULL DEFAULT 0,
    tax BIGINT NOT NULL DEFAULT 0,
    delivery_fee BIGINT NOT NULL DEFAULT 0,
    total BIGINT NOT NULL DEFAULT 0,
    items_summary TEXT NOT NULL DEFAULT '',
    delivery_address TEXT,
    notes TEXT,
    branch_id TEXT,
    branch_name TEXT,
    branch_timezone TEXT DEFAULT 'Asia/Jakarta',
    branch_currency TEXT DEFAULT 'IDR',
    receipt_hash TEXT,
    receipt_tx_hash TEXT,
    is_synced BOOLEAN DEFAULT TRUE
);

-- Migrasi kolom jika tabel orders sudah pernah dibuat
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS user_id TEXT REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name TEXT DEFAULT 'Pelanggan Bun Atelier';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS branch_id TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS branch_name TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS branch_timezone TEXT DEFAULT 'Asia/Jakarta';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS branch_currency TEXT DEFAULT 'IDR';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS receipt_hash TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS receipt_tx_hash TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS is_synced BOOLEAN DEFAULT TRUE;

-- 3. TABEL DETAIL ITEM PESANAN (order_items)
CREATE TABLE IF NOT EXISTS public.order_items (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id TEXT,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price BIGINT NOT NULL DEFAULT 0,
    total_price BIGINT NOT NULL DEFAULT 0,
    customization TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. INDEKS UNTUK PERFORMA QUERY CEPAT
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON public.orders(order_number);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- Mengizinkan aplikasi mobile (anon key / authenticated) membaca dan menulis data
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Policy untuk tabel users
DROP POLICY IF EXISTS "Public access users select" ON public.users;
CREATE POLICY "Public access users select" ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public access users insert" ON public.users;
CREATE POLICY "Public access users insert" ON public.users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public access users update" ON public.users;
CREATE POLICY "Public access users update" ON public.users FOR UPDATE USING (true);

-- Policy untuk tabel orders
DROP POLICY IF EXISTS "Public access orders select" ON public.orders;
CREATE POLICY "Public access orders select" ON public.orders FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public access orders insert" ON public.orders;
CREATE POLICY "Public access orders insert" ON public.orders FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public access orders update" ON public.orders;
CREATE POLICY "Public access orders update" ON public.orders FOR UPDATE USING (true);

-- Policy untuk tabel order_items
DROP POLICY IF EXISTS "Public access order_items select" ON public.order_items;
CREATE POLICY "Public access order_items select" ON public.order_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public access order_items insert" ON public.order_items;
CREATE POLICY "Public access order_items insert" ON public.order_items FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public access order_items update" ON public.order_items;
CREATE POLICY "Public access order_items update" ON public.order_items FOR UPDATE USING (true);

-- 6. VERIFIKASI STRUKTUR TABEL
SELECT 
    table_name, column_name, data_type, is_nullable
FROM 
    information_schema.columns 
WHERE 
    table_name IN ('users', 'orders', 'order_items')
ORDER BY 
    table_name, ordinal_position;


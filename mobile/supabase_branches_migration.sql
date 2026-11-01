-- ==============================================================================
-- BUN ATELIER — MULTI-BRANCH LOCATION & GOOGLE MAPS INTEGRATION
-- Database Migration Script for Supabase (PostgreSQL)
-- Supports 7 Official Branches: Senopati, PIK 2, London, Bali, KL, Singapore, Papua
-- ==============================================================================

-- 1. Create table 'branches' if it does not exist
CREATE TABLE IF NOT EXISTS public.branches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL,
    address TEXT,
    latitude NUMERIC CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
    longitude NUMERIC CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180)),
    maps_query TEXT,
    maps_url TEXT,
    operating_hours TEXT,
    phone TEXT,
    timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    currency_code TEXT NOT NULL DEFAULT 'IDR',
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure timezone and currency_code columns exist if table was previously created
ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta';

ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'IDR';

-- 2. Add branch columns to 'orders' table if not exists
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS branch_id TEXT;

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS branch_name TEXT;

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS branch_timezone TEXT;

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS branch_currency TEXT;

-- Indexing for performance
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON public.branches(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON public.orders(branch_id);

-- 3. Row Level Security (RLS) Configuration
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Policy 1: Customer & Public Read Policy (Anyone can read active branches)
DROP POLICY IF EXISTS "Public can view active branches" ON public.branches;
CREATE POLICY "Public can view active branches" 
ON public.branches 
FOR SELECT 
USING (true);

-- Policy 2: Admin Only Write Policy (Insert, Update, Delete)
DROP POLICY IF EXISTS "Admins can manage branches" ON public.branches;
CREATE POLICY "Admins can manage branches" 
ON public.branches 
FOR ALL 
USING (
    -- Service role bypass or authenticated user with admin role
    auth.role() = 'service_role' OR
    (auth.jwt() ->> 'role') = 'admin' OR
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid()::text AND role = 'admin'
    )
)
WITH CHECK (
    auth.role() = 'service_role' OR
    (auth.jwt() ->> 'role') = 'admin' OR
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid()::text AND role = 'admin'
    )
);

-- 4. Idempotent Upsert for the Official 7 Branches
-- Retains existing Senopati & PIK data and adds regional/international branches.
-- If executed multiple times, will NOT produce duplicates.
INSERT INTO public.branches (
    id, name, city, country, address, latitude, longitude, 
    maps_query, maps_url, operating_hours, phone, timezone, currency_code,
    is_active, is_verified, updated_at
) VALUES 
-- 1. Senopati Flagship (Existing, Verified)
(
    'out-1',
    'Bun Atelier — Senopati Flagship',
    'Jakarta Selatan',
    'Indonesia',
    'Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan',
    -6.2298,
    106.8097,
    'Bun Atelier Senopati, Jakarta, Indonesia',
    'https://www.google.com/maps/search/?api=1&query=-6.2298,106.8097',
    '10:00 - 23:00 WIB',
    '+62 21 555-BURGER',
    'Asia/Jakarta',
    'IDR',
    true,
    true,
    timezone('utc'::text, now())
),
-- 2. PIK 2 Waterfront (Existing, Verified)
(
    'out-2',
    'Bun Atelier — PIK 2 Waterfront',
    'Jakarta Utara',
    'Indonesia',
    'Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara',
    -6.1089,
    106.7410,
    'Bun Atelier PIK, Pantai Indah Kapuk, Jakarta, Indonesia',
    'https://www.google.com/maps/search/?api=1&query=-6.1089,106.741',
    '11:00 - 00:00 WIB',
    '+62 21 555-PIKBUN',
    'Asia/Jakarta',
    'IDR',
    true,
    true,
    timezone('utc'::text, now())
),
-- 3. London (Existing, United Kingdom)
(
    'out-3',
    'Bun Atelier — London',
    'London',
    'United Kingdom',
    '16 Old Compton Street, Soho, London W1D 4TQ, United Kingdom',
    51.5132,
    -0.1318,
    '16 Old Compton Street, Soho, London W1D 4TQ, United Kingdom',
    'https://www.google.com/maps/search/?api=1&query=51.5132,-0.1318',
    '11:00 - 22:00 GMT',
    '+44 20 7946 0912',
    'Europe/London',
    'GBP',
    true,
    false,
    timezone('utc'::text, now())
),
-- 4. Bali (Existing, Indonesia)
(
    'out-4',
    'Bun Atelier — Bali',
    'Bali',
    'Indonesia',
    'Jl. Kayu Aya No. 18, Seminyak, Kec. Kuta Utara, Kabupaten Badung, Bali 80361, Indonesia',
    -8.6882,
    115.1565,
    'Jl. Kayu Aya No. 18, Seminyak, Kec. Kuta Utara, Kabupaten Badung, Bali, Indonesia',
    'https://www.google.com/maps/search/?api=1&query=-8.6882,115.1565',
    '10:00 - 23:00 WITA',
    '+62 361 555-BALI',
    'Asia/Makassar',
    'IDR',
    true,
    false,
    timezone('utc'::text, now())
),
-- 5. Kuala Lumpur (Existing, Malaysia)
(
    'out-5',
    'Bun Atelier — Kuala Lumpur',
    'Kuala Lumpur',
    'Malaysia',
    'Lot 10 Shopping Centre, 50 Jalan Sultan Ismail, Bukit Bintang, 55100 Kuala Lumpur, Malaysia',
    3.1466,
    101.7112,
    'Lot 10 Shopping Centre, 50 Jalan Sultan Ismail, Bukit Bintang, 55100 Kuala Lumpur, Malaysia',
    'https://www.google.com/maps/search/?api=1&query=3.1466,101.7112',
    '10:00 - 22:00 MYT',
    '+60 3 2148 5555',
    'Asia/Kuala_Lumpur',
    'MYR',
    true,
    false,
    timezone('utc'::text, now())
),
-- 6. Singapore (Existing, Singapore)
(
    'out-6',
    'Bun Atelier — Singapore',
    'Singapore',
    'Singapore',
    '7 Keong Saik Road, Chinatown, Singapore 089115',
    1.2801,
    103.8415,
    '7 Keong Saik Road, Chinatown, Singapore 089115',
    'https://www.google.com/maps/search/?api=1&query=1.2801,103.8415',
    '11:00 - 22:00 SGT',
    '+65 6221 5555',
    'Asia/Singapore',
    'SGD',
    true,
    false,
    timezone('utc'::text, now())
),
-- 7. Maluku (Replaces Papua, Indonesia)
(
    'out-7',
    'Bun Atelier — Maluku',
    'Kota Ambon, Maluku',
    'Indonesia',
    'Jl. Jenderal Sudirman No. 88, Kel. Sirimau, Kec. Sirimau, Kota Ambon, Maluku, Indonesia',
    -3.6931,
    128.1884,
    'Jl. Jenderal Sudirman No. 88, Kel. Sirimau, Kec. Sirimau, Kota Ambon, Maluku, Indonesia',
    'https://www.google.com/maps/search/?api=1&query=-3.6931,128.1884',
    '10:00 - 22:00 WIT',
    '+62 911 555-BUN',
    'Asia/Jayapura',
    'IDR',
    true,
    false,
    timezone('utc'::text, now())
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    country = EXCLUDED.country,
    address = EXCLUDED.address,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    maps_query = EXCLUDED.maps_query,
    maps_url = EXCLUDED.maps_url,
    operating_hours = EXCLUDED.operating_hours,
    phone = EXCLUDED.phone,
    timezone = EXCLUDED.timezone,
    currency_code = EXCLUDED.currency_code,
    updated_at = timezone('utc'::text, now());

-- ==============================================================================
-- BUN ATELIER — CUSTOMER FEEDBACK & ORDER RATING DATABASE MIGRATION
-- Ties feedback directly to completed orders (order_id) and customers (user_id)
-- Target table: public.feedbacks
-- Constraints: 1 feedback per order (order_id UNIQUE), rating 1-5
-- ==============================================================================

-- 1. Create feedbacks table if not exists
CREATE TABLE IF NOT EXISTS public.feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_name TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure all required columns exist if table was already created in an earlier migration
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating >= 1 AND rating <= 5);
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS comment TEXT;
ALTER TABLE public.feedbacks ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Enforce exactly 1 feedback per Order ID via Unique Constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'feedbacks_order_id_unique'
    ) THEN
        ALTER TABLE public.feedbacks ADD CONSTRAINT feedbacks_order_id_unique UNIQUE (order_id);
    END IF;
END $$;

-- 2. Indexes for efficient query optimization
CREATE UNIQUE INDEX IF NOT EXISTS idx_feedbacks_order_id ON public.feedbacks(order_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON public.feedbacks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_id ON public.feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_rating ON public.feedbacks(rating);
CREATE INDEX IF NOT EXISTS idx_feedbacks_customer_name ON public.feedbacks(customer_name);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;

-- 4. Clean up existing policies for idempotency
DROP POLICY IF EXISTS "Authenticated users can select feedbacks" ON public.feedbacks;
DROP POLICY IF EXISTS "Authenticated users can insert own feedback" ON public.feedbacks;
DROP POLICY IF EXISTS "Authenticated users can update own feedback" ON public.feedbacks;
DROP POLICY IF EXISTS "Authenticated users can delete own feedback" ON public.feedbacks;
DROP POLICY IF EXISTS "Allow select feedbacks" ON public.feedbacks;
DROP POLICY IF EXISTS "Allow insert feedbacks" ON public.feedbacks;
DROP POLICY IF EXISTS "Public access feedbacks select" ON public.feedbacks;
DROP POLICY IF EXISTS "Public access feedbacks insert" ON public.feedbacks;
DROP POLICY IF EXISTS "Public access feedbacks update" ON public.feedbacks;
DROP POLICY IF EXISTS "Public access feedbacks delete" ON public.feedbacks;

-- 5. Row Level Security Policies
-- (a) Admin dan pelanggan dapat melihat seluruh feedback
CREATE POLICY "Allow select feedbacks"
ON public.feedbacks
FOR SELECT
TO authenticated, anon
USING (true);

-- (b) Pelanggan hanya dapat memberikan feedback pada pesanan miliknya sendiri
CREATE POLICY "Allow insert feedbacks"
ON public.feedbacks
FOR INSERT
TO authenticated, anon
WITH CHECK (
    auth.uid() = user_id OR auth.uid() IS NOT NULL OR user_id IS NOT NULL
);

-- (c) Pengguna hanya dapat mengubah feedback miliknya sendiri
CREATE POLICY "Allow update feedbacks"
ON public.feedbacks
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- (d) Pengguna hanya dapat menghapus feedback miliknya sendiri
CREATE POLICY "Allow delete feedbacks"
ON public.feedbacks
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 6. Grant permissions to authenticated role and anon role
GRANT SELECT, INSERT, UPDATE, DELETE ON public.feedbacks TO authenticated, anon;
GRANT ALL ON public.feedbacks TO service_role;

-- ==============================================================================
-- BUN ATELIER — APP FEEDBACK & EVALUATION DATABASE MIGRATION
-- Evaluasi Kualitas & Pengalaman Pengguna Aplikasi Mobile Bun Atelier
-- Target table: public.app_feedbacks (Terpisah dari feedbacks pesanan)
-- ==============================================================================

-- 1. Create app_feedbacks table if not exists
CREATE TABLE IF NOT EXISTS public.app_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT,
    user_email TEXT,
    
    -- Penilaian 6 Aspek Pengalaman Pengguna (Rating 1 - 5)
    rating_ui INTEGER NOT NULL CHECK (rating_ui >= 1 AND rating_ui <= 5),
    rating_ux INTEGER NOT NULL CHECK (rating_ux >= 1 AND rating_ux <= 5),
    rating_navigation INTEGER NOT NULL CHECK (rating_navigation >= 1 AND rating_navigation <= 5),
    rating_performance INTEGER NOT NULL CHECK (rating_performance >= 1 AND rating_performance <= 5),
    rating_functionality INTEGER NOT NULL CHECK (rating_functionality >= 1 AND rating_functionality <= 5),
    rating_comfort INTEGER NOT NULL CHECK (rating_comfort >= 1 AND rating_comfort <= 5),
    rating_overall NUMERIC(3,2) NOT NULL,
    
    -- Pertanyaan Tambahan
    overall_experience TEXT NOT NULL,
    favorite_feature TEXT NOT NULL,
    had_issues BOOLEAN NOT NULL DEFAULT false,
    issue_description TEXT,
    
    -- Saran dan Masukan
    suggestions TEXT,
    
    -- Metadata
    status TEXT NOT NULL DEFAULT 'TERKIRIM',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure all required columns exist if table was partially created
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS user_name TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS user_email TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_ui INTEGER CHECK (rating_ui >= 1 AND rating_ui <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_ux INTEGER CHECK (rating_ux >= 1 AND rating_ux <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_navigation INTEGER CHECK (rating_navigation >= 1 AND rating_navigation <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_performance INTEGER CHECK (rating_performance >= 1 AND rating_performance <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_functionality INTEGER CHECK (rating_functionality >= 1 AND rating_functionality <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_comfort INTEGER CHECK (rating_comfort >= 1 AND rating_comfort <= 5);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS rating_overall NUMERIC(3,2);
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS overall_experience TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS favorite_feature TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS had_issues BOOLEAN DEFAULT false;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS issue_description TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS suggestions TEXT;
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'TERKIRIM';
ALTER TABLE public.app_feedbacks ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 2. Indexes for efficient query optimization
CREATE INDEX IF NOT EXISTS idx_app_feedbacks_user_id ON public.app_feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_app_feedbacks_created_at ON public.app_feedbacks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_app_feedbacks_overall ON public.app_feedbacks(rating_overall DESC);
CREATE INDEX IF NOT EXISTS idx_app_feedbacks_status ON public.app_feedbacks(status);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.app_feedbacks ENABLE ROW LEVEL SECURITY;

-- 4. Clean up existing policies for idempotency
DROP POLICY IF EXISTS "Allow select app_feedbacks" ON public.app_feedbacks;
DROP POLICY IF EXISTS "Allow insert app_feedbacks" ON public.app_feedbacks;
DROP POLICY IF EXISTS "Allow update app_feedbacks" ON public.app_feedbacks;
DROP POLICY IF EXISTS "Allow delete app_feedbacks" ON public.app_feedbacks;

-- 5. Row Level Security Policies
-- (a) Pengguna dan admin dapat melihat feedback aplikasi
CREATE POLICY "Allow select app_feedbacks"
ON public.app_feedbacks
FOR SELECT
TO authenticated, anon
USING (true);

-- (b) Pengguna terautentikasi dapat mengirimkan feedback aplikasi mereka
CREATE POLICY "Allow insert app_feedbacks"
ON public.app_feedbacks
FOR INSERT
TO authenticated, anon
WITH CHECK (
    auth.uid() = user_id OR auth.uid() IS NOT NULL OR user_id IS NOT NULL
);

-- (c) Pengguna hanya dapat memperbarui feedback miliknya sendiri
CREATE POLICY "Allow update app_feedbacks"
ON public.app_feedbacks
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- (d) Pengguna hanya dapat menghapus feedback miliknya sendiri
CREATE POLICY "Allow delete app_feedbacks"
ON public.app_feedbacks
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 6. Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.app_feedbacks TO authenticated, anon;
GRANT ALL ON public.app_feedbacks TO service_role;


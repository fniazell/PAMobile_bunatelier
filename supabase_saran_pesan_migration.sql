-- ==============================================================================
-- BUN ATELIER - MIGRATION: SARAN & PESAN (MATA KULIAH PEMROGRAMAN APLIKASI MOBILE)
-- ==============================================================================
-- Tabel ini digunakan khusus untuk menampung masukan mahasiswa berupa:
-- 1. Saran untuk Mata Kuliah Pemrograman Aplikasi Mobile
-- 2. Pesan untuk Dosen Pengampu
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.course_saran_pesan (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_name TEXT,
    user_email TEXT,
    saran TEXT NOT NULL,
    pesan TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexing untuk mempercepat query berdasarkan user_id dan urutan waktu
CREATE INDEX IF NOT EXISTS idx_course_saran_pesan_user_id 
ON public.course_saran_pesan (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_course_saran_pesan_created_at 
ON public.course_saran_pesan (created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.course_saran_pesan ENABLE ROW LEVEL SECURITY;

-- Policy: Semua pengguna terautentikasi / anon dapat mengirimkan Saran & Pesan
DROP POLICY IF EXISTS "Allow insert to course_saran_pesan" ON public.course_saran_pesan;
CREATE POLICY "Allow insert to course_saran_pesan"
ON public.course_saran_pesan
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Policy: Pengguna dapat membaca saran & pesan miliknya atau semua untuk keperluan review
DROP POLICY IF EXISTS "Allow select course_saran_pesan" ON public.course_saran_pesan;
CREATE POLICY "Allow select course_saran_pesan"
ON public.course_saran_pesan
FOR SELECT
TO anon, authenticated
USING (true);

COMMENT ON TABLE public.course_saran_pesan IS 'Tabel saran dan pesan mahasiswa untuk mata kuliah Pemrograman Aplikasi Mobile dan dosen pengampu';

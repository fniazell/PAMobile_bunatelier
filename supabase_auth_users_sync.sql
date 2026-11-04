-- Keep public.users in sync with Supabase Auth users.
-- Run this script once in the Supabase SQL Editor.

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

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'CUSTOMER';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
    NOT NULL DEFAULT timezone('utc'::text, now());

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public access users select" ON public.users;
DROP POLICY IF EXISTS "Public access users insert" ON public.users;
DROP POLICY IF EXISTS "Public access users update" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

CREATE POLICY "Users can view own profile"
ON public.users
FOR SELECT
TO authenticated
USING (id = (SELECT auth.uid())::TEXT);

CREATE POLICY "Users can insert own profile"
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (id = (SELECT auth.uid())::TEXT);

CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (id = (SELECT auth.uid())::TEXT)
WITH CHECK (id = (SELECT auth.uid())::TEXT);

CREATE OR REPLACE FUNCTION public.sync_auth_user_profile(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    auth_user auth.users%ROWTYPE;
    profile_name TEXT;
    profile_username TEXT;
    profile_phone TEXT;
    username_base TEXT;
    username_suffix_length INTEGER := 8;
BEGIN
    SELECT *
    INTO auth_user
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND OR auth_user.email IS NULL THEN
        RETURN;
    END IF;

    profile_name := COALESCE(
        NULLIF(auth_user.raw_user_meta_data ->> 'full_name', ''),
        NULLIF(split_part(auth_user.email, '@', 1), ''),
        'Customer'
    );
    profile_username := NULLIF(auth_user.raw_user_meta_data ->> 'username', '');
    profile_phone := NULLIF(auth_user.raw_user_meta_data ->> 'phone', '');

    IF profile_username IS NULL OR EXISTS (
        SELECT 1
        FROM public.users
        WHERE username = profile_username
          AND id <> auth_user.id::TEXT
    ) THEN
        username_base := COALESCE(
            NULLIF(
                left(
                    regexp_replace(
                        split_part(auth_user.email, '@', 1),
                        '[^a-zA-Z0-9._]',
                        '_',
                        'g'
                    ),
                    11
                ),
                ''
            ),
            'customer'
        );

        LOOP
            profile_username :=
                left(
                    username_base,
                    greatest(0, 20 - username_suffix_length - 1)
                )
                || '_'
                || substr(
                    replace(auth_user.id::TEXT, '-', ''),
                    1,
                    username_suffix_length
                );

            EXIT WHEN NOT EXISTS (
                SELECT 1
                FROM public.users
                WHERE username = profile_username
                  AND id <> auth_user.id::TEXT
            );

            username_suffix_length := username_suffix_length + 1;
            IF username_suffix_length > 19 THEN
                RAISE EXCEPTION 'Unable to generate a unique username for auth user %',
                    auth_user.id;
            END IF;
        END LOOP;
    END IF;

    BEGIN
        INSERT INTO public.users (
            id, full_name, email, role, username, phone
        )
        VALUES (
            auth_user.id::TEXT,
            profile_name,
            auth_user.email,
            'CUSTOMER',
            profile_username,
            profile_phone
        )
        ON CONFLICT (id) DO UPDATE
        SET full_name = EXCLUDED.full_name,
            email = EXCLUDED.email,
            role = 'CUSTOMER',
            username = COALESCE(public.users.username, EXCLUDED.username),
            phone = COALESCE(public.users.phone, EXCLUDED.phone),
            updated_at = timezone('utc'::text, now());
    EXCEPTION
        WHEN unique_violation THEN
            UPDATE public.users
            SET full_name = profile_name,
                role = 'CUSTOMER',
                username = COALESCE(public.users.username, profile_username),
                phone = COALESCE(public.users.phone, profile_phone),
                updated_at = timezone('utc'::text, now())
            WHERE email = auth_user.email;

            IF NOT FOUND THEN
                INSERT INTO public.users (
                    id, full_name, email, role, username, phone
                )
                VALUES (
                    auth_user.id::TEXT,
                    profile_name,
                    auth_user.email,
                    'CUSTOMER',
                    profile_username,
                    profile_phone
                )
                ON CONFLICT DO NOTHING;
            END IF;
    END;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    PERFORM public.sync_auth_user_profile(NEW.id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_sync_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_sync_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

REVOKE ALL ON FUNCTION public.sync_auth_user_profile(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
    auth_user RECORD;
BEGIN
    FOR auth_user IN
        SELECT id FROM auth.users
    LOOP
        PERFORM public.sync_auth_user_profile(auth_user.id);
    END LOOP;
END;
$$;

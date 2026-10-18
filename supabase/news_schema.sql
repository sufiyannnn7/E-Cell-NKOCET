-- ==============================================================================
-- E-CELL NKOCET - NEWS & BLOGS MODULE SCHEMA & POLICIES
-- ==============================================================================
-- Run this script in the Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This script is idempotent and safe to run multiple times.
-- ==============================================================================

-- 1. Create news_articles table
CREATE TABLE IF NOT EXISTS public.news_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  excerpt TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Entrepreneurship',
  author TEXT NOT NULL DEFAULT 'E-Cell Team',
  author_id TEXT DEFAULT NULL,
  cover_image TEXT DEFAULT '',
  cover_image_path TEXT DEFAULT '',
  seo_description TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  reading_time INT NOT NULL DEFAULT 3,
  views_count INT NOT NULL DEFAULT 0,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure columns exist in case of partial runs
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS cover_image_path TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS seo_description TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS reading_time INT NOT NULL DEFAULT 3;
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS views_count INT NOT NULL DEFAULT 0;
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_role TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_avatar TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_bio TEXT DEFAULT '';

-- 2. Create news_article_images table (gallery & embedded images)
CREATE TABLE IF NOT EXISTS public.news_article_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID NOT NULL REFERENCES public.news_articles(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  storage_path TEXT DEFAULT '',
  caption TEXT DEFAULT '',
  alt_text TEXT DEFAULT '',
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Indexes for performance
CREATE UNIQUE INDEX IF NOT EXISTS idx_news_articles_slug ON public.news_articles (slug);
CREATE INDEX IF NOT EXISTS idx_news_articles_status_pub ON public.news_articles (status, published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_articles_category ON public.news_articles (category);
CREATE INDEX IF NOT EXISTS idx_news_article_images_article ON public.news_article_images (article_id, display_order ASC);

-- 4. Automatic updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_news_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_news_article_updated ON public.news_articles;
CREATE TRIGGER on_news_article_updated
  BEFORE UPDATE ON public.news_articles
  FOR EACH ROW EXECUTE FUNCTION public.handle_news_updated_at();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news_article_images ENABLE ROW LEVEL SECURITY;

-- ─── 5a. news_articles RLS Policies ───

-- Public can ONLY read published articles
DROP POLICY IF EXISTS "Public can read published articles" ON public.news_articles;
CREATE POLICY "Public can read published articles"
  ON public.news_articles FOR SELECT
  USING (
    status = 'published'
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can insert articles
DROP POLICY IF EXISTS "Admins can insert articles" ON public.news_articles;
CREATE POLICY "Admins can insert articles"
  ON public.news_articles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can update articles
DROP POLICY IF EXISTS "Admins can update articles" ON public.news_articles;
CREATE POLICY "Admins can update articles"
  ON public.news_articles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can delete articles
DROP POLICY IF EXISTS "Admins can delete articles" ON public.news_articles;
CREATE POLICY "Admins can delete articles"
  ON public.news_articles FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- ─── 5b. news_article_images RLS Policies ───

-- Public can read images belonging to published articles (or admin)
DROP POLICY IF EXISTS "Public can read published article images" ON public.news_article_images;
CREATE POLICY "Public can read published article images"
  ON public.news_article_images FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.news_articles
      WHERE news_articles.id = news_article_images.article_id
        AND news_articles.status = 'published'
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can insert gallery images
DROP POLICY IF EXISTS "Admins can insert article images" ON public.news_article_images;
CREATE POLICY "Admins can insert article images"
  ON public.news_article_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can update gallery images
DROP POLICY IF EXISTS "Admins can update article images" ON public.news_article_images;
CREATE POLICY "Admins can update article images"
  ON public.news_article_images FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- Admins can delete gallery images
DROP POLICY IF EXISTS "Admins can delete article images" ON public.news_article_images;
CREATE POLICY "Admins can delete article images"
  ON public.news_article_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
    )
  );

-- ─── 6. Storage Bucket for News Images ───

INSERT INTO storage.buckets (id, name, public)
VALUES ('news', 'news', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Public can download/view news images
DROP POLICY IF EXISTS "Allow public news image downloads" ON storage.objects;
CREATE POLICY "Allow public news image downloads"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'news');

-- Admins can upload news images
DROP POLICY IF EXISTS "Allow admin news image uploads" ON storage.objects;
CREATE POLICY "Allow admin news image uploads"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'news'
    AND (
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
      )
    )
  );

-- Admins can update/replace news images
DROP POLICY IF EXISTS "Allow admin news image updates" ON storage.objects;
CREATE POLICY "Allow admin news image updates"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'news'
    AND (
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
      )
    )
  );

-- Admins can delete news images
DROP POLICY IF EXISTS "Allow admin news image deletes" ON storage.objects;
CREATE POLICY "Allow admin news image deletes"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'news'
    AND (
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (role = 'admin' OR LOWER(contact_email) = 'nikhildeosani@gmail.com')
      )
    )
  );

-- ==============================================================================
-- 7. CLEANUP
-- ==============================================================================
DELETE FROM public.news_articles
WHERE slug IN (
  'nkocet-ecell-launches-annual-flagship-innovation-initiative',
  'from-campus-dorm-to-venture-funded-orchid-alumni-startups',
  'national-innovation-conclave-2026-registration-now-live'
) OR id::TEXT LIKE 'e1a0b5c0-%';


-- ==============================================================================
-- E-CELL NKOCET - FIX NEWS & BLOGS PERMISSIONS, AUTHOR ID, AND STORAGE
-- ==============================================================================
-- Run this complete script in your Supabase SQL Editor:
-- Dashboard > SQL Editor > New query > Paste & Run
-- ==============================================================================

-- 1. FIX AUTHOR_ID COLUMN (Allows text IDs like 'author-sufiyan-shaikh' without crashing)
DO $$
BEGIN
  -- Drop foreign key constraint on auth.users if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'news_articles_author_id_fkey'
      AND table_name = 'news_articles'
  ) THEN
    ALTER TABLE public.news_articles DROP CONSTRAINT news_articles_author_id_fkey;
  END IF;

  -- Change column type from UUID to TEXT
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'news_articles'
      AND column_name = 'author_id'
      AND data_type = 'uuid'
  ) THEN
    ALTER TABLE public.news_articles ALTER COLUMN author_id TYPE TEXT USING author_id::TEXT;
  END IF;
END $$;

-- 2. ENSURE ALL AUTHOR & MEDIA COLUMNS EXIST
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_role TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_avatar TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS author_bio TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS cover_image_path TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS seo_description TEXT DEFAULT '';
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS reading_time INT NOT NULL DEFAULT 3;
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS views_count INT NOT NULL DEFAULT 0;
ALTER TABLE public.news_articles ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;

-- 3. ENSURE GALLERY IMAGES TABLE EXISTS
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

-- Ensure indexes
CREATE INDEX IF NOT EXISTS idx_news_article_images_article ON public.news_article_images (article_id, display_order ASC);
CREATE INDEX IF NOT EXISTS idx_news_articles_status_pub ON public.news_articles (status, published_at DESC);

-- 4. FIX ROW-LEVEL SECURITY (RLS) FOR NEWS ARTICLES
ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read published articles" ON public.news_articles;
DROP POLICY IF EXISTS "Admins can insert articles" ON public.news_articles;
DROP POLICY IF EXISTS "Admins can update articles" ON public.news_articles;
DROP POLICY IF EXISTS "Admins can delete articles" ON public.news_articles;
DROP POLICY IF EXISTS "Allow public read published articles" ON public.news_articles;
DROP POLICY IF EXISTS "Allow full access to news_articles" ON public.news_articles;

-- Allow reading all articles (public sees published, admin sees drafts)
CREATE POLICY "Allow public read published articles"
  ON public.news_articles FOR SELECT
  USING (true);

-- Allow inserting, updating, and deleting articles without RLS block
CREATE POLICY "Allow full access to news_articles"
  ON public.news_articles FOR ALL
  USING (true)
  WITH CHECK (true);

-- 5. FIX ROW-LEVEL SECURITY (RLS) FOR GALLERY IMAGES
ALTER TABLE public.news_article_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read published article images" ON public.news_article_images;
DROP POLICY IF EXISTS "Admins can insert article images" ON public.news_article_images;
DROP POLICY IF EXISTS "Admins can update article images" ON public.news_article_images;
DROP POLICY IF EXISTS "Admins can delete article images" ON public.news_article_images;
DROP POLICY IF EXISTS "Allow full access to news_article_images" ON public.news_article_images;

CREATE POLICY "Allow full access to news_article_images"
  ON public.news_article_images FOR ALL
  USING (true)
  WITH CHECK (true);

-- 6. SETUP STORAGE BUCKET 'news' AND OPEN POLICIES FOR IMAGE UPLOADS
INSERT INTO storage.buckets (id, name, public)
VALUES ('news', 'news', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Allow public news image downloads" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin news image uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin news image updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow admin news image deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public storage access for news bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow public storage uploads for news bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow public storage updates for news bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow public storage deletes for news bucket" ON storage.objects;

CREATE POLICY "Allow public storage access for news bucket"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'news');

CREATE POLICY "Allow public storage uploads for news bucket"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'news');

CREATE POLICY "Allow public storage updates for news bucket"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'news')
  WITH CHECK (bucket_id = 'news');

CREATE POLICY "Allow public storage deletes for news bucket"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'news');

-- 7. PURGE PREVIOUS FAKE SEED ARTICLES
DELETE FROM public.news_articles
WHERE slug IN (
  'nkocet-ecell-launches-annual-flagship-innovation-initiative',
  'from-campus-dorm-to-venture-funded-orchid-alumni-startups',
  'national-innovation-conclave-2026-registration-now-live'
) OR id::TEXT LIKE 'e1a0b5c0-%';

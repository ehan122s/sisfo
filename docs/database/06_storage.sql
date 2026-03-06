-- ============================================================
-- E-PKL Database Setup — Step 6: Storage Buckets
-- ============================================================
-- Creates storage buckets and their access policies.
-- Run after 05_views_indexes.sql.
-- ============================================================

-- 1. Storage Bucket: attendances (selfie photos)
INSERT INTO storage.buckets (id, name, public)
VALUES ('attendances', 'attendances', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Bucket: journal_evidence (journal attachments)
INSERT INTO storage.buckets (id, name, public)
VALUES ('journal_evidence', 'journal_evidence', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policies for 'attendances' bucket
CREATE POLICY "Allow authenticated uploads to attendances"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'attendances' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow public view attendances"
ON storage.objects FOR SELECT
USING (bucket_id = 'attendances');

-- Policies for 'journal_evidence' bucket
CREATE POLICY "Allow authenticated uploads to journal_evidence"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'journal_evidence' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow public view journal_evidence"
ON storage.objects FOR SELECT
USING (bucket_id = 'journal_evidence');

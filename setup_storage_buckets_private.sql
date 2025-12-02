-- Setup Supabase Storage Buckets for MyFamily App (PRIVATE BUCKET VERSION)
-- Run this in your Supabase SQL Editor
-- This version sets up a PRIVATE bucket with signed URL support

-- ============================================================================
-- STEP 1: Create or Update Storage Bucket (PRIVATE)
-- ============================================================================

-- Note: You must set the bucket to PRIVATE in the Supabase Dashboard:
-- Storage → Buckets → user-content → Toggle "Public" to OFF

-- Create user-content bucket for profile pictures and user uploads
-- IMPORTANT: Set public = false for private bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-content',
  'user-content',
  false, -- PRIVATE bucket - requires signed URLs
  5242880, -- 5MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false, -- Ensure bucket is private
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- ============================================================================
-- STEP 2: Storage Policies for PRIVATE Bucket
-- ============================================================================

-- Drop existing public policies
DROP POLICY IF EXISTS "Public can view files" ON storage.objects;
DROP POLICY IF EXISTS "Public read access" ON storage.objects;

-- ============================================================================
-- SELECT (Read) Policies
-- ============================================================================

-- Policy: Authenticated users can view their own avatars
CREATE POLICY "Authenticated users can view their own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Policy: Family members can view each other's avatars
CREATE POLICY "Family members can view avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  (
    -- Own avatar
    auth.uid()::text = (storage.foldername(name))[2]
    OR
    -- Family member's avatar
    EXISTS (
      SELECT 1 FROM family_members fm1
      JOIN family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
      AND fm2.user_id::text = (storage.foldername(name))[2]
    )
  )
);

-- ============================================================================
-- INSERT (Upload) Policies
-- ============================================================================

-- Policy: Users can upload their own files
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- ============================================================================
-- UPDATE Policies
-- ============================================================================

-- Policy: Users can update their own files
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
)
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- ============================================================================
-- DELETE Policies
-- ============================================================================

-- Policy: Users can delete their own files
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify bucket is private
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id = 'user-content';
-- Expected: public = false

-- Verify policies exist
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%avatar%' OR policyname LIKE '%user-content%'
ORDER BY policyname;



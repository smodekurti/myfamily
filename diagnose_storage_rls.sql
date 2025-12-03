-- Diagnostic Script for Supabase Storage RLS Issues
-- Run this in your Supabase SQL Editor to diagnose and fix storage access

-- ============================================================================
-- STEP 1: Check if bucket exists and its configuration
-- ============================================================================
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types,
  created_at
FROM storage.buckets
WHERE id = 'user-content';

-- Expected: Should show one row with public = false

-- ============================================================================
-- STEP 2: Check existing storage policies
-- ============================================================================
SELECT 
  policyname,
  cmd,
  qual,
  with_check,
  tablename
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;

-- ============================================================================
-- STEP 3: Check if there are any files in the bucket
-- ============================================================================
SELECT 
  name,
  bucket_id,
  owner,
  created_at,
  updated_at
FROM storage.objects
WHERE bucket_id = 'user-content'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- STEP 4: Drop ALL existing policies (clean slate)
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can view their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Family members can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload to avatars folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;
DROP POLICY IF EXISTS "Public can view files" ON storage.objects;
DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload their own files" ON storage.objects;

-- ============================================================================
-- STEP 5: Create SIMPLE policies that allow signed URL generation
-- ============================================================================

-- Policy 1: Allow authenticated users to SELECT (required for createSignedUrl)
CREATE POLICY "Allow authenticated users to read avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
);

-- Policy 2: Allow users to upload their own files
CREATE POLICY "Allow users to upload own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Policy 3: Allow users to update their own files
CREATE POLICY "Allow users to update own avatars"
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

-- Policy 4: Allow users to delete their own files
CREATE POLICY "Allow users to delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- ============================================================================
-- STEP 6: Verify policies were created
-- ============================================================================
SELECT 
  policyname,
  cmd,
  roles,
  tablename
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%avatar%'
ORDER BY policyname;

-- Expected: Should show 4 policies

-- ============================================================================
-- STEP 7: Test if current user can access a file (replace with actual path)
-- ============================================================================
-- Replace 'avatars/YOUR_USER_ID/YOUR_FILE.jpg' with an actual file path
-- SELECT * FROM storage.objects 
-- WHERE bucket_id = 'user-content' 
--   AND name = 'avatars/dac594ed-e327-4520-90e6-c6fc99cc8409/1764652829909.jpg';

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. The key policy for signed URLs is the SELECT policy
-- 2. It must allow authenticated users to read the files
-- 3. The bucket MUST be private (public = false)
-- 4. The path structure MUST match: avatars/{userId}/{filename}
-- 5. If createSignedUrl still fails, check Supabase logs for detailed errors


-- Setup Supabase Storage Buckets for MyFamily App
-- Run this in your Supabase SQL Editor

-- Create user-content bucket for profile pictures and user uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-content',
  'user-content',
  true, -- Public bucket so images can be accessed via public URLs
  5242880, -- 5MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for user-content bucket
-- Policy: Users can upload their own files
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

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

-- Policy: Users can delete their own files
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Policy: Anyone can view public files (since bucket is public)
CREATE POLICY "Public can view files"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-content');

-- Alternative: More permissive policy for avatars folder
-- Allow authenticated users to upload to avatars folder with their user ID in filename
CREATE POLICY "Users can upload to avatars folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
);

-- Allow authenticated users to update files in avatars folder
CREATE POLICY "Users can update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
)
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
);

-- Allow authenticated users to delete files in avatars folder
CREATE POLICY "Users can delete avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
);


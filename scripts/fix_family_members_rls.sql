-- ============================================================================
-- FIX FAMILY_MEMBERS RLS POLICY
-- ============================================================================
-- This script fixes the RLS policy for family_members table to allow
-- users to view all members of families they belong to, not just themselves
-- ============================================================================

-- Drop the restrictive policy that only allows viewing own record
DROP POLICY IF EXISTS "family_members_select_policy" ON family_members;

-- Ensure the correct policy exists (allows viewing all members of families user belongs to)
-- First drop it if it exists to recreate it
DROP POLICY IF EXISTS "family_members_select_family" ON family_members;

-- Create the correct policy
CREATE POLICY "family_members_select_family"
  ON family_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Verify the policy was created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'family_members'
ORDER BY policyname;


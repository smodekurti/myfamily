-- ============================================================================
-- COMPREHENSIVE FIX FOR FAMILY ACCESS ISSUES
-- ============================================================================
-- This script fixes all RLS policies related to family access
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Step 1: Drop ALL existing policies on family_members (clean slate)
DROP POLICY IF EXISTS "family_members_select_policy" ON family_members;
DROP POLICY IF EXISTS "family_members_insert_policy" ON family_members;
DROP POLICY IF EXISTS "family_members_update_policy" ON family_members;
DROP POLICY IF EXISTS "Users can view family members of their families" ON family_members;
DROP POLICY IF EXISTS "family_members_select_family" ON family_members;
DROP POLICY IF EXISTS "family_members_insert_self" ON family_members;
DROP POLICY IF EXISTS "family_members_insert_admin" ON family_members;
DROP POLICY IF EXISTS "family_members_update_own" ON family_members;
DROP POLICY IF EXISTS "family_members_update_admin" ON family_members;

-- Step 2: Create correct SELECT policy for family_members
-- Users can see ALL members of families they belong to
-- Using a security definer function to avoid infinite recursion
CREATE OR REPLACE FUNCTION check_user_in_family(p_family_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM family_members
    WHERE family_id = p_family_id
    AND user_id = p_user_id
  );
END;
$$;

CREATE POLICY "family_members_select_family"
  ON family_members FOR SELECT
  USING (check_user_in_family(family_id, auth.uid()));

-- Step 3: Create INSERT policy for family_members
-- Users can insert themselves into families (via invite code)
CREATE POLICY "family_members_insert_self"
  ON family_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Step 4: Create INSERT policy for admins/parents
-- Family admins/parents can insert other members
CREATE POLICY "family_members_insert_admin"
  ON family_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- Step 5: Create UPDATE policy for own record
CREATE POLICY "family_members_update_own"
  ON family_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Step 6: Create UPDATE policy for admins/parents
CREATE POLICY "family_members_update_admin"
  ON family_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- Step 7: Verify the policies were created
SELECT 
  'family_members policies' as table_name,
  policyname,
  cmd,
  CASE 
    WHEN qual IS NOT NULL THEN 'Has USING clause'
    ELSE 'No USING clause'
  END as has_using,
  CASE 
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
    ELSE 'No WITH CHECK clause'
  END as has_with_check
FROM pg_policies
WHERE tablename = 'family_members'
ORDER BY cmd, policyname;

-- Step 8: Test query (should return results if user has family_members records)
SELECT 
  'Test: Can see own family_members' as test_name,
  COUNT(*) as record_count
FROM family_members
WHERE user_id = auth.uid();

-- Step 9: Test query (should return all members of families user belongs to)
SELECT 
  'Test: Can see all family members' as test_name,
  COUNT(*) as total_members,
  COUNT(DISTINCT family_id) as unique_families
FROM family_members;

-- Step 10: Test query (should return families user belongs to)
SELECT 
  'Test: Can see families' as test_name,
  COUNT(*) as family_count,
  array_agg(id) as family_ids
FROM families;


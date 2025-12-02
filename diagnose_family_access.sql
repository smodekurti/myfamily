-- ============================================================================
-- DIAGNOSE FAMILY ACCESS ISSUES
-- ============================================================================
-- Run this script to check if RLS policies are blocking family access
-- ============================================================================

-- Step 1: Check current user
SELECT 
  'Current User' as check_type,
  auth.uid() as user_id,
  auth.email() as email;

-- Step 2: Check family_members records for current user
SELECT 
  'Family Members for Current User' as check_type,
  COUNT(*) as count,
  array_agg(family_id) as family_ids
FROM family_members
WHERE user_id = auth.uid();

-- Step 3: Check if user can see their own family_members records
SELECT 
  'Can See Own Family Members' as check_type,
  COUNT(*) as visible_records
FROM family_members
WHERE user_id = auth.uid();

-- Step 4: Check if user can see other family members (should see all members of families they belong to)
SELECT 
  'Can See All Family Members' as check_type,
  COUNT(*) as visible_records,
  COUNT(DISTINCT family_id) as unique_families
FROM family_members;

-- Step 5: Check if user can see families they belong to
SELECT 
  'Can See Families' as check_type,
  COUNT(*) as visible_families,
  array_agg(id) as family_ids
FROM families;

-- Step 6: Check RLS policies on family_members
SELECT 
  'RLS Policies - family_members' as check_type,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'family_members'
ORDER BY policyname;

-- Step 7: Check RLS policies on families
SELECT 
  'RLS Policies - families' as check_type,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'families'
ORDER BY policyname;

-- Step 8: Test direct query (bypass RLS - only works if you're superuser)
-- Uncomment if you have superuser access
-- SET ROLE postgres;
-- SELECT COUNT(*) FROM family_members WHERE user_id = auth.uid();
-- RESET ROLE;


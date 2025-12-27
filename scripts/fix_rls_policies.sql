-- Fix RLS policies for user profile creation
-- This script addresses the infinite recursion and permission issues

-- First, let's drop ALL existing policies to start clean
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to view their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON users;
DROP POLICY IF EXISTS "Allow viewing family member profiles" ON users;

DROP POLICY IF EXISTS "Users can view families they belong to" ON families;
DROP POLICY IF EXISTS "Users can create families" ON families;

DROP POLICY IF EXISTS "Users can view family members of their families" ON family_members;

DROP POLICY IF EXISTS "Users can view tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their families" ON tasks;

DROP POLICY IF EXISTS "Users can view groceries in their families" ON groceries;
DROP POLICY IF EXISTS "Users can add groceries in their families" ON groceries;

DROP POLICY IF EXISTS "Users can view calendar events in their families" ON calendar_events;
DROP POLICY IF EXISTS "Users can create calendar events in their families" ON calendar_events;

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON users TO authenticated;
GRANT ALL ON families TO authenticated;
GRANT ALL ON family_members TO authenticated;
GRANT ALL ON tasks TO authenticated;
GRANT ALL ON groceries TO authenticated;
GRANT ALL ON calendar_events TO authenticated;

-- Grant sequence permissions for UUID generation
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create simple, non-recursive policies for users table
CREATE POLICY "users_insert_policy"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_select_policy"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "users_update_policy"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Create simple policies for families table
CREATE POLICY "families_select_policy"
  ON families FOR SELECT
  USING (created_by = auth.uid());

CREATE POLICY "families_insert_policy"
  ON families FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "families_update_policy"
  ON families FOR UPDATE
  USING (created_by = auth.uid());

-- Create simple policies for family_members table (no recursion)
CREATE POLICY "family_members_select_policy"
  ON family_members FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "family_members_insert_policy"
  ON family_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "family_members_update_policy"
  ON family_members FOR UPDATE
  USING (user_id = auth.uid());

-- Create simple policies for tasks table
CREATE POLICY "tasks_select_policy"
  ON tasks FOR SELECT
  USING (created_by = auth.uid() OR assigned_to = auth.uid());

CREATE POLICY "tasks_insert_policy"
  ON tasks FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "tasks_update_policy"
  ON tasks FOR UPDATE
  USING (created_by = auth.uid() OR assigned_to = auth.uid());

-- Create simple policies for groceries table
CREATE POLICY "groceries_select_policy"
  ON groceries FOR SELECT
  USING (added_by = auth.uid());

CREATE POLICY "groceries_insert_policy"
  ON groceries FOR INSERT
  WITH CHECK (added_by = auth.uid());

CREATE POLICY "groceries_update_policy"
  ON groceries FOR UPDATE
  USING (added_by = auth.uid());

-- Create simple policies for calendar_events table
CREATE POLICY "calendar_events_select_policy"
  ON calendar_events FOR SELECT
  USING (created_by = auth.uid());

CREATE POLICY "calendar_events_insert_policy"
  ON calendar_events FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "calendar_events_update_policy"
  ON calendar_events FOR UPDATE
  USING (created_by = auth.uid());

-- Fix RLS policies for real-time updates
-- All family members must be able to SELECT from tables for real-time to work
-- This ensures that when one user creates/updates an item, all family members can see it via real-time streams

-- ============================================================================
-- TASKS TABLE
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their families" ON tasks;
DROP POLICY IF EXISTS "tasks_select_policy" ON tasks;
DROP POLICY IF EXISTS "tasks_insert_policy" ON tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON tasks;

-- Create policies that allow all family members to view tasks
CREATE POLICY "Family members can view tasks"
  ON tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can update tasks"
  ON tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can delete tasks"
  ON tasks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- GROCERY_LISTS TABLE
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view lists for their families" ON grocery_lists;
DROP POLICY IF EXISTS "Users can create lists for their families" ON grocery_lists;
DROP POLICY IF EXISTS "Users can update lists for their families" ON grocery_lists;
DROP POLICY IF EXISTS "Users can delete lists for their families" ON grocery_lists;

-- Create policies that allow all family members to view grocery lists
CREATE POLICY "Family members can view grocery lists"
  ON grocery_lists FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can create grocery lists"
  ON grocery_lists FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can update grocery lists"
  ON grocery_lists FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can delete grocery lists"
  ON grocery_lists FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- GROCERY_LIST_ITEMS TABLE
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view list items for their family lists" ON grocery_list_items;
DROP POLICY IF EXISTS "Users can create list items for their family lists" ON grocery_list_items;
DROP POLICY IF EXISTS "Users can update list items for their family lists" ON grocery_list_items;
DROP POLICY IF EXISTS "Users can delete list items for their family lists" ON grocery_list_items;

-- Create policies that allow all family members to view grocery list items
CREATE POLICY "Family members can view grocery list items"
  ON grocery_list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can create grocery list items"
  ON grocery_list_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can update grocery list items"
  ON grocery_list_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can delete grocery list items"
  ON grocery_list_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- CALENDAR_EVENTS TABLE
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view calendar events in their families" ON calendar_events;
DROP POLICY IF EXISTS "Users can create calendar events in their families" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_select_policy" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_insert_policy" ON calendar_events;
DROP POLICY IF EXISTS "calendar_events_update_policy" ON calendar_events;

-- Create policies that allow all family members to view calendar events
CREATE POLICY "Family members can view calendar events"
  ON calendar_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can create calendar events"
  ON calendar_events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can update calendar events"
  ON calendar_events FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Family members can delete calendar events"
  ON calendar_events FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify policies were created
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
WHERE tablename IN ('tasks', 'grocery_lists', 'grocery_list_items', 'calendar_events')
ORDER BY tablename, policyname;


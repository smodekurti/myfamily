-- ============================================================================
-- PRODUCTION RLS POLICIES FOR MYFAMILY APP
-- ============================================================================
-- This script enables RLS and creates comprehensive policies for all tables
-- Run this in Supabase SQL Editor after backing up your database
-- ============================================================================

-- ============================================================================
-- STEP 1: Enable RLS on All Tables
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Drop Existing Policies (Clean Slate)
-- ============================================================================

-- Users table
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to view their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON users;
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON users;
DROP POLICY IF EXISTS "Allow viewing family member profiles" ON users;

-- Families table
DROP POLICY IF EXISTS "families_select_policy" ON families;
DROP POLICY IF EXISTS "families_insert_policy" ON families;
DROP POLICY IF EXISTS "families_update_policy" ON families;
DROP POLICY IF EXISTS "Users can view families they belong to" ON families;
DROP POLICY IF EXISTS "Users can create families" ON families;

-- Family members table
DROP POLICY IF EXISTS "family_members_select_policy" ON family_members;
DROP POLICY IF EXISTS "family_members_insert_policy" ON family_members;
DROP POLICY IF EXISTS "family_members_update_policy" ON family_members;
DROP POLICY IF EXISTS "Users can view family members of their families" ON family_members;

-- Tasks table
DROP POLICY IF EXISTS "tasks_select_policy" ON tasks;
DROP POLICY IF EXISTS "tasks_insert_policy" ON tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON tasks;
DROP POLICY IF EXISTS "tasks_delete_policy" ON tasks;
DROP POLICY IF EXISTS "Users can view tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their families" ON tasks;
DROP POLICY IF EXISTS "Family members can view tasks" ON tasks;
DROP POLICY IF EXISTS "Family members can create tasks" ON tasks;
DROP POLICY IF EXISTS "Family members can update tasks" ON tasks;
DROP POLICY IF EXISTS "Family members can delete tasks" ON tasks;

-- Grocery lists table
DROP POLICY IF EXISTS "Users can view groceries in their families" ON grocery_lists;
DROP POLICY IF EXISTS "Users can add groceries in their families" ON grocery_lists;

-- Grocery list items table
DROP POLICY IF EXISTS "Users can view grocery items in their families" ON grocery_list_items;
DROP POLICY IF EXISTS "Users can add grocery items in their families" ON grocery_list_items;

-- Calendar events table
DROP POLICY IF EXISTS "Users can view calendar events in their families" ON calendar_events;
DROP POLICY IF EXISTS "Users can create calendar events in their families" ON calendar_events;

-- ============================================================================
-- STEP 3: Create Comprehensive RLS Policies
-- ============================================================================

-- ============================================================================
-- USERS TABLE
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "users_select_own"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can view family members' profiles (for display names, avatars)
CREATE POLICY "users_select_family_members"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm1
      JOIN family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
      AND fm2.user_id = users.id
    )
  );

-- Users can insert their own profile (during signup)
CREATE POLICY "users_insert_own"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- FAMILIES TABLE
-- ============================================================================

-- Users can view families they belong to
CREATE POLICY "families_select_member"
  ON families FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
    )
  );

-- Users can create families
CREATE POLICY "families_insert_own"
  ON families FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Users can update families they created or are admins of
CREATE POLICY "families_update_own"
  ON families FOR UPDATE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'parent')
    )
  )
  WITH CHECK (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- FAMILY_MEMBERS TABLE
-- ============================================================================

-- Users can view family members of families they belong to
CREATE POLICY "family_members_select_family"
  ON family_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Users can insert themselves into families (via invite code)
CREATE POLICY "family_members_insert_self"
  ON family_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

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

-- Users can update their own family member record
CREATE POLICY "family_members_update_own"
  ON family_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Family admins/parents can update any member in their family
CREATE POLICY "family_members_update_admin"
  ON family_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = family_members.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- TASKS TABLE
-- ============================================================================

-- Family members can view tasks in their families
CREATE POLICY "tasks_select_family"
  ON tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create tasks in their families
CREATE POLICY "tasks_insert_family"
  ON tasks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update tasks in their families
CREATE POLICY "tasks_update_family"
  ON tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = tasks.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete tasks in their families (creator or admin)
CREATE POLICY "tasks_delete_family"
  ON tasks FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      JOIN families f ON fm.family_id = f.id
      WHERE fm.family_id = tasks.family_id
      AND fm.user_id = auth.uid()
      AND (fm.role IN ('admin', 'parent') OR f.created_by = auth.uid())
    )
  );

-- ============================================================================
-- GROCERY_LISTS TABLE
-- ============================================================================

-- Family members can view grocery lists in their families
CREATE POLICY "grocery_lists_select_family"
  ON grocery_lists FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create grocery lists in their families
CREATE POLICY "grocery_lists_insert_family"
  ON grocery_lists FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update grocery lists in their families
CREATE POLICY "grocery_lists_update_family"
  ON grocery_lists FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete grocery lists in their families
CREATE POLICY "grocery_lists_delete_family"
  ON grocery_lists FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = grocery_lists.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- GROCERY_LIST_ITEMS TABLE
-- ============================================================================

-- Family members can view grocery list items in their families
CREATE POLICY "grocery_list_items_select_family"
  ON grocery_list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists gl
      JOIN family_members fm ON fm.family_id = gl.family_id
      WHERE gl.id = grocery_list_items.list_id
      AND fm.user_id = auth.uid()
    )
  );

-- Family members can create grocery list items in their families
CREATE POLICY "grocery_list_items_insert_family"
  ON grocery_list_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM grocery_lists gl
      JOIN family_members fm ON fm.family_id = gl.family_id
      WHERE gl.id = grocery_list_items.list_id
      AND fm.user_id = auth.uid()
    )
    AND added_by = auth.uid()
  );

-- Family members can update grocery list items in their families
CREATE POLICY "grocery_list_items_update_family"
  ON grocery_list_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists gl
      JOIN family_members fm ON fm.family_id = gl.family_id
      WHERE gl.id = grocery_list_items.list_id
      AND fm.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM grocery_lists gl
      JOIN family_members fm ON fm.family_id = gl.family_id
      WHERE gl.id = grocery_list_items.list_id
      AND fm.user_id = auth.uid()
    )
  );

-- Family members can delete grocery list items in their families
CREATE POLICY "grocery_list_items_delete_family"
  ON grocery_list_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists gl
      JOIN family_members fm ON fm.family_id = gl.family_id
      WHERE gl.id = grocery_list_items.list_id
      AND fm.user_id = auth.uid()
    )
  );

-- ============================================================================
-- CALENDAR_EVENTS TABLE
-- ============================================================================

-- Family members can view calendar events in their families
CREATE POLICY "calendar_events_select_family"
  ON calendar_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create calendar events in their families
CREATE POLICY "calendar_events_insert_family"
  ON calendar_events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update calendar events in their families
CREATE POLICY "calendar_events_update_family"
  ON calendar_events FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = calendar_events.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete calendar events in their families
CREATE POLICY "calendar_events_delete_family"
  ON calendar_events FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = calendar_events.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- ANNOUNCEMENTS TABLE
-- ============================================================================

-- Family members can view announcements in their families
CREATE POLICY "announcements_select_family"
  ON announcements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = announcements.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create announcements in their families
CREATE POLICY "announcements_insert_family"
  ON announcements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = announcements.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update announcements in their families
CREATE POLICY "announcements_update_family"
  ON announcements FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = announcements.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = announcements.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete announcements in their families
CREATE POLICY "announcements_delete_family"
  ON announcements FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- GROCERY_TEMPLATES TABLE
-- ============================================================================

-- Family members can view grocery templates in their families
CREATE POLICY "grocery_templates_select_family"
  ON grocery_templates FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create grocery templates in their families
CREATE POLICY "grocery_templates_insert_family"
  ON grocery_templates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update grocery templates in their families
CREATE POLICY "grocery_templates_update_family"
  ON grocery_templates FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete grocery templates in their families
CREATE POLICY "grocery_templates_delete_family"
  ON grocery_templates FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = grocery_templates.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- TASK_TEMPLATES TABLE
-- ============================================================================

-- Family members can view task templates in their families
CREATE POLICY "task_templates_select_family"
  ON task_templates FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = task_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can create task templates in their families
CREATE POLICY "task_templates_insert_family"
  ON task_templates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = task_templates.family_id
      AND family_members.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Family members can update task templates in their families
CREATE POLICY "task_templates_update_family"
  ON task_templates FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = task_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = task_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- Family members can delete task templates in their families
CREATE POLICY "task_templates_delete_family"
  ON task_templates FOR DELETE
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = task_templates.family_id
      AND fm.user_id = auth.uid()
      AND fm.role IN ('admin', 'parent')
    )
  );

-- ============================================================================
-- POINTS_HISTORY TABLE
-- ============================================================================

-- Users can view their own points history
CREATE POLICY "points_history_select_own"
  ON points_history FOR SELECT
  USING (user_id = auth.uid());

-- Family members can view each other's points (for leaderboard)
CREATE POLICY "points_history_select_family"
  ON points_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm1
      JOIN family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
      AND fm2.user_id = points_history.user_id
    )
  );

-- System can insert points (via service role or function)
-- Note: This should be done via Edge Function or service role, not directly

-- ============================================================================
-- ACHIEVEMENTS TABLE
-- ============================================================================

-- Users can view their own achievements
CREATE POLICY "achievements_select_own"
  ON achievements FOR SELECT
  USING (user_id = auth.uid());

-- Family members can view each other's achievements
CREATE POLICY "achievements_select_family"
  ON achievements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members fm1
      JOIN family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
      AND fm2.user_id = achievements.user_id
    )
  );

-- ============================================================================
-- USER_FCM_TOKENS TABLE
-- ============================================================================

-- Users can view their own FCM tokens
CREATE POLICY "user_fcm_tokens_select_own"
  ON user_fcm_tokens FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own FCM tokens
CREATE POLICY "user_fcm_tokens_insert_own"
  ON user_fcm_tokens FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own FCM tokens
CREATE POLICY "user_fcm_tokens_update_own"
  ON user_fcm_tokens FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own FCM tokens
CREATE POLICY "user_fcm_tokens_delete_own"
  ON user_fcm_tokens FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these to verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Run these to verify policies exist:
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;


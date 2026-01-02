-- Migration: Fix task visibility to hide personal tasks from others
-- Personal Task = Assigned to self (assigned_to == created_by)

-- Drop all existing SELECT policies on tasks to prevent permissive leaks
-- We iterate over existing SELECT policies on the 'tasks' table and drop them.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'tasks' AND cmd = 'SELECT' LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON tasks';
    END LOOP;
END $$;

-- 1. Re-create Admin SELECT Policy (as defined in 20251230200000)
-- Ensure 'is_admin' function exists (it should from previous migrations)
CREATE POLICY "Admins can view all tasks" ON tasks
    FOR SELECT USING (is_admin());

-- 2. Create Standard User SELECT Policy with Privacy Restriction
-- Users can see tasks if:
--   a) The task belongs to their family
--   AND
--   b) It is NOT a personal task of someone else
--      (Personal Task = Task where assigned_to == created_by)
--      (Someone else's = assigned_to != auth.uid())
CREATE POLICY "Users can view family tasks" ON tasks
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM family_members WHERE user_id = auth.uid()
        )
        AND (
            -- Visible if:
            -- 1. It is NOT personal (assigned_to != created_by) -> Shared task
            -- OR
            -- 2. It IS personal BUT it is MINE (assigned_to == auth.uid())
            
            -- Simplified Login:
            -- NOT (Personal AND SomeoneElse)
            NOT (
                assigned_to = created_by 
                AND assigned_to != auth.uid()
            )
        )
    );

-- Ensure RLS is enabled
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

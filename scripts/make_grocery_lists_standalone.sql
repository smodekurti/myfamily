-- Make task_id optional in grocery_lists table to support standalone lists
-- Run this in Supabase Dashboard → SQL Editor

-- Make task_id nullable
ALTER TABLE grocery_lists
ALTER COLUMN task_id DROP NOT NULL;

-- Add comment to clarify usage
COMMENT ON COLUMN grocery_lists.task_id IS 'Optional: Links to a task if this list is part of a task. NULL for standalone lists.';


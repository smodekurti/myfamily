-- Enable real-time for tasks table
-- This is required for Supabase real-time subscriptions to work properly
-- REPLICA IDENTITY FULL allows Supabase to track all changes to rows

ALTER TABLE tasks REPLICA IDENTITY FULL;

-- Verify the change
-- You can check this by running: SELECT relreplident FROM pg_class WHERE relname = 'tasks';
-- It should return 'f' (FULL) instead of 'd' (DEFAULT)


-- Enable real-time for all tables that use Supabase streams
-- This is required for Supabase real-time subscriptions to work properly
-- REPLICA IDENTITY FULL allows Supabase to track all changes to rows

-- Tasks table (for real-time task updates)
ALTER TABLE tasks REPLICA IDENTITY FULL;

-- Grocery lists table (for real-time grocery list updates)
ALTER TABLE grocery_lists REPLICA IDENTITY FULL;

-- Grocery list items table (for real-time item updates within lists)
ALTER TABLE grocery_list_items REPLICA IDENTITY FULL;

-- Calendar events table (for real-time calendar event updates)
ALTER TABLE calendar_events REPLICA IDENTITY FULL;

-- Verify the changes
-- You can check this by running:
-- SELECT relname, relreplident FROM pg_class WHERE relname IN ('tasks', 'grocery_lists', 'grocery_list_items', 'calendar_events');
-- All should return 'f' (FULL) instead of 'd' (DEFAULT)


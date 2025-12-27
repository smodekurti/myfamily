-- TEMPORARY FIX: Disable RLS for testing
-- This allows user profile creation during sign-up
-- IMPORTANT: Only use this for development/testing

-- Disable RLS on all tables temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE families DISABLE ROW LEVEL SECURITY;
ALTER TABLE family_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE groceries DISABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events DISABLE ROW LEVEL SECURITY;

-- Grant all permissions to authenticated users
GRANT ALL ON users TO authenticated;
GRANT ALL ON families TO authenticated;
GRANT ALL ON family_members TO authenticated;
GRANT ALL ON tasks TO authenticated;
GRANT ALL ON groceries TO authenticated;
GRANT ALL ON calendar_events TO authenticated;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;



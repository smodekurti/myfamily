-- Add role column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin'));

-- Helper function to check if user is admin (avoids repetition in policies)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS Policies to allow Admins to view all data

-- Users (Profiles)
CREATE POLICY "Admins can view all profiles" ON users
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all profiles" ON users
    FOR UPDATE USING (is_admin());

-- Families
CREATE POLICY "Admins can view all families" ON families
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all families" ON families
    FOR UPDATE USING (is_admin());

-- Family Members
CREATE POLICY "Admins can view all family members" ON family_members
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all family members" ON family_members
    FOR UPDATE USING (is_admin());

-- Tasks
CREATE POLICY "Admins can view all tasks" ON tasks
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all tasks" ON tasks
    FOR UPDATE USING (is_admin());

-- Grocery Lists
CREATE POLICY "Admins can view all grocery lists" ON grocery_lists
    FOR SELECT USING (is_admin());

-- Grocery List Items (Corrected table name)
CREATE POLICY "Admins can view all grocery list items" ON grocery_list_items
    FOR SELECT USING (is_admin());

-- Messages
CREATE POLICY "Admins can view all messages" ON messages
    FOR SELECT USING (is_admin());

-- Grocery Templates (CMS Features - Admins have full access)
CREATE POLICY "Admins can manage grocery templates" ON grocery_templates
    FOR ALL USING (is_admin());

CREATE POLICY "Admins can manage grocery template items" ON grocery_template_items
    FOR ALL USING (is_admin());

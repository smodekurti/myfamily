-- ============================================================================
-- ENSURE ROLE PERMISSIONS EXIST
-- ============================================================================
-- This script ensures all role permissions are properly set up
-- Run this in Supabase SQL Editor if you see "No permissions found for role" warnings
-- ============================================================================

-- Step 1: Ensure role_permissions table exists
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  role TEXT NOT NULL UNIQUE,
  permissions JSONB NOT NULL,
  restrictions JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Enable RLS (if not already enabled)
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop existing policies (if any) and create a simple one
DROP POLICY IF EXISTS "role_permissions_select_all" ON role_permissions;
DROP POLICY IF EXISTS "Users can view role permissions" ON role_permissions;

-- Create policy: All authenticated users can view role permissions
-- (This is safe because role permissions are not sensitive - they're defaults)
CREATE POLICY "role_permissions_select_all"
  ON role_permissions FOR SELECT
  USING (auth.role() = 'authenticated');

-- Step 4: Insert/Update all role permissions
-- Parent role
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('parent', 
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": true, "can_assign_tasks": true, "can_create_events": true, "can_edit_events": true, "can_delete_events": true, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": true, "can_create_templates": true, "can_delete_templates": true, "can_create_announcements": true, "can_manage_family": true, "can_invite_members": true, "can_change_roles": true, "can_view_all_data": true, "can_view_points": true, "can_delete_family": true}',
 '{}')
ON CONFLICT (role) DO UPDATE SET
  permissions = EXCLUDED.permissions,
  restrictions = EXCLUDED.restrictions,
  updated_at = NOW();

-- Caretaker role
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('caretaker',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": true, "can_create_events": true, "can_edit_events": true, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO UPDATE SET
  permissions = EXCLUDED.permissions,
  restrictions = EXCLUDED.restrictions,
  updated_at = NOW();

-- Guardian role
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('guardian',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": true, "can_create_events": false, "can_edit_events": false, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO UPDATE SET
  permissions = EXCLUDED.permissions,
  restrictions = EXCLUDED.restrictions,
  updated_at = NOW();

-- Member role
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('member',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": false, "can_create_events": false, "can_edit_events": false, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO UPDATE SET
  permissions = EXCLUDED.permissions,
  restrictions = EXCLUDED.restrictions,
  updated_at = NOW();

-- Child role (this is the one that's missing)
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('child',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": false, "can_create_events": true, "can_edit_events": true, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": true, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{"can_only_view_assigned_tasks": false, "can_only_complete_own_tasks": false, "can_view_calendar": true, "can_view_grocery_lists_readonly": false, "cannot_view_announcements": false, "cannot_view_leaderboard": false}')
ON CONFLICT (role) DO UPDATE SET
  permissions = EXCLUDED.permissions,
  restrictions = EXCLUDED.restrictions,
  updated_at = NOW();

-- Step 5: Verify all roles exist
SELECT 
  'Verification' as check_type,
  role,
  jsonb_object_keys(permissions) as permission_key,
  permissions->jsonb_object_keys(permissions) as permission_value
FROM role_permissions
ORDER BY role, permission_key;

-- Step 6: Show summary
SELECT 
  'Summary' as check_type,
  COUNT(*) as total_roles,
  array_agg(role) as roles
FROM role_permissions;


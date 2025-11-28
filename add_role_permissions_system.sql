-- Role-Based Access Control System Migration
-- This migration adds role permissions, parent limit enforcement, and parent-specific invite codes

-- Step 1: Add parent_invite_code column to families table
ALTER TABLE families 
ADD COLUMN IF NOT EXISTS parent_invite_code TEXT UNIQUE;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_families_parent_invite_code ON families(parent_invite_code);

-- Step 2: Ensure role column exists in family_members (should already exist)
ALTER TABLE family_members 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';

-- Add permissions and restrictions columns for flexibility
ALTER TABLE family_members 
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS restrictions JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS assigned_by UUID REFERENCES auth.users(id);

-- Step 3: Create role_permissions table for default role configurations
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  role TEXT NOT NULL UNIQUE,
  permissions JSONB NOT NULL,
  restrictions JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Insert default role permissions
INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('parent', 
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": true, "can_assign_tasks": true, "can_create_events": true, "can_edit_events": true, "can_delete_events": true, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": true, "can_create_templates": true, "can_delete_templates": true, "can_create_announcements": true, "can_manage_family": true, "can_invite_members": true, "can_change_roles": true, "can_view_all_data": true, "can_view_points": true, "can_delete_family": true}',
 '{}')
ON CONFLICT (role) DO NOTHING;

INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('caretaker',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": true, "can_create_events": true, "can_edit_events": true, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO NOTHING;

INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('guardian',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": true, "can_create_events": false, "can_edit_events": false, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO NOTHING;

INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('member',
 '{"can_create_tasks": true, "can_edit_tasks": true, "can_delete_tasks": false, "can_assign_tasks": false, "can_create_events": false, "can_edit_events": false, "can_delete_events": false, "can_create_lists": true, "can_edit_lists": true, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": true, "can_view_points": true, "can_delete_family": false}',
 '{}')
ON CONFLICT (role) DO NOTHING;

INSERT INTO role_permissions (role, permissions, restrictions) VALUES
('child',
 '{"can_create_tasks": false, "can_edit_tasks": false, "can_delete_tasks": false, "can_assign_tasks": false, "can_create_events": false, "can_edit_events": false, "can_delete_events": false, "can_create_lists": false, "can_edit_lists": false, "can_delete_lists": false, "can_create_templates": false, "can_delete_templates": false, "can_create_announcements": false, "can_manage_family": false, "can_invite_members": false, "can_change_roles": false, "can_view_all_data": false, "can_view_points": false, "can_delete_family": false}',
 '{"can_only_view_assigned_tasks": true, "can_only_complete_own_tasks": true, "can_view_calendar": true, "can_view_grocery_lists_readonly": true, "cannot_view_announcements": true, "cannot_view_leaderboard": true}')
ON CONFLICT (role) DO NOTHING;

-- Step 5: Create function to check parent limit (max 2 parents per family)
CREATE OR REPLACE FUNCTION check_parent_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'parent' THEN
    IF (SELECT COUNT(*) FROM family_members 
        WHERE family_id = NEW.family_id AND role = 'parent') >= 2 THEN
      RAISE EXCEPTION 'Maximum of 2 parents allowed per family';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to enforce parent limit
DROP TRIGGER IF EXISTS enforce_parent_limit ON family_members;
CREATE TRIGGER enforce_parent_limit
BEFORE INSERT OR UPDATE ON family_members
FOR EACH ROW
EXECUTE FUNCTION check_parent_limit();

-- Step 7: Create function to get parent count for a family
CREATE OR REPLACE FUNCTION get_parent_count(family_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (SELECT COUNT(*) FROM family_members 
          WHERE family_id = family_uuid AND role = 'parent');
END;
$$ LANGUAGE plpgsql;

-- Step 8: Add comments for documentation
COMMENT ON COLUMN families.parent_invite_code IS 'Invite code specifically for parents (starts with P) - separate from adult and child codes';
COMMENT ON COLUMN family_members.role IS 'User role in family: parent, caretaker, guardian, member, or child';
COMMENT ON COLUMN family_members.permissions IS 'JSONB object with specific permissions for this member (overrides role defaults)';
COMMENT ON COLUMN family_members.restrictions IS 'JSONB object with specific restrictions for this member (overrides role defaults)';
COMMENT ON TABLE role_permissions IS 'Default permissions and restrictions for each role type';


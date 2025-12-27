-- Fix parent limit trigger to only check when role changes
-- The trigger was incorrectly firing on all updates, including points updates

-- Drop the existing trigger
DROP TRIGGER IF EXISTS enforce_parent_limit ON family_members;

-- Update the function to only check when role is being changed to 'parent'
CREATE OR REPLACE FUNCTION check_parent_limit()
RETURNS TRIGGER AS $$
BEGIN
  -- Only check parent limit when:
  -- 1. Inserting a new member with role 'parent', OR
  -- 2. Updating an existing member's role TO 'parent' (role changed)
  IF NEW.role = 'parent' AND (TG_OP = 'INSERT' OR OLD.role != 'parent') THEN
    -- Count existing parents (excluding the current row if updating)
    DECLARE
      parent_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO parent_count
      FROM family_members 
      WHERE family_id = NEW.family_id 
        AND role = 'parent'
        AND (TG_OP = 'INSERT' OR id != NEW.id);
      
      IF parent_count >= 2 THEN
        RAISE EXCEPTION 'Maximum of 2 parents allowed per family';
      END IF;
    END;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER enforce_parent_limit
BEFORE INSERT OR UPDATE ON family_members
FOR EACH ROW
EXECUTE FUNCTION check_parent_limit();

-- Add comment
COMMENT ON FUNCTION check_parent_limit() IS 'Enforces maximum of 2 parents per family. Only checks when role is being set to parent, not on other column updates like points.';


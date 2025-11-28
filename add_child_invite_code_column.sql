-- Add child_invite_code column to families table
-- This enables role-based invite codes for adults vs children

-- Add the child_invite_code column
ALTER TABLE families 
ADD COLUMN child_invite_code VARCHAR(10) UNIQUE;

-- Add comment to document the purpose
COMMENT ON COLUMN families.child_invite_code IS 'Invite code for children (starts with C) - separate from adult invite code';

-- Create index for faster lookups
CREATE INDEX idx_families_child_invite_code ON families(child_invite_code);

-- Update RLS policy to allow reading child_invite_code
-- (The existing policies should already cover this, but let's be explicit)

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'families' 
AND column_name = 'child_invite_code';










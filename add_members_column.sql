-- Add missing members column to families table
-- Run this in Supabase Dashboard → SQL Editor

-- Add members column as TEXT array
ALTER TABLE families 
ADD COLUMN IF NOT EXISTS members TEXT[] DEFAULT '{}';

-- Update existing families to have empty members array
UPDATE families 
SET members = '{}' 
WHERE members IS NULL;

-- Verify the column was added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'families' AND column_name = 'members';










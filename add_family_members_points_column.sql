-- Add points column to family_members table
-- Run this in Supabase Dashboard → SQL Editor

-- Add points column if it doesn't exist
ALTER TABLE family_members 
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;

-- Add notification_tokens column if it doesn't exist
ALTER TABLE family_members 
ADD COLUMN IF NOT EXISTS notification_tokens TEXT[] DEFAULT '{}';

-- Add updated_at column if it doesn't exist
ALTER TABLE family_members 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing records to have default values
UPDATE family_members 
SET 
  points = COALESCE(points, 0),
  notification_tokens = COALESCE(notification_tokens, '{}'),
  updated_at = COALESCE(updated_at, joined_at, NOW())
WHERE points IS NULL OR notification_tokens IS NULL OR updated_at IS NULL;

-- Create index on points for faster sorting
CREATE INDEX IF NOT EXISTS idx_family_members_points ON family_members(points);

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'family_members' 
ORDER BY ordinal_position;


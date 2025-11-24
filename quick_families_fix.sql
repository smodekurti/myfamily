-- Quick fix for families table - add all missing columns
-- Run this in Supabase Dashboard → SQL Editor

-- Add all missing columns to families table
ALTER TABLE families 
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS invite_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS invite_link TEXT,
ADD COLUMN IF NOT EXISTS theme_preference TEXT DEFAULT 'system',
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing records with default values
UPDATE families 
SET 
  created_at = COALESCE(created_at, NOW()),
  updated_at = COALESCE(updated_at, NOW()),
  theme_preference = COALESCE(theme_preference, 'system'),
  total_points = COALESCE(total_points, 0)
WHERE created_at IS NULL OR updated_at IS NULL OR theme_preference IS NULL OR total_points IS NULL;

-- Create index on invite_code for faster lookups
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);

-- Verify the table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'families' 
ORDER BY ordinal_position;









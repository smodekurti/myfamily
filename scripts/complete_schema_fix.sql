-- Complete schema fix for MyFamily app
-- This ensures all tables have the correct columns to match the models

-- Fix families table
ALTER TABLE families 
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS invite_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS invite_link TEXT,
ADD COLUMN IF NOT EXISTS theme_preference TEXT DEFAULT 'system',
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0;

-- Create index on invite_code
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);

-- Fix users table (ensure all columns exist)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS families TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS total_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS theme_preference TEXT DEFAULT 'system',
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Fix family_members table (ensure it exists and has correct structure)
CREATE TABLE IF NOT EXISTS family_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(family_id, user_id)
);

-- Fix tasks table (ensure it exists and has correct structure)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id),
  created_by UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  category TEXT DEFAULT 'chore',
  category_data JSONB,
  due_date TIMESTAMPTZ,
  points INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Add category and category_data columns if they don't exist (for existing tables)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'chore';

ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category_data JSONB;

-- Update existing tasks to have default category
UPDATE tasks 
SET category = 'chore' 
WHERE category IS NULL;

-- Create index on category for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);

-- Fix groceries table (ensure it exists and has correct structure)
CREATE TABLE IF NOT EXISTS groceries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  category TEXT,
  notes TEXT,
  is_purchased BOOLEAN DEFAULT false,
  added_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fix calendar_events table (ensure it exists and has correct structure)
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update existing families with default values
UPDATE families 
SET 
  theme_preference = COALESCE(theme_preference, 'system'),
  total_points = COALESCE(total_points, 0)
WHERE theme_preference IS NULL OR total_points IS NULL;

-- Update existing users with default values
UPDATE users 
SET 
  families = COALESCE(families, '{}'),
  total_points = COALESCE(total_points, 0),
  theme_preference = COALESCE(theme_preference, 'system'),
  notifications_enabled = COALESCE(notifications_enabled, true)
WHERE families IS NULL OR total_points IS NULL OR theme_preference IS NULL OR notifications_enabled IS NULL;

-- Show the final table structures
SELECT 'families' as table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'families' 
UNION ALL
SELECT 'users' as table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY table_name, column_name;









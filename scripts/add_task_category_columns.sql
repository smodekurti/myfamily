-- Add category and category_data columns to tasks table
-- This migration adds support for task categories (chore, grocery, etc.)

-- Add category column with default value 'chore'
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'chore';

-- Add category_data column for category-specific JSON data
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category_data JSONB;

-- Update existing tasks to have default category
UPDATE tasks 
SET category = 'chore' 
WHERE category IS NULL;

-- Create index on category for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);

-- Add comment to explain the columns
COMMENT ON COLUMN tasks.category IS 'Task category: chore, grocery, event, etc.';
COMMENT ON COLUMN tasks.category_data IS 'Category-specific data stored as JSON (e.g., groceryListId for grocery tasks)';


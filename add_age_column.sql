-- Add age column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add comment to the column
COMMENT ON COLUMN users.age IS 'User age in years, required for family creators (18+)';












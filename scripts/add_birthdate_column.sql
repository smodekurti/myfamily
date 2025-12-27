-- Add birthdate column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS birthdate DATE;

-- Add comment to the column
COMMENT ON COLUMN users.birthdate IS 'User birthdate, used to calculate age and validate family creation (18+)';

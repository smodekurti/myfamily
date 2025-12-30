-- Add REMOVED_SECRET column to families table
ALTER TABLE families ADD COLUMN IF NOT EXISTS REMOVED_SECRET TEXT;

-- Comment on column
COMMENT ON COLUMN families.REMOVED_SECRET IS 'Shared Google Gemini API Key for the family';

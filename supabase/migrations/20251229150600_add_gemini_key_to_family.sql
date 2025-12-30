-- Add gemini_api_key column to families table
ALTER TABLE families ADD COLUMN IF NOT EXISTS gemini_api_key TEXT;

-- Comment on column
COMMENT ON COLUMN families.gemini_api_key IS 'Shared Google Gemini API Key for the family';

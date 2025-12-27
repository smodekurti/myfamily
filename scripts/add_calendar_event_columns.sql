-- Add color and participants columns to calendar_events table
ALTER TABLE calendar_events
ADD COLUMN IF NOT EXISTS color TEXT;

ALTER TABLE calendar_events
ADD COLUMN IF NOT EXISTS participants TEXT[] DEFAULT '{}';

-- Update existing records to set default values
UPDATE calendar_events
SET participants = COALESCE(participants, '{}')
WHERE participants IS NULL;


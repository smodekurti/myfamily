-- Add deleted_at column to families table for soft deletes
ALTER TABLE public.families
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Update RLS policies to hide soft-deleted families from normal queries if needed
-- For now, we just add the column. 
-- The application logic will handle filtering or we can add a policy later if we want strict enforcement.
-- Ideally, we might want to update the "Select families" policy to exclude deleted ones, 
-- but since the user query is "get users families", and we are removing the user from the family_members table,
-- they won't see it anyway. 
-- So simply adding the column is sufficient for the "Archival" requirement.

-- Create announcements table for family-wide messaging
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ,
  read_by TEXT[] DEFAULT '{}' -- Array of user IDs who have read this announcement
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_announcements_family_id ON announcements(family_id);
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_created_by ON announcements(created_by);

-- Enable RLS
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for announcements
-- Users can view announcements in their families
CREATE POLICY "Users can view announcements in their families" ON announcements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Users can create announcements in their families
CREATE POLICY "Users can create announcements in their families" ON announcements
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
    )
    AND created_by = auth.uid()
  );

-- Users can update their own announcements
CREATE POLICY "Users can update their own announcements" ON announcements
  FOR UPDATE USING (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Users can delete their own announcements
CREATE POLICY "Users can delete their own announcements" ON announcements
  FOR DELETE USING (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Users can mark announcements as read (update read_by array)
CREATE POLICY "Users can mark announcements as read" ON announcements
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = announcements.family_id
      AND fm.user_id = auth.uid()
    )
  );




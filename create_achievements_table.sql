-- Create achievements table for tracking user achievements/badges
-- Run this in Supabase Dashboard → SQL Editor

-- Create achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL, -- e.g., 'first_task', 'streak_starter', 'task_master', etc.
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, family_id, achievement_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_family_id ON achievements(family_id);
CREATE INDEX IF NOT EXISTS idx_achievements_achievement_id ON achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievements_user_family ON achievements(user_id, family_id);

-- Enable RLS
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (using family_members table to avoid UUID/TEXT type issues)
CREATE POLICY "Users can view achievements in their families" ON achievements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = achievements.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert achievements in their families" ON achievements
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = achievements.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Note: Achievements are typically immutable (no update/delete policies needed)
-- Users can view their own achievements and the system can insert new ones

-- Grant permissions to authenticated users
GRANT ALL ON achievements TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;


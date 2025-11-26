-- Create points_history table to track all points transactions
CREATE TABLE IF NOT EXISTS points_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL, -- Can be positive (awarded) or negative (removed)
  reason TEXT NOT NULL, -- e.g., 'task_completed', 'task_uncompleted', 'bonus', etc.
  task_id UUID REFERENCES tasks(id) ON DELETE SET NULL, -- Reference to task if points are from task completion
  task_title TEXT, -- Task title for display (denormalized for performance)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_points_history_family_id ON points_history(family_id);
CREATE INDEX IF NOT EXISTS idx_points_history_user_id ON points_history(user_id);
CREATE INDEX IF NOT EXISTS idx_points_history_created_at ON points_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_points_history_task_id ON points_history(task_id);

-- Enable RLS
ALTER TABLE points_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for points_history
CREATE POLICY "Users can view points history in their families" ON points_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = points_history.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "System can insert points history" ON points_history
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = points_history.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Grant permissions to authenticated users
GRANT ALL ON points_history TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;


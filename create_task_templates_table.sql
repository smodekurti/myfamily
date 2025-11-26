-- Create task_templates table to store reusable task configurations
CREATE TABLE IF NOT EXISTS task_templates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- Template name (e.g., "Weekly Cleaning", "Monthly Review")
  title TEXT NOT NULL, -- Default task title
  description TEXT, -- Default task description
  category TEXT DEFAULT 'chore', -- Task category
  priority TEXT DEFAULT 'medium', -- Task priority
  points INTEGER DEFAULT 10, -- Default points
  recurrence_type TEXT, -- 'none', 'daily', 'weekly', 'monthly'
  recurrence_end_date TIMESTAMPTZ, -- Optional end date for recurrence
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_task_templates_family_id ON task_templates(family_id);
CREATE INDEX IF NOT EXISTS idx_task_templates_created_by ON task_templates(created_by);

-- Enable RLS
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for task_templates
CREATE POLICY "Users can view task templates in their families" ON task_templates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = task_templates.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create task templates in their families" ON task_templates
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = task_templates.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update task templates in their families" ON task_templates
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = task_templates.family_id
      AND fm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete task templates in their families" ON task_templates
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.family_id = task_templates.family_id
      AND fm.user_id = auth.uid()
    )
  );

-- Grant permissions to authenticated users
GRANT ALL ON task_templates TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;


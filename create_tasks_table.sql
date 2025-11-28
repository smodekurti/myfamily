-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id),
  created_by UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  due_date TIMESTAMPTZ,
  points INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);

-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for tasks
CREATE POLICY "Users can view tasks in their families" ON tasks
  FOR SELECT USING (
    family_id IN (
      SELECT f.id FROM families f 
      WHERE f.id = tasks.family_id 
      AND auth.uid() = ANY(f.members)
    )
  );

CREATE POLICY "Users can create tasks in their families" ON tasks
  FOR INSERT WITH CHECK (
    family_id IN (
      SELECT f.id FROM families f 
      WHERE f.id = tasks.family_id 
      AND auth.uid() = ANY(f.members)
    )
  );

CREATE POLICY "Users can update tasks in their families" ON tasks
  FOR UPDATE USING (
    family_id IN (
      SELECT f.id FROM families f 
      WHERE f.id = tasks.family_id 
      AND auth.uid() = ANY(f.members)
    )
  );

CREATE POLICY "Users can delete tasks in their families" ON tasks
  FOR DELETE USING (
    family_id IN (
      SELECT f.id FROM families f 
      WHERE f.id = tasks.family_id 
      AND auth.uid() = ANY(f.members)
    )
  );

-- Grant permissions to authenticated users
GRANT ALL ON tasks TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;











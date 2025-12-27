# Database Migrations Guide

This file contains all SQL migrations that need to be run in your Supabase project.

## How to Run Migrations

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy and paste the SQL from the migration file below
5. Click **Run** (or press Cmd/Ctrl + Enter)
6. Verify the table was created in **Table Editor**

---

## Migration: Points History Table

**File:** `create_points_history_table.sql`

**When to run:** Before using the Points History feature

**SQL:**

```sql
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
```

---

## Migration: Task Templates Table

**File:** `create_task_templates_table.sql`

**When to run:** Before using the Task Templates feature

**SQL:**

```sql
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
```

---

## Migration: Achievements Table

**File:** `create_achievements_table.sql` (if exists)

**When to run:** Before using the Achievements feature

**Note:** Check if this file exists and add the SQL here if needed.

---

## Quick Checklist

- [ ] Points History table created
- [ ] Task Templates table created
- [ ] Achievements table created (if applicable)
- [ ] All RLS policies are active
- [ ] Indexes are created
- [ ] Test queries work in SQL Editor

---

## Troubleshooting

### "Table already exists" error
- This is safe to ignore if using `CREATE TABLE IF NOT EXISTS`
- The migration is idempotent (can be run multiple times safely)

### "Permission denied" error
- Make sure you're running the SQL as a database admin
- Check that RLS policies are correctly set up

### "Foreign key constraint" error
- Ensure parent tables (families, users, tasks) exist first
- Run migrations in order if dependencies exist

---

## Need Help?

If you encounter issues:
1. Check the Supabase logs in the dashboard
2. Verify your table structure matches the SQL
3. Ensure RLS policies are enabled and correct
4. Check that foreign key references are valid


-- Create grocery templates and related tables
-- Run this in Supabase Dashboard → SQL Editor

-- Create grocery_templates table
CREATE TABLE IF NOT EXISTS grocery_templates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create grocery_template_items table
CREATE TABLE IF NOT EXISTS grocery_template_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  template_id UUID REFERENCES grocery_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  default_qty INTEGER DEFAULT 1,
  notes TEXT,
  unit TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create grocery_lists table
CREATE TABLE IF NOT EXISTS grocery_lists (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  template_id UUID REFERENCES grocery_templates(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create grocery_list_items table
CREATE TABLE IF NOT EXISTS grocery_list_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  list_id UUID REFERENCES grocery_lists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  qty INTEGER DEFAULT 1,
  notes TEXT,
  unit TEXT,
  checked BOOLEAN DEFAULT FALSE,
  checked_at TIMESTAMPTZ,
  source TEXT, -- 'template' or 'manual'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE grocery_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_template_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_list_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for grocery_templates
CREATE POLICY "Users can view templates for their families"
  ON grocery_templates FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create templates for their families"
  ON grocery_templates FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_templates.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update templates they created"
  ON grocery_templates FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can delete templates they created"
  ON grocery_templates FOR DELETE
  USING (created_by = auth.uid());

-- RLS Policies for grocery_template_items
CREATE POLICY "Users can view template items for their family templates"
  ON grocery_template_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM grocery_templates
      JOIN family_members ON family_members.family_id = grocery_templates.family_id
      WHERE grocery_template_items.template_id = grocery_templates.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create template items for their family templates"
  ON grocery_template_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM grocery_templates
      JOIN family_members ON family_members.family_id = grocery_templates.family_id
      WHERE grocery_template_items.template_id = grocery_templates.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update template items for their family templates"
  ON grocery_template_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_templates
      JOIN family_members ON family_members.family_id = grocery_templates.family_id
      WHERE grocery_template_items.template_id = grocery_templates.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete template items for their family templates"
  ON grocery_template_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_templates
      JOIN family_members ON family_members.family_id = grocery_templates.family_id
      WHERE grocery_template_items.template_id = grocery_templates.id
      AND family_members.user_id = auth.uid()
    )
  );

-- RLS Policies for grocery_lists
CREATE POLICY "Users can view lists for their families"
  ON grocery_lists FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create lists for their families"
  ON grocery_lists FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update lists for their families"
  ON grocery_lists FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete lists for their families"
  ON grocery_lists FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE family_members.family_id = grocery_lists.family_id
      AND family_members.user_id = auth.uid()
    )
  );

-- RLS Policies for grocery_list_items
CREATE POLICY "Users can view list items for their family lists"
  ON grocery_list_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create list items for their family lists"
  ON grocery_list_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update list items for their family lists"
  ON grocery_list_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete list items for their family lists"
  ON grocery_list_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM grocery_lists
      JOIN family_members ON family_members.family_id = grocery_lists.family_id
      WHERE grocery_list_items.list_id = grocery_lists.id
      AND family_members.user_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_grocery_templates_family_id ON grocery_templates(family_id);
CREATE INDEX IF NOT EXISTS idx_grocery_templates_created_by ON grocery_templates(created_by);
CREATE INDEX IF NOT EXISTS idx_grocery_template_items_template_id ON grocery_template_items(template_id);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_task_id ON grocery_lists(task_id);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_family_id ON grocery_lists(family_id);
CREATE INDEX IF NOT EXISTS idx_grocery_list_items_list_id ON grocery_list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_grocery_list_items_checked ON grocery_list_items(checked);

-- Verify tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('grocery_templates', 'grocery_template_items', 'grocery_lists', 'grocery_list_items')
ORDER BY table_name;


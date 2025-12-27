# Complete Database Migration Checklist

This guide lists **all SQL migrations** you should run for the MyFamily app, in the recommended order.

## ✅ Priority 1: Core Tables (Required for Basic Functionality)

### 1. Base Schema Setup
**File:** `SUPABASE_SETUP.md` (Step 3) or `complete_schema_fix.sql`

Run the base schema first - this creates:
- `users` table
- `families` table  
- `family_members` table
- `tasks` table
- Basic RLS policies

**Status:** ⚠️ Check if you already have these tables

---

### 2. Tasks Table Enhancements
**File:** `add_task_category_columns.sql`

Adds `category` and `category_data` columns to tasks table (needed for grocery tasks, recurring tasks, etc.)

**Run this if:** You have an existing `tasks` table without these columns

---

### 3. Grocery Tables
**File:** `create_grocery_tables.sql`

Creates:
- `grocery_templates` table
- `grocery_template_items` table
- `grocery_lists` table
- `grocery_list_items` table

**Run this if:** You want to use the Shopping/Grocery features

---

## ✅ Priority 2: New Features (Recently Implemented)

### 4. Points History Table
**File:** `create_points_history_table.sql` ✅ **FIXED VERSION**

Creates `points_history` table to track all points transactions.

**Status:** ✅ **You already tried this - use the FIXED version with corrected RLS policies**

---

### 5. Task Templates Table
**File:** `create_task_templates_table.sql` ✅ **FIXED VERSION**

Creates `task_templates` table for reusable task configurations.

**Status:** ✅ **Use the FIXED version with corrected RLS policies**

---

### 6. Achievements Table
**File:** `create_achievements_table.sql` (see SQL below)

Creates `achievements` table for the achievement badges feature.

**SQL:**
```sql
-- Create achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL, -- e.g., 'first_task', 'streak_starter', etc.
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, family_id, achievement_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_family_id ON achievements(family_id);
CREATE INDEX IF NOT EXISTS idx_achievements_achievement_id ON achievements(achievement_id);

-- Enable RLS
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (using family_members table)
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

-- Grant permissions
GRANT ALL ON achievements TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
```

---

## ✅ Priority 3: Additional Enhancements

### 7. Family Members Points Column
**File:** `add_family_members_points_column.sql`

Adds `points` column to `family_members` table for tracking individual member points.

**Run this if:** You want to track points per family member

---

### 8. Calendar Event Enhancements
**File:** `add_calendar_event_columns.sql`

Adds additional columns to `calendar_events` table if needed.

**Run this if:** You have calendar events and need extra fields

---

### 9. Families Table Enhancements
**File:** `quick_families_fix.sql` or `complete_schema_fix.sql`

Adds missing columns to `families` table:
- `address`
- `invite_code`
- `invite_link`
- `theme_preference`
- `total_points`

**Run this if:** Your `families` table is missing these columns

---

### 10. Users Table Enhancements
**File:** `complete_schema_fix.sql`

Adds missing columns to `users` table:
- `families` (TEXT array)
- `total_points`
- `theme_preference`
- `notifications_enabled`
- `deleted_at`

**Run this if:** Your `users` table is missing these columns

---

## ⚠️ Optional: Utility Scripts

### 11. Make Grocery Lists Standalone
**File:** `make_grocery_lists_standalone.sql`

Modifies grocery lists to support standalone lists (not just task-linked).

**Run this if:** You need standalone grocery lists

---

### 12. Consent Content Table
**File:** `create_consent_content_table.sql`

Creates table for storing consent/terms content.

**Run this if:** You use the consent feature

---

### 13. Storage Buckets Setup
**File:** `setup_storage_buckets.sql`

Sets up Supabase Storage buckets for file uploads.

**Run this if:** You need file/image uploads

---

## 📋 Recommended Migration Order

1. ✅ **Base Schema** (`SUPABASE_SETUP.md` or `complete_schema_fix.sql`)
2. ✅ **Task Category Columns** (`add_task_category_columns.sql`)
3. ✅ **Grocery Tables** (`create_grocery_tables.sql`)
4. ✅ **Points History** (`create_points_history_table.sql`) - **FIXED VERSION**
5. ✅ **Task Templates** (`create_task_templates_table.sql`) - **FIXED VERSION**
6. ✅ **Achievements** (SQL provided above)
7. ✅ **Family Members Points** (`add_family_members_points_column.sql`)
8. ✅ **Families Enhancements** (`quick_families_fix.sql`)
9. ✅ **Users Enhancements** (part of `complete_schema_fix.sql`)

---

## 🔍 How to Check What You Already Have

Run this query in Supabase SQL Editor to see all your tables:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

---

## ✅ Quick Verification

After running migrations, verify with:

```sql
-- Check if key tables exist
SELECT 
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'points_history') 
    THEN '✅' ELSE '❌' END as points_history,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'task_templates') 
    THEN '✅' ELSE '❌' END as task_templates,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'achievements') 
    THEN '✅' ELSE '❌' END as achievements,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grocery_lists') 
    THEN '✅' ELSE '❌' END as grocery_lists;
```

---

## 🚨 Important Notes

1. **RLS Policies:** All recent migrations use `family_members` table instead of `families.members` array to avoid UUID/TEXT type mismatches.

2. **Idempotent:** Most migrations use `CREATE TABLE IF NOT EXISTS` and `ADD COLUMN IF NOT EXISTS`, so they're safe to run multiple times.

3. **Dependencies:** Make sure base tables (`families`, `users`, `family_members`) exist before running feature-specific migrations.

4. **Test After Each Migration:** Run a simple query after each migration to verify it worked.

---

## Need Help?

If you encounter errors:
1. Check the error message - it usually tells you what's missing
2. Verify parent tables exist before running child table migrations
3. Check RLS policies are enabled and correct
4. Ensure you're running SQL as a database admin


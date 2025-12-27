-- ============================================================================
-- AUDIT & FIX RLS POLICIES FOR FEATURE TABLES
-- ============================================================================
-- This script adds missing RLS policies for Rewards, Meal Plans, Recipes, 
-- and Consent Content tables identified during the codebase audit.
-- ============================================================================

-- ============================================================================
-- 1. CONSENT CONTENT (Global / System Table)
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consent_content') THEN
    ALTER TABLE consent_content ENABLE ROW LEVEL SECURITY;

    -- Authenticated users can view consent content
    DROP POLICY IF EXISTS "consent_content_select_auth" ON consent_content;
    CREATE POLICY "consent_content_select_auth"
      ON consent_content FOR SELECT
      USING (auth.role() = 'authenticated');

    -- Insert/Update restricted to service role (no policy for users)
  END IF;
END $$;

-- ============================================================================
-- 2. REWARDS & REDEMPTIONS
-- ============================================================================

-- REWARDS TABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rewards') THEN
    ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

    -- Family members can view rewards
    DROP POLICY IF EXISTS "rewards_select_family" ON rewards;
    CREATE POLICY "rewards_select_family"
      ON rewards FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = rewards.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Parents/Admins can insert rewards
    DROP POLICY IF EXISTS "rewards_insert_parent" ON rewards;
    CREATE POLICY "rewards_insert_parent"
      ON rewards FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = rewards.family_id
          AND family_members.user_id = auth.uid()
          AND family_members.role IN ('admin', 'parent')
        )
      );

    -- Parents/Admins can update rewards
    DROP POLICY IF EXISTS "rewards_update_parent" ON rewards;
    CREATE POLICY "rewards_update_parent"
      ON rewards FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = rewards.family_id
          AND family_members.user_id = auth.uid()
          AND family_members.role IN ('admin', 'parent')
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = rewards.family_id
          AND family_members.user_id = auth.uid()
          AND family_members.role IN ('admin', 'parent')
        )
      );

    -- Parents/Admins can delete rewards
    DROP POLICY IF EXISTS "rewards_delete_parent" ON rewards;
    CREATE POLICY "rewards_delete_parent"
      ON rewards FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = rewards.family_id
          AND family_members.user_id = auth.uid()
          AND family_members.role IN ('admin', 'parent')
        )
      );
  END IF;
END $$;

-- REDEMPTIONS TABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reward_redemptions') THEN
    ALTER TABLE reward_redemptions ENABLE ROW LEVEL SECURITY;

    -- Family members can view redemptions (or at least their own + admins view all)
    -- Simpler: Family members view all in family to see activity? Or restrictive?
    -- App code implies streaming all family redemptions for admin.
    DROP POLICY IF EXISTS "redemptions_select_family" ON reward_redemptions;
    CREATE POLICY "redemptions_select_family"
      ON reward_redemptions FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = reward_redemptions.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Users can create redemption requests (for themselves)
    DROP POLICY IF EXISTS "redemptions_insert_self" ON reward_redemptions;
    CREATE POLICY "redemptions_insert_self"
      ON reward_redemptions FOR INSERT
      WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = reward_redemptions.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Users can cancel their own pending redemptions? (Update)
    -- Parents can approve/reject (Update)
    DROP POLICY IF EXISTS "redemptions_update_policy" ON reward_redemptions;
    CREATE POLICY "redemptions_update_policy"
      ON reward_redemptions FOR UPDATE
      USING (
        -- User owns it OR is parent/admin
        user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = reward_redemptions.family_id
          AND family_members.user_id = auth.uid()
          AND family_members.role IN ('admin', 'parent')
        )
      );
  END IF;
END $$;

-- ============================================================================
-- 3. MEAL PLANS & RECIPES
-- ============================================================================

-- MEAL PLANS TABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'meal_plans') THEN
    ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;

    -- Family can view
    DROP POLICY IF EXISTS "meal_plans_select_family" ON meal_plans;
    CREATE POLICY "meal_plans_select_family"
      ON meal_plans FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = meal_plans.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can create (Any member)
    DROP POLICY IF EXISTS "meal_plans_insert_family" ON meal_plans;
    CREATE POLICY "meal_plans_insert_family"
      ON meal_plans FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = meal_plans.family_id
          AND family_members.user_id = auth.uid()
        )
      );
      
    -- Family can update
    DROP POLICY IF EXISTS "meal_plans_update_family" ON meal_plans;
    CREATE POLICY "meal_plans_update_family"
      ON meal_plans FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = meal_plans.family_id
          AND family_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- MEAL PLAN ENTRIES TABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'meal_plan_entries') THEN
    ALTER TABLE meal_plan_entries ENABLE ROW LEVEL SECURITY;

    -- Family can view (via join to meal_plans)
    DROP POLICY IF EXISTS "meal_entries_select_family" ON meal_plan_entries;
    CREATE POLICY "meal_entries_select_family"
      ON meal_plan_entries FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM meal_plans
          JOIN family_members ON family_members.family_id = meal_plans.family_id
          WHERE meal_plans.id = meal_plan_entries.plan_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can insert (via join check)
    DROP POLICY IF EXISTS "meal_entries_insert_family" ON meal_plan_entries;
    CREATE POLICY "meal_entries_insert_family"
      ON meal_plan_entries FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM meal_plans
          JOIN family_members ON family_members.family_id = meal_plans.family_id
          WHERE meal_plans.id = meal_plan_entries.plan_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can update
    DROP POLICY IF EXISTS "meal_entries_update_family" ON meal_plan_entries;
    CREATE POLICY "meal_entries_update_family"
      ON meal_plan_entries FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM meal_plans
          JOIN family_members ON family_members.family_id = meal_plans.family_id
          WHERE meal_plans.id = meal_plan_entries.plan_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can delete
    DROP POLICY IF EXISTS "meal_entries_delete_family" ON meal_plan_entries;
    CREATE POLICY "meal_entries_delete_family"
      ON meal_plan_entries FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM meal_plans
          JOIN family_members ON family_members.family_id = meal_plans.family_id
          WHERE meal_plans.id = meal_plan_entries.plan_id
          AND family_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- RECIPES TABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recipes') THEN
    ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

    -- Family can view
    DROP POLICY IF EXISTS "recipes_select_family" ON recipes;
    CREATE POLICY "recipes_select_family"
      ON recipes FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = recipes.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can insert
    DROP POLICY IF EXISTS "recipes_insert_family" ON recipes;
    CREATE POLICY "recipes_insert_family"
      ON recipes FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = recipes.family_id
          AND family_members.user_id = auth.uid()
        )
      );

    -- Family can update
    DROP POLICY IF EXISTS "recipes_update_family" ON recipes;
    CREATE POLICY "recipes_update_family"
      ON recipes FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = recipes.family_id
          AND family_members.user_id = auth.uid()
        )
      );
      
    -- Family can delete
    DROP POLICY IF EXISTS "recipes_delete_family" ON recipes;
    CREATE POLICY "recipes_delete_family"
      ON recipes FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM family_members
          WHERE family_members.family_id = recipes.family_id
          AND family_members.user_id = auth.uid()
        )
      );
  END IF;
END $$;

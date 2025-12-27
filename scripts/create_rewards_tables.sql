-- Create rewards table
CREATE TABLE IF NOT EXISTS public.rewards (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    created_by uuid NOT NULL REFERENCES auth.users(id),
    title text NOT NULL,
    description text,
    cost integer NOT NULL DEFAULT 0,
    icon text NOT NULL DEFAULT 'star',
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT rewards_pkey PRIMARY KEY (id)
);

-- Create reward_redemptions table
CREATE TABLE IF NOT EXISTS public.reward_redemptions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    reward_id uuid NOT NULL REFERENCES public.rewards(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id),
    cost_at_redemption integer NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'fulfilled', 'rejected')),
    redeemed_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT reward_redemptions_pkey PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rewards
-- Everyone in the family can view rewards
CREATE POLICY "Family members can view rewards" ON public.rewards
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = rewards.family_id
            AND family_members.user_id = auth.uid()
        )
    );

-- Only parents/admins can manage rewards
CREATE POLICY "Parents can insert rewards" ON public.rewards
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = rewards.family_id
            AND family_members.user_id = auth.uid()
            AND family_members.role IN ('parent', 'admin')
        )
    );

CREATE POLICY "Parents can update rewards" ON public.rewards
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = rewards.family_id
            AND family_members.user_id = auth.uid()
            AND family_members.role IN ('parent', 'admin')
        )
    );

CREATE POLICY "Parents can delete rewards" ON public.rewards
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = rewards.family_id
            AND family_members.user_id = auth.uid()
            AND family_members.role IN ('parent', 'admin')
        )
    );

-- RLS Policies for reward_redemptions
-- Everyone can view redemptions for their family (so parents can see requests, kids can see history)
CREATE POLICY "Family members can view redemptions" ON public.reward_redemptions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = reward_redemptions.family_id
            AND family_members.user_id = auth.uid()
        )
    );

-- Any family member can insert a redemption (request a reward)
CREATE POLICY "Family members can request rewards" ON public.reward_redemptions
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = reward_redemptions.family_id
            AND family_members.user_id = auth.uid()
        )
    );

-- Only parents can update status (approve/reject/fulfill)
-- Exception: Maybe user can cancel their own pending request? For now, let's just stick to parent updates.
CREATE POLICY "Parents can update redemptions" ON public.reward_redemptions
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.family_members
            WHERE family_members.family_id = reward_redemptions.family_id
            AND family_members.user_id = auth.uid()
            AND family_members.role IN ('parent', 'admin')
        )
    );

-- Grant permissions (if needed for authenticated role, though standard Supabase setup usually handles this via role grants)
GRANT ALL ON public.rewards TO postgres;
GRANT ALL ON public.rewards TO service_role;
GRANT ALL ON public.reward_redemptions TO postgres;
GRANT ALL ON public.reward_redemptions TO service_role;

-- Enable Realtime for rewards and redemptions
-- This ensures the app updates immediately when changes occur
alter publication supabase_realtime add table public.rewards;
alter publication supabase_realtime add table public.reward_redemptions;

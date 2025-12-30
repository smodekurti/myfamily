-- Ensure user_fcm_tokens table exists (Safe Migration)

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL,
    device_type TEXT, -- 'android', 'ios', 'web'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, token) -- Prevent duplicate tokens for same user
);

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policies (Safe creation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_fcm_tokens' AND policyname = 'Users can view their own tokens'
    ) THEN
        CREATE POLICY "Users can view their own tokens" ON user_fcm_tokens
            FOR SELECT USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_fcm_tokens' AND policyname = 'Users can insert their own tokens'
    ) THEN
        CREATE POLICY "Users can insert their own tokens" ON user_fcm_tokens
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_fcm_tokens' AND policyname = 'Users can update their own tokens'
    ) THEN
        CREATE POLICY "Users can update their own tokens" ON user_fcm_tokens
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_fcm_tokens' AND policyname = 'Users can delete their own tokens'
    ) THEN
        CREATE POLICY "Users can delete their own tokens" ON user_fcm_tokens
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END
$$;

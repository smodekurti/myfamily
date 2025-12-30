-- User Devices Table for Push Notifications

CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    fcm_token TEXT NOT NULL,
    platform TEXT, -- 'android', 'ios', 'web'
    last_seen_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, fcm_token) -- Prevent duplicate tokens for same user
);

-- Enable RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own devices" ON user_devices
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own devices" ON user_devices
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices" ON user_devices
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own devices" ON user_devices
    FOR DELETE
    USING (auth.uid() = user_id);

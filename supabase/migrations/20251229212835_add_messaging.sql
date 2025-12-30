-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_url TEXT,
    channel_id TEXT NOT NULL DEFAULT 'general',
    channel_type TEXT NOT NULL DEFAULT 'family', -- 'family', 'dm', 'task', 'event'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policies

-- Select: Members of the family can view messages
CREATE POLICY "Family members can view messages" ON messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM family_members
            WHERE family_members.user_id = auth.uid()
            AND family_members.family_id = messages.family_id
        )
    );

-- Insert: Members of the family can insert messages
CREATE POLICY "Family members can insert messages" ON messages
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM family_members
            WHERE family_members.user_id = auth.uid()
            AND family_members.family_id = messages.family_id
        )
        AND
        auth.uid() = sender_id -- Ensure sender matches authenticated user
    );

-- Update: Senders can update their own messages (optional, maybe restricted time window in future)
CREATE POLICY "Senders can update own messages" ON messages
    FOR UPDATE
    USING (auth.uid() = sender_id);

-- Delete: Senders or Family Admins can delete messages
-- For simplicity in Phase 1, only sender can delete
CREATE POLICY "Senders can delete own messages" ON messages
    FOR DELETE
    USING (auth.uid() = sender_id);

-- Create index for faster querying by family and channel
CREATE INDEX idx_messages_family_channel ON messages(family_id, channel_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Add to Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

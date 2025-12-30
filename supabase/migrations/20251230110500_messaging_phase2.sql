-- Update Messages Table Policies for DMs

DROP POLICY IF EXISTS "Family members can view messages" ON messages;
DROP POLICY IF EXISTS "Family members can insert messages" ON messages;

-- Unified View Policy
CREATE POLICY "Users can view messages" ON messages
    FOR SELECT
    USING (
        -- Family Chat: User is member of the family
        (channel_type = 'family' AND EXISTS (
            SELECT 1 FROM family_members
            WHERE family_members.user_id = auth.uid()
            AND family_members.family_id = messages.family_id
        ))
        OR
        -- DM: User ID is part of the channel_id string (dm_uid1_uid2)
        (channel_type = 'dm' AND strpos(channel_id, auth.uid()::text) > 0)
    );

-- Unified Insert Policy
CREATE POLICY "Users can insert messages" ON messages
    FOR INSERT
    WITH CHECK (
        -- Sender must be the auth user
        auth.uid() = sender_id
        AND
        (
            -- Family Chat: User is member of the family
            (channel_type = 'family' AND EXISTS (
                SELECT 1 FROM family_members
                WHERE family_members.user_id = auth.uid()
                AND family_members.family_id = messages.family_id
            ))
            OR
            -- DM: User ID is part of the channel_id
            (channel_type = 'dm' AND strpos(channel_id, auth.uid()::text) > 0)
        )
    );

-- Message Reactions Table
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(message_id, user_id, emoji) -- Prevent duplicate reactions of same type from same user
);

-- Enable RLS on Reactions
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- Reactions Policies
CREATE POLICY "Users can view reactions" ON message_reactions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM messages
            WHERE messages.id = message_reactions.message_id
            AND (
                -- Same visibility logic as messages
                (messages.channel_type = 'family' AND EXISTS (
                    SELECT 1 FROM family_members
                    WHERE family_members.user_id = auth.uid()
                    AND family_members.family_id = messages.family_id
                ))
                OR
                (messages.channel_type = 'dm' AND strpos(messages.channel_id, auth.uid()::text) > 0)
            )
        )
    );

CREATE POLICY "Users can toggle reactions" ON message_reactions
    FOR ALL
    USING (
        auth.uid() = user_id
    );

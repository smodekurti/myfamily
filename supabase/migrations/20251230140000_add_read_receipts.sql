-- Create message_reads table
CREATE TABLE IF NOT EXISTS message_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(message_id, user_id) -- Prevent duplicate reads
);

-- Enable RLS
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;

-- Policies for message_reads
CREATE POLICY "Users can view reads" ON message_reads
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM messages
            WHERE messages.id = message_reads.message_id
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

CREATE POLICY "Users can insert reads" ON message_reads
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
    );

-- Add tables to Realtime publication
-- message_reactions was created in previous migration but might not be in publication
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reads;

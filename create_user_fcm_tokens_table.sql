-- Create table to store FCM tokens for push notifications
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL UNIQUE,
  device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_token ON user_fcm_tokens(token);

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can view their own tokens
CREATE POLICY "Users can view their own FCM tokens" ON user_fcm_tokens
  FOR SELECT USING (user_id = auth.uid());

-- Users can insert their own tokens
CREATE POLICY "Users can insert their own FCM tokens" ON user_fcm_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Users can update their own tokens
CREATE POLICY "Users can update their own FCM tokens" ON user_fcm_tokens
  FOR UPDATE USING (user_id = auth.uid());

-- Users can delete their own tokens
CREATE POLICY "Users can delete their own FCM tokens" ON user_fcm_tokens
  FOR DELETE USING (user_id = auth.uid());

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at on row update
CREATE TRIGGER update_user_fcm_tokens_updated_at
  BEFORE UPDATE ON user_fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_user_fcm_tokens_updated_at();


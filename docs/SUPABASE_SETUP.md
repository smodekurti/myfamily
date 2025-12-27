# Supabase Setup Guide for MyFamily

## 🎉 Migration Complete!

Your app has been successfully migrated from Firebase to Supabase! This eliminates the iOS gRPC build issues.

## Prerequisites

1. Create a free Supabase account at [https://supabase.com](https://supabase.com)
2. Create a new project in Supabase dashboard

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy the following:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **Anon/Public Key** (starts with `eyJ...`)

## Step 2: Configure Your App

Update `lib/app/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // ... rest of the config
}
```

**OR** use environment variables:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Step 3: Set Up Database Schema

Run the following SQL in your Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  families TEXT[] DEFAULT '{}',
  total_points INTEGER DEFAULT 0,
  theme_preference TEXT DEFAULT 'system',
  notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Create families table
CREATE TABLE families (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create family_members table
CREATE TABLE family_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(family_id, user_id)
);

-- Create tasks table
CREATE TABLE tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES auth.users(id),
  created_by UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  due_date TIMESTAMPTZ,
  points INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Create groceries table
CREATE TABLE groceries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  category TEXT,
  notes TEXT,
  is_purchased BOOLEAN DEFAULT false,
  added_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create calendar_events table
CREATE TABLE calendar_events (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE groceries ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- RLS Policies for families table
CREATE POLICY "Users can view families they belong to"
  ON families FOR SELECT
  USING (id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can create families"
  ON families FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- RLS Policies for family_members table
CREATE POLICY "Users can view family members of their families"
  ON family_members FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

-- RLS Policies for tasks table
CREATE POLICY "Users can view tasks in their families"
  ON tasks FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can create tasks in their families"
  ON tasks FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

-- RLS Policies for groceries table
CREATE POLICY "Users can view groceries in their families"
  ON groceries FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can add groceries in their families"
  ON groceries FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

-- RLS Policies for calendar_events table
CREATE POLICY "Users can view calendar events in their families"
  ON calendar_events FOR SELECT
  USING (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can create calendar events in their families"
  ON calendar_events FOR INSERT
  WITH CHECK (family_id IN (
    SELECT family_id FROM family_members WHERE user_id = auth.uid()
  ));

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_families_updated_at BEFORE UPDATE ON families
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groceries_updated_at BEFORE UPDATE ON groceries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Step 4: Configure Authentication

### Email/Password
Already configured! No additional setup needed.

### Google Sign-In

1. Go to **Authentication** → **Providers** in Supabase dashboard
2. Enable **Google** provider
3. Add your OAuth credentials:
   - Get Client ID and Secret from [Google Cloud Console](https://console.cloud.google.com/)
   - Add redirect URL: `https://your-project.supabase.co/auth/v1/callback`

### Apple Sign-In

1. Go to **Authentication** → **Providers** in Supabase dashboard
2. Enable **Apple** provider
3. Add your Apple credentials from Apple Developer account
4. Add redirect URL: `https://your-project.supabase.co/auth/v1/callback`

## Step 5: Configure Deep Links (iOS)

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myfamily</string>
    </array>
  </dict>
</array>
```

## Step 6: Build and Run

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Benefits of Supabase Migration

✅ **No more iOS gRPC build issues!**
✅ **Google Sign-In now works without conflicts**
✅ **Simpler, cleaner dependencies**
✅ **PostgreSQL database with SQL queries**
✅ **Real-time subscriptions out of the box**
✅ **Built-in Row Level Security**
✅ **Auto-generated REST API**
✅ **Storage buckets for files**
✅ **Open source and self-hostable**

## Next Steps

1. Configure your Supabase credentials
2. Run the database schema SQL
3. Set up authentication providers
4. Build and test the app!

## Need Help?

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart)
- [Discord Community](https://discord.supabase.com/)


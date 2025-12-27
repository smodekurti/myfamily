# Quick Start - MyFamily with Supabase

## ✅ Migration Complete!

Your app has been successfully migrated from Firebase to Supabase!

---

## Immediate Next Steps

### 1. Create a Supabase Project (5 minutes)

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up/Sign in
3. Click "New Project"
4. Choose a name (e.g., "myfamily")
5. Set a strong database password
6. Select a region (closest to you)
7. Wait for project to be created (~2 minutes)

### 2. Get Your Credentials (1 minute)

1. Go to **Settings** → **API** in your Supabase dashboard
2. Copy:
   - **Project URL** (e.g., `https://abcdefgh.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### 3. Configure Your App (1 minute)

Open `lib/app/core/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

### 4. Set Up Database (3 minutes)

1. Go to **SQL Editor** in Supabase dashboard
2. Copy ALL the SQL from `SUPABASE_SETUP.md` (Step 3)
3. Paste and click **Run**
4. Verify tables are created in **Table Editor**

### 5. Run the App! (1 minute)

```bash
flutter run
```

That's it! Your app should now run without iOS build errors!

---

## Authentication Setup (Optional, but Recommended)

### Enable Google Sign-In

1. In Supabase dashboard: **Authentication** → **Providers**
2. Enable **Google**
3. Add your Google OAuth credentials
4. Add redirect URL: `https://YOUR_PROJECT_URL.supabase.co/auth/v1/callback`

### Enable Apple Sign-In

1. In Supabase dashboard: **Authentication** → **Providers**
2. Enable **Apple**
3. Add your Apple credentials
4. Add redirect URL: `https://YOUR_PROJECT_URL.supabase.co/auth/v1/callback`

---

## What Works Now?

✅ **Email/Password Authentication** - Works out of the box  
✅ **Google Sign-In** - After configuring in Supabase  
✅ **Apple Sign-In** - After configuring in Supabase  
✅ **iOS Builds** - No more gRPC errors!  
✅ **Clean Dependencies** - Only 16 iOS pods instead of 31  

---

## Troubleshooting

### App won't start?
- Check if you updated `supabase_config.dart` with real credentials

### "Table doesn't exist" error?
- Make sure you ran the SQL script in Supabase SQL Editor

### iOS build fails?
- Run: `cd ios && pod install && cd ..`
- Then: `flutter clean && flutter run`

### Google Sign-In not working?
- Configure it in Supabase dashboard
- Make sure `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) are present

---

## Key Benefits

🚀 **No iOS Build Issues** - Removed all problematic Firebase/gRPC dependencies  
⚡ **Faster Builds** - Fewer dependencies, cleaner code  
💾 **PostgreSQL** - More powerful than Firestore  
🔐 **Row Level Security** - Built-in data protection  
📊 **Better Queries** - Full SQL support with joins  
💰 **Better Pricing** - More generous free tier  
🌍 **Open Source** - Can self-host if needed  

---

## Documentation

- **Full Setup Guide:** `SUPABASE_SETUP.md`
- **Migration Details:** `MIGRATION_SUMMARY.md`
- **Supabase Docs:** [https://supabase.com/docs](https://supabase.com/docs)

---

**Total Setup Time:** ~10 minutes  
**Result:** Working app with no iOS build issues! 🎉


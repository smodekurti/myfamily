# 🔒 Security Notice: API Keys Removed from Git

## ⚠️ Important Security Information

Several files containing API keys and sensitive configuration have been removed from git tracking. These files should **NEVER** be committed to version control.

## Files Removed from Git

1. **`lib/firebase_options.dart`** - Contains Firebase API keys
2. **`android/app/google-services.json`** - Contains Firebase configuration
3. **`ios/Runner/GoogleService-Info.plist`** - Contains Firebase configuration
4. **`macos/Runner/GoogleService-Info.plist`** - Contains Firebase configuration
5. **`lib/app/core/config/supabase_config.dart`** - Contains Supabase URL and anon key

## ⚠️ Action Required: Rotate Your Keys

**Since these keys were previously committed to git, you should:**

1. **Rotate Firebase API Keys:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Navigate to Project Settings → General
   - Regenerate API keys for all platforms (Web, Android, iOS, macOS)
   - Update your local `firebase_options.dart` file with new keys

2. **Rotate Supabase Keys (if needed):**
   - Go to [Supabase Dashboard](https://supabase.com/dashboard)
   - Navigate to Settings → API
   - If you're concerned about exposure, regenerate the anon key
   - Update your local `supabase_config.dart` file

3. **Update All Team Members:**
   - Share the new keys securely (use a password manager or secure channel)
   - Ensure all team members update their local files

## Setting Up Local Development

### Step 1: Copy Example Files

```bash
# Copy example files to actual config files
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp lib/app/core/config/supabase_config.dart.example lib/app/core/config/supabase_config.dart
```

### Step 2: Fill in Your Keys

1. **Firebase Options:**
   - Run `flutterfire configure` to generate `firebase_options.dart`
   - Or manually fill in the values from Firebase Console

2. **Supabase Config:**
   - Get your Supabase URL and anon key from [Supabase Dashboard](https://supabase.com/dashboard/project/_/settings/api)
   - Update `supabase_config.dart` with your values

3. **Google Services Files:**
   - Download `google-services.json` from Firebase Console → Project Settings → Your apps
   - Place it in `android/app/google-services.json`
   - Download `GoogleService-Info.plist` for iOS
   - Place it in `ios/Runner/GoogleService-Info.plist`
   - Download `GoogleService-Info.plist` for macOS
   - Place it in `macos/Runner/GoogleService-Info.plist`

### Step 3: Verify .gitignore

Ensure these files are in `.gitignore`:

```
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
macos/Runner/GoogleService-Info.plist
lib/app/core/config/supabase_config.dart
```

## Best Practices Going Forward

1. **Never commit API keys** - Always use environment variables or secure storage
2. **Use example files** - Commit `.example` files instead of real config files
3. **Use secrets management** - For production, use services like:
   - Supabase Edge Functions Secrets
   - Firebase Remote Config
   - Environment variables
   - CI/CD secrets

## Removing from Git History

If you need to completely remove these files from git history (including all past commits), you'll need to use `git filter-branch` or BFG Repo-Cleaner. **Warning:** This rewrites git history and requires force push.

```bash
# Option 1: Using git filter-branch (slow but built-in)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/firebase_options.dart android/app/google-services.json ios/Runner/GoogleService-Info.plist macos/Runner/GoogleService-Info.plist lib/app/core/config/supabase_config.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Option 2: Using BFG Repo-Cleaner (faster, recommended)
# Download from https://rtyley.github.io/bfg-repo-cleaner/
bfg --delete-files firebase_options.dart
bfg --delete-files google-services.json
bfg --delete-files GoogleService-Info.plist
bfg --delete-files supabase_config.dart
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**After cleaning history, you'll need to force push:**
```bash
git push origin --force --all
git push origin --force --tags
```

⚠️ **Warning:** Force pushing rewrites history. Coordinate with your team before doing this!



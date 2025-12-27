# 🔄 Step-by-Step Guide: Rotate Exposed API Keys

This guide will walk you through rotating all API keys that were previously committed to git.

---

## 🔥 Part 1: Rotate Firebase API Keys

### Step 1.1: Access Firebase Console

1. Open your browser and go to: **https://console.firebase.google.com/**
2. Sign in with your Google account
3. Select your project: **`myfamily-d1388`** (or your project name)

### Step 1.2: Navigate to Project Settings

1. Click the **gear icon** (⚙️) next to "Project Overview" in the left sidebar
2. Select **"Project settings"**

### Step 1.3: View Current API Keys

1. You'll see a **"General"** tab (should be selected by default)
2. Scroll down to the **"Your apps"** section
3. You'll see cards for each platform:
   - 🌐 **Web app**
   - 🤖 **Android app**
   - 🍎 **iOS app**
   - 💻 **macOS app**

### Step 1.4: Regenerate API Keys

**⚠️ Important:** Firebase doesn't allow direct regeneration of API keys. Instead, you need to:

#### Option A: Restrict Current Keys (Recommended - Less Disruptive)

1. Go to **Google Cloud Console**: https://console.cloud.google.com/
2. Select your project: **`myfamily-d1388`**
3. Navigate to **"APIs & Services"** → **"Credentials"**
4. Find each API key (they start with `AIzaSy...`)
5. Click on each key to edit it
6. Under **"API restrictions"**, select **"Restrict key"**
7. Choose **"Restrict to specific APIs"**
8. Select only the APIs you need:
   - Firebase Installations API
   - Firebase Cloud Messaging API
   - Identity Toolkit API
   - Firebase Remote Config API
9. Click **"Save"**

#### Option B: Create New Keys and Update Apps (More Secure)

1. In **Firebase Console** → **Project Settings** → **General**
2. For each app platform:
   - Click the **"Add app"** button (or use existing app)
   - Download the new config file:
     - **Web**: Copy the config object
     - **Android**: Download `google-services.json`
     - **iOS**: Download `GoogleService-Info.plist`
     - **macOS**: Download `GoogleService-Info.plist`
3. **Note:** You'll need to update your app's configuration with the new keys

### Step 1.5: Update Local Firebase Configuration

1. **For Web, Android, iOS, macOS:**
   - Run this command in your project root:
   ```bash
   flutterfire configure
   ```
   - This will:
     - Detect your Firebase project
     - Generate a new `lib/firebase_options.dart` file
     - Update platform-specific config files

2. **Or manually update `lib/firebase_options.dart`:**
   - Copy the file from the example:
   ```bash
   cp lib/firebase_options.dart.example lib/firebase_options.dart
   ```
   - Open `lib/firebase_options.dart`
   - Replace all `YOUR_*` placeholders with values from Firebase Console

3. **Update platform-specific files:**
   - **Android**: Place `google-services.json` in `android/app/`
   - **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`
   - **macOS**: Place `GoogleService-Info.plist` in `macos/Runner/`

### Step 1.6: Verify Firebase Setup

1. Test the app:
   ```bash
   flutter run
   ```
2. Verify Firebase services work:
   - Push notifications
   - Authentication
   - Any other Firebase features

---

## 🗄️ Part 2: Rotate Supabase Keys (If Needed)

### Step 2.1: Access Supabase Dashboard

1. Go to: **https://supabase.com/dashboard**
2. Sign in with your account
3. Select your project: **`vovfhxnmiximhzdjadvu`** (or your project name)

### Step 2.2: Navigate to API Settings

1. Click **"Settings"** in the left sidebar
2. Click **"API"** in the settings menu

### Step 2.3: View Current Keys

You'll see:
- **Project URL**: `https://vovfhxnmiximhzdjadvu.supabase.co`
- **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **service_role key**: (hidden, only shown once)

### Step 2.4: Regenerate Anon Key (If Needed)

**⚠️ Important Decision:**

- **If you're NOT concerned about exposure**: The anon key is meant to be public (it's used in client-side code). However, if it was exposed, you may want to rotate it for security.

- **If you ARE concerned**: You should regenerate it.

#### To Regenerate:

1. Scroll down to the **"API Keys"** section
2. Find the **"anon public"** key
3. Click the **"Reset"** or **"Regenerate"** button (if available)
4. **⚠️ Warning**: This will invalidate the old key immediately
5. Copy the new key

### Step 2.5: Update Local Supabase Configuration

1. Copy the example file:
   ```bash
   cp lib/app/core/config/supabase_config.dart.example lib/app/core/config/supabase_config.dart
   ```

2. Open `lib/app/core/config/supabase_config.dart`

3. Update the values:
   ```dart
   static const String supabaseUrl = String.fromEnvironment(
     'SUPABASE_URL',
     defaultValue: 'https://vovfhxnmiximhzdjadvu.supabase.co', // Your actual URL
   );
   
   static const String supabaseAnonKey = String.fromEnvironment(
     'SUPABASE_ANON_KEY',
     defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // Your new anon key
   );
   ```

4. **Or use environment variables** (recommended for production):
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-new-key
   ```

### Step 2.6: Verify Supabase Connection

1. Test the app:
   ```bash
   flutter run
   ```
2. Verify Supabase features work:
   - Authentication
   - Database queries
   - Realtime subscriptions
   - Storage

---

## 👥 Part 3: Update Team Members

### Step 3.1: Share New Keys Securely

**⚠️ Never share keys via:**
- ❌ Email (unencrypted)
- ❌ Slack/Teams messages
- ❌ Git commits
- ❌ Public channels

**✅ Use secure methods:**
- ✅ Password manager (1Password, LastPass, Bitwarden)
- ✅ Encrypted messaging (Signal, Keybase)
- ✅ Secure file sharing (encrypted)
- ✅ In-person or secure video call

### Step 3.2: Create a Secure Key Document

Create a document with the following structure (store in password manager):

```
Firebase Project: myfamily-d1388
===============================
Web API Key: AIzaSy...
Android API Key: AIzaSy...
iOS API Key: AIzaSy...
macOS API Key: AIzaSy...

Supabase Project: vovfhxnmiximhzdjadvu
======================================
URL: https://vovfhxnmiximhzdjadvu.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkXVCJ9...
```

### Step 3.3: Share Instructions with Team

Send this message to your team:

```
🔒 SECURITY UPDATE: API Keys Rotated

We've rotated all API keys that were previously committed to git.

ACTION REQUIRED:
1. Pull the latest code: git pull
2. Copy example files:
   - cp lib/firebase_options.dart.example lib/firebase_options.dart
   - cp lib/app/core/config/supabase_config.dart.example lib/app/core/config/supabase_config.dart
3. Get new keys from [password manager/secure channel]
4. Update the files with new keys
5. Download platform config files:
   - android/app/google-services.json
   - ios/Runner/GoogleService-Info.plist
   - macos/Runner/GoogleService-Info.plist
6. Test the app: flutter run

Questions? Contact [your contact info]
```

### Step 3.4: Team Member Setup Checklist

Each team member should:

- [ ] Pull latest code: `git pull`
- [ ] Copy example files to actual config files
- [ ] Get new keys from secure source
- [ ] Update `lib/firebase_options.dart` with new Firebase keys
- [ ] Update `lib/app/core/config/supabase_config.dart` with new Supabase keys
- [ ] Download and place `google-services.json` in `android/app/`
- [ ] Download and place `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Download and place `GoogleService-Info.plist` in `macos/Runner/`
- [ ] Test the app: `flutter run`
- [ ] Verify all features work (auth, database, notifications)

---

## ✅ Verification Checklist

After completing all steps, verify:

### Firebase
- [ ] App builds successfully
- [ ] Authentication works (email/password, Google, Apple)
- [ ] Push notifications work
- [ ] Firebase services are accessible

### Supabase
- [ ] App connects to Supabase
- [ ] Authentication works
- [ ] Database queries work
- [ ] Realtime subscriptions work
- [ ] Storage uploads/downloads work

### Git
- [ ] Sensitive files are NOT tracked: `git status` should not show them
- [ ] `.gitignore` includes all sensitive files
- [ ] Example files are committed: `git status` should show `.example` files

---

## 🆘 Troubleshooting

### Issue: "Firebase app not initialized"
**Solution**: Make sure `lib/firebase_options.dart` exists and has correct keys

### Issue: "Supabase connection failed"
**Solution**: 
- Check `supabase_config.dart` has correct URL and key
- Verify Supabase project is active
- Check network connection

### Issue: "Google Sign-In failed"
**Solution**:
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Check OAuth client IDs match in Firebase Console

### Issue: "Build fails - missing config files"
**Solution**:
- Ensure all config files exist locally (even if not in git)
- Run `flutterfire configure` to regenerate

---

## 📝 Quick Reference Commands

```bash
# Copy example files
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp lib/app/core/config/supabase_config.dart.example lib/app/core/config/supabase_config.dart

# Or regenerate Firebase config
flutterfire configure

# Verify files are ignored
git status | grep -E "(firebase_options|google-services|GoogleService-Info|supabase_config)"

# Test the app
flutter clean
flutter pub get
flutter run
```

---

## 🔐 Security Best Practices Going Forward

1. **Never commit sensitive files** - They're in `.gitignore` now
2. **Use environment variables** for production builds
3. **Rotate keys periodically** (every 6-12 months)
4. **Monitor API usage** in Firebase/Supabase dashboards
5. **Use service accounts** for server-side operations
6. **Enable API key restrictions** in Google Cloud Console

---

## 📞 Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review `SECURITY_NOTICE.md` for additional context
3. Check Firebase/Supabase documentation
4. Contact your team lead or DevOps



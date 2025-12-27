# 🚀 START HERE: Key Rotation Process

## 📋 Overview

You need to rotate API keys that were exposed in git. Follow these steps in order.

---

## Step 1: Firebase API Keys (15-20 minutes)

### Quick Method (Recommended): Use FlutterFire CLI

1. **Open Terminal** in your project directory

2. **Run FlutterFire configure:**
   ```bash
   flutterfire configure
   ```
   
3. **Follow the prompts:**
   - Select your Firebase project: `myfamily-d1388`
   - Select platforms: Web, Android, iOS, macOS
   - It will automatically:
     - Generate new `lib/firebase_options.dart`
     - Download `google-services.json` for Android
     - Download `GoogleService-Info.plist` for iOS/macOS

4. **Verify files were created:**
   ```bash
   ls -la lib/firebase_options.dart
   ls -la android/app/google-services.json
   ls -la ios/Runner/GoogleService-Info.plist
   ls -la macos/Runner/GoogleService-Info.plist
   ```

5. **Test Firebase:**
   ```bash
   flutter run
   ```

### Alternative: Manual Method

If `flutterfire configure` doesn't work, see **ROTATE_KEYS_GUIDE.md** Part 1 for manual steps.

---

## Step 2: Supabase Keys (5 minutes)

### Option A: Keep Current Keys (Recommended)

The Supabase anon key is **meant to be public** (it's used in client-side code). If you're not concerned about exposure, you can keep the current keys.

**Just verify the file exists locally:**
```bash
ls -la lib/app/core/config/supabase_config.dart
```

If it doesn't exist, copy from example:
```bash
cp lib/app/core/config/supabase_config.dart.example lib/app/core/config/supabase_config.dart
# Then edit it with your actual keys
```

### Option B: Rotate Supabase Keys

1. **Go to Supabase Dashboard:**
   - https://supabase.com/dashboard/project/vovfhxnmiximhzdjadvu/settings/api

2. **Regenerate anon key:**
   - Scroll to "API Keys" section
   - Click "Reset" on the anon key
   - Copy the new key

3. **Update local file:**
   ```bash
   # Edit the file
   nano lib/app/core/config/supabase_config.dart
   # Or use your preferred editor
   ```
   
   Update the `defaultValue` for `supabaseAnonKey` with the new key.

4. **Test Supabase:**
   ```bash
   flutter run
   ```

---

## Step 3: Verify Everything Works

Run this checklist:

```bash
# 1. Check sensitive files are NOT in git
git status | grep -E "(firebase_options|google-services|GoogleService-Info|supabase_config)" 
# Should return nothing (files are ignored)

# 2. Check files exist locally
ls lib/firebase_options.dart
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist
ls lib/app/core/config/supabase_config.dart
# All should exist

# 3. Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Test these features:**
- [ ] App launches successfully
- [ ] Sign in with email/password works
- [ ] Google Sign-In works
- [ ] Apple Sign-In works (iOS)
- [ ] Database queries work
- [ ] Push notifications work (if applicable)

---

## Step 4: Share with Team

### Create Secure Key Document

Store these in a password manager (1Password, LastPass, etc.):

```
Firebase Project: myfamily-d1388
===============================
[Get keys from Firebase Console → Project Settings → General]

Supabase Project: vovfhxnmiximhzdjadvu
======================================
URL: https://vovfhxnmiximhzdjadvu.supabase.co
Anon Key: [Get from Supabase Dashboard → Settings → API]
```

### Send Team Message

```
🔒 SECURITY UPDATE: API Keys Rotated

We've rotated API keys that were previously in git.

ACTION REQUIRED:
1. Pull latest: git pull
2. Run: flutterfire configure
   OR manually copy example files and add keys
3. Test: flutter run

Get keys from: [password manager link]
```

---

## 🆘 Need Help?

- **Detailed guide:** See `ROTATE_KEYS_GUIDE.md`
- **Quick checklist:** See `QUICK_KEY_ROTATION.md`
- **Troubleshooting:** See `ROTATE_KEYS_GUIDE.md` troubleshooting section

---

## ✅ Completion Checklist

- [ ] Firebase keys rotated/restricted
- [ ] `lib/firebase_options.dart` updated
- [ ] `google-services.json` downloaded and placed
- [ ] `GoogleService-Info.plist` files downloaded and placed
- [ ] Supabase keys updated (if rotated)
- [ ] All features tested and working
- [ ] Keys shared securely with team
- [ ] Team members notified

---

## 🎯 Next Steps After Rotation

1. **Monitor API usage** in Firebase/Supabase dashboards
2. **Set up API key restrictions** in Google Cloud Console
3. **Consider using environment variables** for production builds
4. **Schedule periodic key rotation** (every 6-12 months)



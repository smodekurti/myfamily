# 📱 Bundle ID Update Guide

## New Bundle ID: `com.familyapp.ios`

Follow these steps in order to update your Bundle ID everywhere:

---

## Step 1: Update Xcode Project

1. **Open Xcode**:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Select Runner target** in the left sidebar

3. **Go to General tab**

4. **Change Bundle Identifier**:
   - Current: `com.example.myfamily`
   - New: `com.familyapp.ios` ✅

5. **Go to Signing & Capabilities tab**
   - Verify the Bundle Identifier updated
   - Sign in with Apple capability should still be there

6. **Save** (Cmd+S)

---

## Step 2: Update Google Cloud Console - iOS OAuth Client

1. **Go to Google Cloud Console**:
   - https://console.cloud.google.com/apis/credentials

2. **Find your iOS OAuth Client**:
   - Client ID: `667205355253-2m542escb9oc8rrjhaajhm537j1n8gh4.apps.googleusercontent.com`

3. **Click Edit** (pencil icon)

4. **Update Bundle ID**:
   - Current: `com.example.myfamily`
   - New: `com.familyapp.ios` ✅

5. **Click Save**

---

## Step 3: Verify Info.plist

Your `ios/Runner/Info.plist` should already be using the variable:
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

This means it will automatically use the new Bundle ID from Xcode.

**No changes needed here!** ✅

---

## Step 4: Clean and Rebuild

```bash
cd /Users/vasu.modekurti/Documents/AppDev/flutterApps/myfamily
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

---

## Step 5: Create App ID in Apple Developer Portal

Now you can create the App ID:

1. **Go to Apple Developer Portal**:
   - https://developer.apple.com/account/resources/identifiers/list

2. **Click + button**

3. **Select "App IDs"** → Continue

4. **Select "App"** → Continue

5. **Configure**:
   - **Description**: `MyFamily App`
   - **Bundle ID**: Select "Explicit"
   - **Bundle ID**: Enter `com.familyapp.ios` ✅
   - **Capabilities**: Check ✅ **Sign in with Apple**

6. **Click Continue** → **Register**

✅ **App ID Created!**

---

## Step 6: Create Services ID (for Supabase)

1. **In Identifiers**, click **+** again

2. **Select "Services IDs"** → Continue

3. **Configure**:
   - **Description**: `MyFamily Supabase Auth`
   - **Identifier**: `com.familyapp.ios.auth` ✅

4. **Enable "Sign in with Apple"**

5. **Click Configure**:
   - **Primary App ID**: Select `com.familyapp.ios` (the one you just created)
   - **Web Domain**: `vovfhxnmiximhzdjadvu.supabase.co`
   - **Return URLs**: `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback`

6. **Click Save** → **Continue** → **Register**

✅ **Services ID Created!**

---

## Step 7: Create Private Key

1. **Go to Keys** → Click **+**

2. **Configure**:
   - **Key Name**: `MyFamily Supabase Apple Auth Key`
   - Enable **Sign in with Apple**
   - Click **Configure** → Select `com.familyapp.ios`

3. **Click Continue** → **Register**

4. **Download the .p8 file** (you can only download once!)

5. **Note the Key ID** (e.g., `ABC123DEFG`)

✅ **Key Created!**

---

## Step 8: Configure Supabase Apple Provider

1. **Go to Supabase Dashboard**:
   - https://supabase.com/dashboard/project/vovfhxnmiximhzdjadvu/auth/providers

2. **Click on "Apple" provider**

3. **Enable Apple**

4. **Configure**:
   - **Services ID**: `com.familyapp.ios.auth` ✅
   - **Apple Key ID**: Your Key ID from Step 7
   - **Apple Team ID**: Your Team ID (found in Apple Developer Portal - Membership)
   - **Apple Private Key**: Paste entire contents of .p8 file

5. **Click Save**

✅ **Supabase Configured!**

---

## Step 9: Test Everything

### Test Google Sign-In:
```bash
flutter run
```
- Tap "Sign in with Google"
- Should work normally ✅

### Test Apple Sign-In:
- Must use **physical iOS device** (not simulator)
- Tap "Sign in with Apple"
- Should show Face ID / Touch ID
- Complete sign-in ✅

---

## Summary of Changes

| Item | Old Value | New Value |
|------|-----------|-----------|
| Bundle ID | `com.example.myfamily` | `com.familyapp.ios` ✅ |
| iOS OAuth Client Bundle ID | `com.example.myfamily` | `com.familyapp.ios` ✅ |
| Apple App ID | ❌ Didn't exist | `com.familyapp.ios` ✅ |
| Apple Services ID | ❌ Didn't exist | `com.familyapp.ios.auth` ✅ |

---

## Checklist

- [ ] Step 1: Update Xcode Bundle Identifier
- [ ] Step 2: Update Google Cloud Console iOS OAuth Client
- [ ] Step 3: Verify Info.plist (should be automatic)
- [ ] Step 4: Clean and rebuild
- [ ] Step 5: Create App ID in Apple Developer Portal
- [ ] Step 6: Create Services ID in Apple Developer Portal
- [ ] Step 7: Create and download .p8 Private Key
- [ ] Step 8: Configure Supabase Apple Provider
- [ ] Step 9: Test Google Sign-In
- [ ] Step 9: Test Apple Sign-In (physical device)

---

## Need Help?

If you encounter any issues:
1. Verify Bundle ID matches everywhere
2. Check Google OAuth Client is updated
3. Ensure App ID and Services ID are created
4. Verify Supabase configuration is correct

**You're all set to complete the Apple Sign-In setup!** 🎉


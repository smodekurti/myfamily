# Fixing iOS Push Notifications (Android → iOS Not Working)

## Problem
Push notifications work from **Apple device → Android** but **NOT from Android → Apple device**.

This is almost always an **APNs (Apple Push Notification service) configuration issue**.

---

## Root Cause

iOS push notifications require:
1. ✅ **APNs certificate/key uploaded to Firebase Console** (MOST COMMON ISSUE)
2. ✅ **Push Notifications capability enabled in Xcode**
3. ✅ **Proper FCM message format for iOS**

---

## Solution: Step-by-Step Fix

### Step 1: Verify Xcode Capabilities ✅

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Verify you have:
   - ✅ **Push Notifications** capability (should show a checkmark)
   - ✅ **Background Modes** capability with **Remote notifications** enabled

If missing:
- Click **+ Capability**
- Add **Push Notifications**
- Add **Background Modes** → Check **Remote notifications**

### Step 2: Upload APNs Key to Firebase Console 🔑 (REQUIRED)

This is the **most common cause** of iOS push notification failures.

#### Option A: APNs Authentication Key (Recommended - Works for both Development and Production)

1. **Get APNs Key from Apple Developer:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Click **+** to create a new key
   - Check **Apple Push Notifications service (APNs)**
   - Click **Continue** → **Register**
   - **Download the .p8 file** (you can only download it once!)
   - Note the **Key ID** (e.g., `ABC123XYZ`)

2. **Upload to Firebase:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to **Project Settings** (gear icon) → **Cloud Messaging** tab
   - Scroll to **Apple app configuration**
   - Under **APNs Authentication Key**, click **Upload**
   - Upload the `.p8` file
   - Enter the **Key ID** (from step 1)
   - Enter your **Team ID** (found in Apple Developer Portal → Membership)
   - Click **Upload**

#### Option B: APNs Certificate (Alternative)

1. **Create APNs Certificate:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
   - Click **+** to create new certificate
   - Select **Apple Push Notification service SSL (Sandbox & Production)**
   - Select your App ID
   - Follow the wizard to create and download the certificate
   - Double-click to install in Keychain
   - Export as `.p12` file

2. **Upload to Firebase:**
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Under **Apple app configuration**, click **Upload** next to **APNs Certificate**
   - Upload the `.p12` file
   - Enter the certificate password

### Step 3: Verify Bundle ID Matches

1. **Check your iOS Bundle ID:**
   - In Xcode → Runner target → General tab
   - Note the **Bundle Identifier** (e.g., `com.familyapp.ios`)

2. **Verify in Firebase:**
   - Firebase Console → Project Settings → General
   - Under **Your apps**, find your iOS app
   - Verify the Bundle ID matches

### Step 4: Test Again

1. **Rebuild the iOS app:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

2. **Test push notification:**
   - From Android device, create a task and assign to iOS user
   - iOS device should receive the notification

---

## Troubleshooting

### Check Firebase Console

1. Go to Firebase Console → Project Settings → Cloud Messaging
2. Under **Apple app configuration**, verify:
   - ✅ APNs Authentication Key is uploaded (shows Key ID)
   - OR
   - ✅ APNs Certificate is uploaded (shows certificate info)

### Check Edge Function Logs

1. Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
2. Look for iOS-specific errors:
   - `INVALID_ARGUMENT` - APNs not configured
   - `UNREGISTERED` - Token is invalid
   - `PERMISSION_DENIED` - APNs key/certificate issue

### Check FCM Token Registration

1. In Supabase Dashboard → Table Editor → `user_fcm_tokens`
2. Verify iOS device has a token with `device_type = 'ios'`
3. If missing, the iOS app needs to:
   - Request notification permissions
   - Get FCM token
   - Save to database

### Common Errors

#### Error: "APNs certificate/key not found"
- **Fix:** Upload APNs key or certificate to Firebase Console

#### Error: "Invalid APNs credentials"
- **Fix:** Verify the key/certificate is correct and matches your Bundle ID

#### Error: "Token not registered"
- **Fix:** Reinstall the iOS app to get a new FCM token

#### Error: "Permission denied"
- **Fix:** Check that Push Notifications capability is enabled in Xcode

---

## Verification Checklist

- [ ] Push Notifications capability added in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] APNs Authentication Key OR Certificate uploaded to Firebase
- [ ] Bundle ID matches in Xcode and Firebase
- [ ] iOS app rebuilt and reinstalled
- [ ] FCM token exists in `user_fcm_tokens` table for iOS device
- [ ] Test notification sent from Android to iOS

---

## Still Not Working?

1. **Check Supabase Edge Function logs** for specific error messages
2. **Check Firebase Console** → Cloud Messaging → Delivery reports
3. **Verify FCM token** is being saved correctly for iOS device
4. **Test with Firebase Console** directly:
   - Firebase Console → Cloud Messaging → Send test message
   - Enter the iOS device's FCM token
   - If this works, the issue is in the Edge Function
   - If this fails, the issue is APNs configuration

---

## Quick Test

To verify APNs is configured correctly:

1. Go to Firebase Console → Cloud Messaging
2. Click **Send test message**
3. Enter your iOS device's FCM token (from `user_fcm_tokens` table)
4. Send the message
5. If you receive it → APNs is configured correctly ✅
6. If you don't → APNs needs to be configured ❌

---

## Summary

**Most likely fix:** Upload APNs Authentication Key to Firebase Console (Step 2, Option A)

This is a **one-time setup** that takes about 5 minutes. Once configured, iOS push notifications will work from any device (Android, iOS, web) to iOS devices.


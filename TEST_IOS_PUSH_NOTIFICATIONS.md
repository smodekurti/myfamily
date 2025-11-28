# Testing iOS Push Notifications

## Method 1: Check APNs Configuration Status

### Verify APNs is Configured in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Project Settings** (gear icon) → **Cloud Messaging** tab
4. Scroll to **Apple app configuration** section
5. Look for one of these:
   - ✅ **APNs Authentication Key** - Shows Key ID if configured
   - ✅ **APNs Certificates** - Shows certificate info if configured
   - ❌ **"Upload"** button - Means APNs is NOT configured yet

**If you see "Upload" button → APNs needs to be configured (see IOS_PUSH_NOTIFICATIONS_FIX.md)**

---

## Method 2: Test via Your App (Recommended)

This is the easiest way to test:

1. **Make sure both devices are logged in:**
   - Android device: User A
   - iOS device: User B

2. **Check FCM tokens are saved:**
   - Go to Supabase Dashboard → Table Editor → `user_fcm_tokens`
   - Verify both devices have entries:
     - Android: `device_type = 'android'`
     - iOS: `device_type = 'ios'`

3. **Send a test notification:**
   - From Android device: Create a task and assign it to User B (iOS user)
   - iOS device should receive the notification

4. **Check Edge Function logs:**
   - Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
   - Look for:
     - `📱 Sending iOS notification to token...` (iOS)
     - `🤖 Sending Android notification to token...` (Android)
     - Success/failure messages

---

## Method 3: Test via Supabase Edge Function Directly

You can test the Edge Function directly using curl or Postman:

### Get Your FCM Token

1. Run the iOS app
2. Check Supabase Dashboard → `user_fcm_tokens` table
3. Copy the `token` value for your iOS device

### Test via curl

```bash
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "YOUR_USER_ID",
    "title": "Test Notification",
    "body": "This is a test from curl",
    "data": {
      "type": "test",
      "action": "test_action"
    }
  }'
```

Replace:
- `YOUR_PROJECT_REF` - Your Supabase project reference
- `YOUR_ANON_KEY` - Your Supabase anon key (from Supabase Dashboard → Settings → API)
- `YOUR_USER_ID` - The user ID that has the iOS FCM token

---

## Method 4: Check Edge Function Logs for Errors

### Common iOS-Specific Errors

1. **"APNs certificate/key not found"**
   - **Fix:** Upload APNs key to Firebase Console

2. **"Invalid APNs credentials"**
   - **Fix:** Verify the key/certificate is correct

3. **"UNREGISTERED" for iOS tokens**
   - **Fix:** Reinstall the iOS app to get a new token

4. **"PERMISSION_DENIED"**
   - **Fix:** Check Push Notifications capability in Xcode

### How to Check Logs

1. Go to Supabase Dashboard → Edge Functions → `send-push-notification`
2. Click **Logs** tab
3. Look for recent invocations
4. Check for error messages related to iOS/APNs

---

## Method 5: Verify iOS App Configuration

### Check Xcode Capabilities

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Verify:
   - ✅ **Push Notifications** capability is added
   - ✅ **Background Modes** → **Remote notifications** is checked

### Check Info.plist

Verify `ios/Runner/Info.plist` has:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## Method 6: Check FCM Token Registration

### Verify Token is Saved

1. **In Supabase Dashboard:**
   - Table Editor → `user_fcm_tokens`
   - Filter by `device_type = 'ios'`
   - Verify there's a token for your iOS device

2. **In App Logs:**
   - Look for: `FCM Token obtained: ...`
   - Look for: `FCM token saved to database`

### If Token is Missing

1. **Reinstall the iOS app:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

2. **Grant notification permissions** when prompted

3. **Check logs** for token registration

---

## Quick Diagnostic Checklist

Run through this checklist to identify the issue:

- [ ] **APNs configured in Firebase?**
  - Firebase Console → Project Settings → Cloud Messaging
  - Check if APNs Authentication Key or Certificate is uploaded

- [ ] **Xcode capabilities enabled?**
  - Push Notifications capability added
  - Background Modes → Remote notifications enabled

- [ ] **FCM token registered?**
  - Check `user_fcm_tokens` table for iOS device
  - Token exists with `device_type = 'ios'`

- [ ] **Edge Function deployed?**
  - Run: `supabase functions deploy send-push-notification`

- [ ] **Test notification sent?**
  - From Android: Create task, assign to iOS user
  - Check Edge Function logs for success/failure

---

## Most Common Issue: APNs Not Configured

**If push notifications work Android → Android but NOT Android → iOS:**

99% of the time, this means **APNs is not configured in Firebase Console**.

### Fix:

1. **Get APNs Authentication Key:**
   - [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Create new key with **Apple Push Notifications service (APNs)** enabled
   - Download `.p8` file
   - Note the **Key ID**

2. **Upload to Firebase:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Under **Apple app configuration** → Click **Upload**
   - Upload `.p8` file
   - Enter **Key ID** and **Team ID**
   - Click **Upload**

3. **Test again** - Should work immediately!

---

## Still Not Working?

1. **Check Supabase Edge Function logs** for specific error messages
2. **Verify APNs key is uploaded** in Firebase Console
3. **Reinstall iOS app** to get fresh FCM token
4. **Check Xcode capabilities** are enabled
5. **Verify Bundle ID** matches in Xcode and Firebase

The Edge Function logs will show exactly what's wrong - look for iOS-specific error messages!


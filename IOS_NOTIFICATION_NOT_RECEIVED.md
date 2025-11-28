# iOS Push Notification Not Received - Diagnostic Guide

## The Issue

Supabase logs show: ✅ "Notification sent successfully"
But iOS device: ❌ No notification received

## Root Cause

**"Sent successfully" from FCM doesn't mean APNs is configured!**

FCM accepts the message and says "sent successfully", but if **APNs credentials aren't configured in Firebase**, FCM **cannot deliver** the message to the iOS device.

---

## Diagnostic Steps

### Step 1: Verify APNs is Configured in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. **Project Settings** (gear icon) → **Cloud Messaging** tab
4. Scroll to **Apple app configuration**
5. **What do you see?**

   **❌ If you see "Upload" button:**
   - APNs is **NOT configured**
   - This is why notifications aren't being received
   - **Fix:** Upload APNs Authentication Key (see `APNS_SETUP_OPTIONS.md`)

   **✅ If you see Key ID or Certificate info:**
   - APNs is configured
   - Move to Step 2

---

### Step 2: Check App Logs

Check if the app is receiving the message at all:

1. **Run the iOS app** (in foreground or background)
2. **Send a test notification** from Android
3. **Check Xcode console logs** for:
   - `Foreground message received: ...` (if app is open)
   - `Background message received: ...` (if app is in background)

**If you see these logs:**
- ✅ App is receiving the message
- Issue might be with notification display or permissions

**If you DON'T see these logs:**
- ❌ App is not receiving the message
- Most likely: APNs not configured (Step 1)

---

### Step 3: Check Notification Permissions

1. **On iOS device:** Settings → Your App → Notifications
2. **Verify:**
   - ✅ Allow Notifications is **ON**
   - ✅ Alert Style is set (Banners or Alerts)

**If permissions are denied:**
- Reinstall the app to get permission prompt again
- Or: Settings → Your App → Notifications → Enable

---

### Step 4: Verify FCM Token

1. **Check Supabase Dashboard:**
   - Table Editor → `user_fcm_tokens`
   - Filter by `device_type = 'ios'`
   - Verify token exists for your iOS device

2. **Check if token matches:**
   - The token in the database should match the token FCM is trying to send to
   - If token is old/invalid, reinstall the app

---

### Step 5: Test with App in Different States

#### Test 1: App in Foreground (Open)
- Open the app
- Send notification from Android
- **Expected:** Local notification should appear (handled by `_handleForegroundMessage`)
- **Check logs:** Should see `Foreground message received`

#### Test 2: App in Background (Minimized)
- Minimize the app (home button/swipe up)
- Send notification from Android
- **Expected:** Notification should appear in notification center
- **Check logs:** Should see `Background message received`

#### Test 3: App Terminated (Closed)
- Force close the app (swipe up in app switcher)
- Send notification from Android
- **Expected:** Notification should appear in notification center
- **Check logs:** Should see `Background message received` when app is opened

---

## Most Common Issue: APNs Not Configured

**If Supabase logs show "sent successfully" but iOS device doesn't receive:**

99% of the time, this means **APNs Authentication Key is not uploaded to Firebase**.

### Quick Fix:

1. **Get APNs Key:**
   - [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Create new key with **Apple Push Notifications service (APNs)**
   - Download `.p8` file
   - Note **Key ID**

2. **Upload to Firebase:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Under **Apple app configuration** → Click **Upload**
   - Upload `.p8` file
   - Enter **Key ID** and **Team ID**
   - Click **Upload**

3. **Test immediately:**
   - No need to redeploy Edge Function
   - Send notification from Android to iOS
   - Should work immediately! ✅

---

## Understanding "Sent Successfully"

When you see "Notification sent successfully" in Supabase logs:

✅ **What it means:**
- Edge Function successfully called FCM API
- FCM accepted the message
- FCM queued the message for delivery

❌ **What it DOESN'T mean:**
- Message was delivered to device
- APNs is configured
- Device will receive the notification

**FCM can say "sent successfully" even if APNs isn't configured!** FCM just accepts the message but can't deliver it without APNs credentials.

---

## Verification Checklist

Run through this checklist:

- [ ] **APNs configured in Firebase?**
  - Firebase Console → Project Settings → Cloud Messaging
  - Check if APNs Authentication Key is uploaded

- [ ] **Xcode capabilities enabled?**
  - Push Notifications capability added
  - Background Modes → Remote notifications enabled

- [ ] **Notification permissions granted?**
  - iOS Settings → Your App → Notifications → Enabled

- [ ] **FCM token registered?**
  - Check `user_fcm_tokens` table for iOS device
  - Token exists with `device_type = 'ios'`

- [ ] **App receiving messages?**
  - Check Xcode console for "Foreground message received" or "Background message received"

- [ ] **Edge Function deployed?**
  - Latest version with iOS-specific formatting deployed

---

## Still Not Working?

1. **Check Firebase Console → Cloud Messaging → Delivery reports**
   - This shows if FCM actually delivered to APNs
   - If you see errors here, it's an APNs configuration issue

2. **Check Xcode console logs** when sending notification
   - Look for any error messages
   - Look for "Foreground message received" or "Background message received"

3. **Reinstall iOS app**
   - Get fresh FCM token
   - Re-request notification permissions

4. **Verify Bundle ID matches**
   - Xcode → Runner target → General → Bundle Identifier
   - Firebase Console → Project Settings → Your apps → iOS app Bundle ID
   - Must match exactly

---

## Summary

**The app does NOT need to be running in background.** Push notifications work in all app states.

**If Supabase shows "sent successfully" but iOS doesn't receive:**
- Most likely: **APNs not configured in Firebase**
- Fix: Upload APNs Authentication Key to Firebase Console
- Time: ~5 minutes
- Result: Should work immediately after upload

The "sent successfully" message is misleading - it just means FCM accepted the message, not that it was delivered to the device.


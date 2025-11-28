# APNs Configured But iOS Notifications Not Working

## Status: ✅ APNs IS Configured

Your Firebase Console shows:
- ✅ Development APNs auth key (Key ID: `5232XYTT7Y`)
- ✅ Production APNs auth key (Key ID: `5232XYTT7Y`)
- ✅ Bundle IDs: `com.familyapp.ios` and `com.example.myfamily`

Since APNs is configured but notifications aren't being received, let's check other potential issues.

---

## Diagnostic Steps

### Step 1: Verify Bundle ID Matches

**Check your iOS app's Bundle ID:**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **General** tab
4. Check **Bundle Identifier**

**It should match one of these:**
- `com.familyapp.ios` ✅
- `com.example.myfamily` ✅

**If Bundle ID doesn't match:**
- Either update the Bundle ID in Xcode to match Firebase
- Or add the correct Bundle ID to Firebase Console

---

### Step 2: Verify Xcode Capabilities

**Check Push Notifications capability:**

1. In Xcode → **Runner** target → **Signing & Capabilities**
2. Verify you have:
   - ✅ **Push Notifications** capability (should show a checkmark)
   - ✅ **Background Modes** capability with **Remote notifications** checked

**If missing:**
- Click **+ Capability**
- Add **Push Notifications**
- Add **Background Modes** → Check **Remote notifications**

---

### Step 3: Check Provisioning Profile

**The provisioning profile must have Push Notifications enabled:**

1. In Xcode → **Runner** target → **Signing & Capabilities**
2. Check **Signing Certificate** and **Provisioning Profile**
3. The provisioning profile must be for the correct Bundle ID
4. It must have Push Notifications enabled

**If provisioning profile is wrong:**
- Xcode should automatically regenerate it
- Or download from Apple Developer Portal
- Make sure it's for the correct Bundle ID with Push Notifications enabled

---

### Step 4: Verify Notification Permissions

**Check if app has notification permissions:**

1. **On iOS device:** Settings → Your App → Notifications
2. **Verify:**
   - ✅ Allow Notifications is **ON**
   - ✅ Alert Style is set (Banners or Alerts)

**If permissions are denied:**
- Delete and reinstall the app
- Grant permissions when prompted

---

### Step 5: Check FCM Token

**Verify token is registered correctly:**

1. **Supabase Dashboard:**
   - Table Editor → `user_fcm_tokens`
   - Filter by `device_type = 'ios'`
   - Check the token for your iOS device

2. **Verify token matches:**
   - The token in database should be the current FCM token
   - If token is old, reinstall the app to get a new one

3. **Check app logs:**
   - Look for: `FCM Token obtained: ...`
   - Look for: `FCM token saved to database`

---

### Step 6: Test App in Different States

#### Test 1: App in Foreground
- Open the app
- Send notification from Android
- **Check Xcode console:** Should see `Foreground message received: ...`
- **Expected:** Local notification should appear

#### Test 2: App in Background
- Minimize the app
- Send notification from Android
- **Expected:** Notification should appear in notification center

#### Test 3: App Terminated
- Force close the app
- Send notification from Android
- **Expected:** Notification should appear in notification center

---

### Step 7: Check Firebase Console Delivery Reports

1. **Firebase Console** → **Cloud Messaging**
2. Look for **Delivery reports** or **Message history**
3. Check if messages show as:
   - ✅ **Delivered** - Message reached device
   - ❌ **Failed** - Check error message
   - ⚠️ **Pending** - Still being processed

**If you see errors:**
- Note the error message
- Common errors:
  - "Invalid token" - Token is expired/invalid
  - "APNs error" - APNs configuration issue
  - "Permission denied" - Notification permissions not granted

---

### Step 8: Verify APNs Key is for Correct Team

**Check Team ID matches:**

1. **Firebase Console** shows Team ID: `Y6ZC4C8VZS`
2. **Apple Developer Portal:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Check **Membership** → Your **Team ID**
   - Should match `Y6ZC4C8VZS`

**If Team ID doesn't match:**
- The APNs key might be for a different team
- Need to upload the correct APNs key for your team

---

### Step 9: Check Development vs Production

**Your Firebase shows both Development and Production keys:**

- **Development key:** For development/testing builds
- **Production key:** For App Store/TestFlight builds

**Which build are you testing?**

- **Development build (Xcode run):**
  - Should use Development APNs key ✅
  
- **Production build (TestFlight/App Store):**
  - Should use Production APNs key ✅

**If testing development build:**
- Make sure you're using a development provisioning profile
- The Development APNs key should work

**If testing production build:**
- Make sure you're using a production provisioning profile
- The Production APNs key should work

---

### Step 10: Check App Logs

**When sending a notification, check Xcode console for:**

1. **Foreground messages:**
   ```
   Foreground message received: [message_id]
   ```

2. **Background messages:**
   ```
   Background message received: [message_id]
   ```

3. **Any errors:**
   - APNs errors
   - Token errors
   - Permission errors

**If you see NO logs at all:**
- App is not receiving the message
- Likely: Token issue, Bundle ID mismatch, or provisioning profile issue

**If you see logs but no notification:**
- App is receiving the message
- Likely: Notification permissions or display issue

---

## Most Likely Issues (Since APNs is Configured)

### 1. Bundle ID Mismatch
- **Check:** Xcode Bundle ID vs Firebase Bundle ID
- **Fix:** Make sure they match exactly

### 2. Provisioning Profile Issue
- **Check:** Provisioning profile has Push Notifications enabled
- **Fix:** Regenerate provisioning profile in Xcode

### 3. Notification Permissions
- **Check:** iOS Settings → Your App → Notifications
- **Fix:** Enable notifications or reinstall app

### 4. Invalid/Expired FCM Token
- **Check:** Token in database matches current token
- **Fix:** Reinstall app to get fresh token

### 5. Development vs Production Key Mismatch
- **Check:** Using correct key for build type
- **Fix:** Make sure development builds use development key

---

## Quick Test

**Try this quick test:**

1. **Reinstall the iOS app** (to get fresh token and permissions)
2. **Grant notification permissions** when prompted
3. **Check Supabase:** Verify new FCM token is saved
4. **Send notification** from Android
5. **Check Xcode console** for any logs

**If still not working:**
- Check Bundle ID matches exactly
- Check provisioning profile has Push Notifications
- Check notification permissions are granted

---

## Next Steps

Since APNs is configured, the issue is likely:
1. ✅ Bundle ID mismatch
2. ✅ Provisioning profile
3. ✅ Notification permissions
4. ✅ Invalid FCM token

Start with Step 1 (Bundle ID) and work through the checklist. The most common issue when APNs is configured is a Bundle ID mismatch or provisioning profile issue.


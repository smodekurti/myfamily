# Push Notifications Troubleshooting Guide

## Issue: Notifications Not Received

If you see "Push notification sent" in logs but don't receive notifications, follow these steps:

## Step 1: Check FCM Token Registration

The most common issue is that the FCM token is not saved in the database.

### Check in Supabase:
1. Go to Supabase Dashboard → Table Editor → `user_fcm_tokens`
2. Verify your user ID has a token entry
3. Check the `device_type` matches your platform (android/ios)

### Check in App Logs:
Look for these log messages:
- ✅ `FCM Token obtained: ...` - Token was retrieved
- ✅ `FCM token saved to database` - Token was saved
- ❌ `No user logged in, cannot save FCM token` - User not logged in when token was obtained

### Fix: Manually Refresh Token
If no token is found:
1. Make sure you're logged in
2. Restart the app (this will re-initialize the push notification service)
3. Check logs for "FCM token saved to database"

## Step 2: Check Edge Function Response

The improved logging now shows detailed responses. Check your logs for:

### Good Response:
```
Push notification response: {sent: 1, failed: 0, total: 1}
Push notification sent to user: [userId] (sent: 1, failed: 0)
```

### No Tokens Found:
```
Push notification response: {message: "No FCM tokens found for users", sent: 0}
No FCM tokens found for user: [userId]. User may need to log in again...
```

### FCM Send Errors:
```
Push notification response: {sent: 0, failed: 1, total: 1}
Push notification failed for user: [userId] (sent: 0, failed: 1)
```

## Step 3: Check Supabase Edge Function Logs

1. Go to Supabase Dashboard → Edge Functions → `send-push-notification`
2. Click on "Logs" tab
3. Look for:
   - `Looking for FCM tokens for user IDs: [...]`
   - `Found X FCM tokens for Y user(s)`
   - `Sending notifications to X device(s)`
   - `✅ Notification sent successfully` or `❌ FCM send error`

### Common Edge Function Issues:

#### Issue: "No FCM tokens found"
- **Cause**: Token not saved in database
- **Fix**: See Step 1

#### Issue: "FCM send error" with 401/403
- **Cause**: Invalid OAuth token or Service Account credentials
- **Fix**: 
  1. Check `FCM_SERVICE_ACCOUNT_JSON` secret in Supabase
  2. Verify `FCM_PROJECT_ID` matches your Firebase project
  3. See `PUSH_NOTIFICATIONS_SETUP_V1.md`

#### Issue: "FCM send error" with 404
- **Cause**: Invalid FCM token (token expired or invalid)
- **Fix**: 
  1. Delete old tokens from `user_fcm_tokens` table
  2. Restart app to get new token
  3. Token will auto-refresh when it expires

## Step 4: Check Device-Specific Issues

### Android:
1. **Notification Permission**: Settings → Apps → MyFamily → Notifications → Enabled
2. **Battery Optimization**: Settings → Apps → MyFamily → Battery → Unrestricted
3. **Do Not Disturb**: Make sure DND is not blocking notifications
4. **Check Logs**: Look for "Android notification channels created"

### iOS:
1. **Notification Permission**: Settings → MyFamily → Notifications → Allow Notifications
2. **Background App Refresh**: Settings → MyFamily → Background App Refresh → ON
3. **Check APNs**: Verify APNs certificate/key is uploaded to Firebase
4. **Check Logs**: Look for iOS-specific errors

## Step 5: Test Notification Flow

### Test 1: Verify Token is Saved
1. Log in to the app
2. Check Supabase `user_fcm_tokens` table for your user ID
3. Should see at least one row with your token

### Test 2: Send Test Notification
1. Create a task and assign it to yourself
2. Check app logs for:
   ```
   Push notification response: {sent: 1, failed: 0}
   ```
3. Check Supabase Edge Function logs for success

### Test 3: Foreground vs Background
- **Foreground** (app open): Should show local notification
- **Background** (app minimized): Should show system notification
- **Killed** (app closed): Should show system notification

## Step 6: Common Fixes

### Fix 1: Token Not Saved After Login
**Problem**: Token obtained before user logged in

**Solution**: The service now listens to auth state changes and saves the token when user logs in. If still not working:
1. Log out and log back in
2. Or restart the app after logging in

### Fix 2: Old/Invalid Token
**Problem**: Token in database is expired

**Solution**:
1. Delete your token from `user_fcm_tokens` table
2. Restart the app
3. New token will be generated and saved

### Fix 3: Multiple Devices
**Problem**: Token saved for wrong device

**Solution**: 
- Each device has its own token
- Make sure you're checking the token for the correct device
- You can have multiple tokens per user (one per device)

## Step 7: Debug Commands

Add this to your code temporarily to debug:

```dart
// Check if token exists
final hasToken = await PushNotificationService().hasTokenInDatabase();
print('Has FCM token in database: $hasToken');

// Manually refresh token
await PushNotificationService().refreshToken();

// Get current token
final token = PushNotificationService().fcmToken;
print('Current FCM token: ${token?.substring(0, 20)}...');
```

## Summary Checklist

- [ ] FCM token exists in `user_fcm_tokens` table
- [ ] Edge Function logs show "Found X FCM tokens"
- [ ] Edge Function logs show "✅ Notification sent successfully"
- [ ] App logs show "sent: 1, failed: 0"
- [ ] Notification permissions granted
- [ ] Firebase Service Account configured
- [ ] APNs configured (iOS only)
- [ ] App is not in Do Not Disturb mode

## Still Not Working?

1. Check Supabase Edge Function logs for detailed error messages
2. Check Firebase Console → Cloud Messaging → Reports for delivery status
3. Verify all steps in `PUSH_NOTIFICATIONS_COMPLETE_CHECKLIST.md`
4. Check device-specific notification settings



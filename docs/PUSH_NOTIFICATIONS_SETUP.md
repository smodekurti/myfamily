# Push Notifications Setup Guide

This guide will help you set up push notifications for the MyFamily app using Supabase and Firebase Cloud Messaging (FCM).

## Overview

The app now uses **push notifications** for cross-device notifications (like task assignments) and **local notifications** for reminders (due dates, events).

---

## Step 1: Firebase Setup

### 1.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 1.2 Configure Firebase for Flutter

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `firebase_options.dart` file
- Configure Android and iOS apps

### 1.3 Create Firebase Project (if needed)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project" or select existing project
3. Follow the setup wizard
4. Then run `flutterfire configure` again

### 1.2 Add Android App to Firebase

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.yourcompany.myfamily` (check your `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 1.3 Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID (check your `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

### 1.4 Get Service Account Credentials (REQUIRED - Server Key is Deprecated)

**⚠️ Important:** Firebase has deprecated the Server Key. You must use Service Account credentials instead.

1. In Firebase Console, go to **Project Settings** → **Service accounts** tab
2. Click **"Generate new private key"**
3. Download the JSON file (keep it secure!)
4. You'll need to set this as a Supabase secret (see Step 3.5)

**See `PUSH_NOTIFICATIONS_SETUP_V1.md` for detailed instructions on the new FCM API v1 setup.**

---

## Step 2: Supabase Database Setup

### 2.1 Create FCM Tokens Table

Run this SQL in your Supabase SQL Editor:

```sql
-- See file: create_user_fcm_tokens_table.sql
```

Or copy the SQL from `create_user_fcm_tokens_table.sql` file.

---

## Step 3: Supabase Edge Function Setup

### 3.1 Install Supabase CLI

```bash
npm install -g supabase
```

### 3.2 Login to Supabase

```bash
supabase login
```

### 3.3 Link Your Project

```bash
supabase link --project-ref your-project-ref
```

### 3.4 Deploy Edge Function

The Edge Function is located in `supabase/functions/send-push-notification/`

Deploy it:

```bash
supabase functions deploy send-push-notification
```

### 3.5 Set Environment Variables

**⚠️ Server Key is Deprecated - Use Service Account Instead**

Set the Service Account JSON and Project ID:

```bash
# Set the entire service account JSON (from Step 1.4)
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<paste entire JSON file content>'

# Set the project ID (found in the JSON file's "project_id" field)
supabase secrets set FCM_PROJECT_ID='myfamily-d1388'
```

Or set it in Supabase Dashboard:
1. Go to **Project Settings** → **Edge Functions** → **Secrets**
2. Add secret: `FCM_SERVICE_ACCOUNT_JSON` = entire JSON file content
3. Add secret: `FCM_PROJECT_ID` = your Firebase project ID

**See `PUSH_NOTIFICATIONS_SETUP_V1.md` for complete instructions.**

---

## Step 4: Android Configuration

### 4.1 Update android/app/build.gradle

Ensure you have the Google Services plugin:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // Add this
}
```

### 4.2 Update android/build.gradle

Add Google Services classpath:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'  // Add this
    }
}
```

### 4.3 Update AndroidManifest.xml

The file should already have location permissions. Add notification channel (optional):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## Step 5: iOS Configuration

### 5.1 Update ios/Podfile

Ensure Firebase pods are included (they should be added automatically when you add `firebase_core` and `firebase_messaging`).

### 5.2 Update ios/Runner/Info.plist

Add notification permission description:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We need permission to send you notifications about tasks and events.</string>
```

### 5.3 Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** → Enable **Remote notifications**

### 5.4 Upload APNS Certificate to Firebase

1. In Firebase Console → Project Settings → Cloud Messaging
2. Upload your APNS certificate or key
3. For development, you can use the APNS Auth Key

---

## Step 6: Test Push Notifications

### 6.1 Run the App

```bash
flutter run
```

### 6.2 Check FCM Token

The app will automatically:
- Request notification permissions
- Get FCM token
- Save token to Supabase `user_fcm_tokens` table

### 6.3 Test Task Assignment

1. Create a task
2. Assign it to another family member
3. They should receive a push notification on their device

---

## How It Works

### Flow Diagram

```
1. User A creates task → assigns to User B
2. Task Repository calls PushNotificationService
3. PushNotificationService calls Supabase Edge Function
4. Edge Function gets User B's FCM token from database
5. Edge Function sends notification via FCM
6. User B receives notification on their device
```

### Notification Types

1. **Push Notifications** (via FCM):
   - Task assignments
   - Task reassignments
   - Cross-device notifications

2. **Local Notifications** (device-based):
   - Task due date reminders (1 hour before)
   - Event reminders (30 minutes before)
   - Scheduled on each user's device

---

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token**:
   - Verify token is saved in `user_fcm_tokens` table
   - Check logs for "FCM Token obtained"

2. **Check Firebase Setup**:
   - Ensure `google-services.json` is in `android/app/`
   - Ensure `GoogleService-Info.plist` is in `ios/Runner/`

3. **Check Supabase Edge Function**:
   - Verify function is deployed
   - Check function logs in Supabase Dashboard
   - Verify `FCM_SERVER_KEY` secret is set

4. **Check Permissions**:
   - Android: Settings → Apps → MyFamily → Notifications
   - iOS: Settings → MyFamily → Notifications

### Edge Function Errors

Check Supabase Dashboard → Edge Functions → Logs for errors.

Common issues:
- Missing `FCM_SERVER_KEY` secret
- Invalid FCM server key
- No FCM tokens found for user

### Android Build Errors

If you get Google Services errors:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## Security Notes

1. **FCM Server Key**: Keep this secret! Never commit it to git.
2. **RLS Policies**: The `user_fcm_tokens` table has RLS enabled - users can only see their own tokens.
3. **Edge Function**: Uses service role key (server-side only).

---

## Next Steps

- [ ] Set up Firebase project
- [ ] Add Android and iOS apps to Firebase
- [ ] Download and add configuration files
- [ ] Run database migration for FCM tokens table
- [ ] Deploy Supabase Edge Function
- [ ] Set FCM_SERVER_KEY secret
- [ ] Test push notifications

---

## Summary

✅ **Push notifications are now implemented!**

- Cross-device task assignment notifications
- Uses Supabase Edge Functions for server-side sending
- Uses FCM for reliable delivery
- Automatic token management
- Secure with RLS policies

The app will automatically request permissions and register for push notifications when users log in.


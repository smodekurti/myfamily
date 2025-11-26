# Push Notifications Complete Configuration Checklist

## ✅ Code Implementation Status

### Flutter/Dart Code
- ✅ Push notification service implemented
- ✅ FCM token registration
- ✅ Foreground message handling
- ✅ Background message handler
- ✅ Notification tap handling
- ✅ Token refresh handling
- ✅ Token storage in Supabase

### Android Configuration
- ✅ `google-services.json` present
- ✅ Google Services plugin in `build.gradle.kts`
- ✅ Firebase Core and Messaging dependencies
- ⚠️ **MISSING:** `POST_NOTIFICATIONS` permission (Android 13+)
- ⚠️ **MISSING:** Notification channel creation
- ⚠️ **MISSING:** Firebase initialization with `firebase_options.dart`

### iOS Configuration
- ✅ `GoogleService-Info.plist` present
- ✅ `UIBackgroundModes` with `remote-notification`
- ✅ `NSUserNotificationsUsageDescription` in Info.plist
- ⚠️ **MISSING:** Firebase initialization with `firebase_options.dart`
- ⚠️ **MISSING:** Push Notifications capability in Xcode (manual step)
- ⚠️ **MISSING:** APNs certificate/key in Firebase Console (manual step)

### Supabase Edge Function
- ✅ FCM API v1 implementation
- ✅ Service Account OAuth token handling
- ✅ Error handling
- ⚠️ **MISSING:** Secrets configuration (`FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID`)

---

## 🔧 Required Fixes

### 1. Android: Add POST_NOTIFICATIONS Permission

**File:** `android/app/src/main/AndroidManifest.xml`

Add this permission (required for Android 13+):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2. Android: Create Notification Channels

The code should create notification channels on Android. Currently, channels are referenced but not explicitly created.

### 3. Firebase Initialization: Use firebase_options.dart

**File:** `lib/main.dart`

Update Firebase initialization to use `firebase_options.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. iOS: Xcode Capabilities (Manual Step)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** → Enable **Remote notifications**

### 5. iOS: APNs Configuration (Manual Step)

In Firebase Console:
1. Go to **Project Settings** → **Cloud Messaging**
2. Under **Apple app configuration**, upload:
   - APNs Authentication Key (recommended), OR
   - APNs Certificate

### 6. Supabase: Set Secrets (Manual Step)

```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<entire JSON content>'
supabase secrets set FCM_PROJECT_ID='your-project-id'
```

---

## 📋 Complete Checklist

### Code Changes Needed
- [ ] Add `POST_NOTIFICATIONS` permission to AndroidManifest
- [ ] Update Firebase initialization to use `firebase_options.dart`
- [ ] Create Android notification channels explicitly
- [ ] Improve notification tap navigation handling

### Manual Steps Required
- [ ] Run `flutterfire configure` to generate/update `firebase_options.dart`
- [ ] Add Push Notifications capability in Xcode
- [ ] Upload APNs key/certificate to Firebase Console
- [ ] Deploy Supabase Edge Function
- [ ] Set Supabase secrets (`FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID`)
- [ ] Run database migration for `user_fcm_tokens` table

### Testing
- [ ] Test on Android device (Android 13+)
- [ ] Test on iOS device
- [ ] Test foreground notifications
- [ ] Test background notifications
- [ ] Test notification taps
- [ ] Test token refresh

---

## Current Status: ~75% Complete

**What's Working:**
- ✅ Core push notification service code
- ✅ FCM token management
- ✅ Supabase Edge Function (code ready)
- ✅ Basic Android/iOS configuration files

**What's Missing:**
- ⚠️ Android 13+ permission
- ⚠️ Firebase options initialization
- ⚠️ Manual Xcode configuration
- ⚠️ Manual Firebase Console APNs setup
- ⚠️ Supabase secrets configuration

Let me fix the code issues now!


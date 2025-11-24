# Firebase Bootstrap Guide

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Flutter SDK installed
- iOS Simulator or Android Emulator running

## Project Setup

### 1. Firebase Project Configuration
The Firebase project is already configured:
- **Project ID:** `myfamily-e897d`
- **Storage Bucket:** `myfamily-e897d.firebasestorage.app`

### 2. Configuration Files
The following files have been added to your project:
- `ios/Runner/GoogleService-Info.plist` (iOS)
- `android/app/google-services.json` (Android)

### 3. Firebase Services Setup

#### Authentication
```bash
# Enable Google Sign-In
firebase auth:enable google
firebase auth:enable apple
```

#### Firestore Database
```bash
# Create Firestore database
firebase firestore:databases:create --region=us-central1
```

#### Storage
```bash
# Enable Cloud Storage
firebase storage:enable
```

#### Functions
```bash
# Initialize Functions
firebase init functions
# Select TypeScript, ESLint, and install dependencies
```

#### App Check
```bash
# Enable App Check
firebase appcheck:enable
```

### 4. Security Rules Setup

#### Firestore Rules
Deploy the security rules:
```bash
firebase deploy --only firestore:rules
```

#### Storage Rules
Deploy the storage rules:
```bash
firebase deploy --only storage
```

### 5. Cloud Functions Deployment
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onTaskCompleted
```

### 6. Environment Setup

#### iOS Configuration
1. Open `ios/Runner.xcworkspace` in Xcode
2. Add GoogleService-Info.plist to Runner target
3. Enable Push Notifications capability
4. Add URL schemes for Google Sign-In

#### Android Configuration
1. Add SHA-1 fingerprints to Firebase Console
2. Enable Google Sign-In in Firebase Console
3. Configure OAuth consent screen

### 7. Testing Setup

#### Local Testing
```bash
# Start Firebase emulators
firebase emulators:start

# Run tests with emulators
flutter test --dart-define=USE_FIREBASE_EMULATOR=true
```

#### Production Testing
```bash
# Deploy to Firebase App Distribution
firebase appdistribution:distribute \
  --app YOUR_APP_ID \
  --groups "testers" \
  --file build/app/outputs/flutter-apk/app-release.apk
```

## Verification

### Check Firebase Connection
Run the app and verify:
1. Firebase initialization completes successfully
2. Authentication works with Google/Apple Sign-In
3. Firestore reads/writes function correctly
4. Push notifications are received

### Common Issues

#### iOS Build Issues
- Ensure GoogleService-Info.plist is added to Xcode project
- Check bundle ID matches Firebase configuration
- Verify URL schemes are configured

#### Android Build Issues
- Ensure google-services.json is in correct location
- Check package name matches Firebase configuration
- Verify SHA-1 fingerprints are added

#### Authentication Issues
- Check OAuth client configuration
- Verify redirect URLs are correct
- Ensure proper scopes are requested

## Next Steps
1. Set up analytics and crash reporting
2. Configure push notification topics
3. Set up A/B testing experiments
4. Configure performance monitoring

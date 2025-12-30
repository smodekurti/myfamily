# App Store & Play Store Submission Guide

This guide provides step-by-step instructions for preparing and submitting your Flutter app ("MyFamily") to the Apple App Store and Google Play Store.

## Prerequisites

Before beginning the submission process, ensure you have the following:

1.  **Apple Developer Account**: [Enroll here](https://developer.apple.com/programs/) ($99/year).
2.  **Google Play Console Account**: [Register here](https://play.google.com/console/signup) ($25 one-time fee).
3.  **App Assets**:
    *   **App Icon**: High-resolution (1024x1024) icon.
    *   **Screenshots**: For various device sizes (iPhone 6.5", 5.5", iPad, Android Phone, 7" Tablet, 10" Tablet).
    *   **Feature Graphic** (Android): 1024x500 px.
    *   **Privacy Policy URL**: Hosted link to your privacy policy.
    *   **Support URL**: Link to your support page or email.

> [!IMPORTANT]
> Ensure your `pubspec.yaml` version is correct (e.g., `1.0.0+1`) before building. Increment the build number (`+1`, `+2`) for each subsequent upload.

---

## 🍎 Apple App Store (iOS)

### 1. Configure Signing & Certificates

1.  Open **Xcode** (`ios/Runner.xcworkspace`).
2.  Select the **Runner** target in the left navigator.
3.  Go to the **Signing & Capabilities** tab.
4.  **Team**: Select your Apple Developer Team.
    *   If missing, go to **Xcode > Settings > Accounts** and add your Apple ID.
5.  **Bundle Identifier**: Ensure it is unique (configured as `com.smodekurti.myfamily`).
6.  **Signing Certificate**: Check "Automatically manage signing" for easiest setup.

### 2. Update Metadata

1.  **Display Name**: Check `ios/Runner/Info.plist` or the General tab in Xcode.
2.  **Version**: Handled by `pubspec.yaml`, but verify in General tab (`1.0.0`, Build `1`).

### 3. Create App in App Store Connect

1.  Login to [App Store Connect](https://appstoreconnect.apple.com/).
2.  Go to **My Apps** > **(+)** > **New App**.
3.  **Platforms**: iOS.
4.  **Name**: "MyFamily" (or your chosen store name).
5.  **Primary Language**: English (US).
6.  **Bundle ID**: Select the one matching your Xcode project.
7.  **SKU**: A unique ID for your internal use (e.g., `myfamily-flutter-001`).

### 4. Build & Archive

1.  In Xcode, select **Any iOS Device (arm64)** as the destination.
2.  Go to **Product** > **Archive**.
3.  Wait for the build to complete. The **Organizer** window will open.
4.  Select the latest archive and click **Distribute App**.
5.  Select **App Store Connect** > **Upload** > **Next**.
6.  Keep default options (Upload your app's symbols, Manage Version Number).
7.  Select your Distribution Certificate and Profile (Xcode usually manages this).
8.  Click **Upload**.

### 5. Submit for Review

1.  Once uploaded (processing can take 10-20 mins), go back to **App Store Connect**.
2.  Select the **TestFlight** tab to see the build. You can add internal testers here immediately.
3.  Go to the **App Store** tab > **1.0 Prepare for Submission**.
4.  **Build**: Select the build you just uploaded.
5.  **Screenshots**: Drag and drop your screenshots.
6.  **App Information**: Fill in description, keywords, support URL, privacy policy.
7.  **Copyright**: `2024 Your Name`.
8.  **Rating**: Complete the content rating questionnaire.
9.  Click **Submit for Review**.

---

## 🤖 Google Play Store (Android)

### 1. Generate Upload Keystore

1.  Run the following command in your terminal (macOS/Linux) to generate a keystore file:
    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
2.  Move `upload-keystore.jks` to `android/app/`.
3.  Create a file `android/key.properties` (DO NOT COMMIT THIS FILE):
    ```properties
    storePassword=<password_from_step_1>
    keyPassword=<password_from_step_1>
    keyAlias=upload
    storeFile=upload-keystore.jks
    ```
4.  Ensure `android/app/build.gradle` uses these properties in the `release` signing config (Flutter default template usually has this logic commented out or partially setup).

### 2. Configure Build Gradle

1.  Open `android/app/build.gradle`.
2.  Ensure `signingConfigs` for `release` reads from `key.properties`.
3.  Ensure `buildTypes` > `release` uses `signingConfig signingConfigs.release`.

### 3. Build App Bundle

Run the following command in your project root:

```bash
flutter build appbundle
```

The output file will be at: `build/app/outputs/bundle/release/app-release.aab`.

### 4. Create App in Google Play Console

1.  Login to [Google Play Console](https://play.google.com/console/).
2.  Click **Create app**.
3.  **App Name**: "MyFamily".
4.  **Default Language**: English (US).
5.  **App or Game**: App.
6.  **Free or Paid**: Free.
7.  Accept declarations using the checkboxes.
8.  Click **Create app**.

### 5. Setup Store Listing

1.  **Main Store Listing**: Upload app icon, feature graphic, phone screenshots, and tablet screenshots (required if you support users on tablets).
2.  **App Content**: Complete all questionnaires (Privacy Policy, Ads, App Access, Content Ratings, Target Audience, News Apps, COVID-19).

### 6. Upload & Release

1.  Go to **Testing** > **Internal testing** (recommended for first build).
2.  Click **Create new release**.
3.  **App Bundles**: Upload the `app-release.aab` file generated in Step 3.
4.  **Release Name**: `1.0.0` (or whatever you set in `pubspec.yaml`).
5.  **Release Notes**: "Initial release".
6.  Click **Next** > **Start rollout to Internal testing**.
7.  Add email lists for testers.

### 7. Promote to Production

1.  Once tested, go to **Production**.
2.  Create a new release (or promote from Internal/Closed testing).
3.  Review all details and click **Start rollout to Production**.

---

## ⚠️ Important Considerations

*   **Privacy Policy**: With Google Auth, FaceID, and Location features, your privacy policy must clearly state *why* you collect this data and how it is deleted.
*   **Google Sign-In**:
    *   **Android**: You must add the **SHA-1** fingerprint of your **Release Keystore** to your Firebase Project Settings (in the Firebase Console). Otherwise, Google Sign-In will fail on the Play Store version.
    *   **Supabase Config**: In "Authentication > Providers > Google", add your **Authorized Client IDs** (from `GoogleService-Info.plist` for iOS and `google-services.json` for Android). *Do NOT look for a "Bundle ID" field here; it does not exist for Google.*
*   **Apple Sign-In** (Required):
    1.  **Apple Dev Portal**: Create a **Key** with "Sign in with Apple" enabled. Download the `.p8` file.
    2.  **Supabase Config**: In "Authentication > Providers > Apple":
        *   **Services ID**: Enter your **Bundle ID** here (`com.smodekurti.myfamily`).
            *   *Note*: Do not create a new "Services ID" in the Apple Portal unless you have a website. For native iOS apps, the token is issued to your Bundle ID, so Supabase needs to verify against that.
        *   **Secret Key**: The contents of the `.p8` file you downloaded from Apple.
        *   **Key ID**: The 10-character Key ID associated with the `.p8` file.
        *   **Team ID**: Your Apple Team ID.
        *   **Bundle ID**: Enter `com.smodekurti.myfamily` again here (under "Main Bundle ID" or similar).
    3.  **Callback**: Not strictly required for native-only flow, but if asked, use `https://<your-project>.supabase.co/auth/v1/callback`.
*   **Apple Push Notifications** (Required for FCM on iOS):
    1.  **Apple Dev Portal**: Create a **Key** with "Apple Push Notifications service (APNs)" enabled. Download the `.p8` file.
    2.  **Firebase Console**: Go to Project Settings > Cloud Messaging > Apple app configuration.
    3.  **Upload Key**: Upload the `.p8` file. Enter your Key ID and Team ID.
    4.  **Xcode**:
        *   **Capabilities**: Add "Push Notifications".
        *   **Background Modes**: Enable "Remote notifications".

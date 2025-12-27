# 🍎 Apple Sign-In Setup Guide

## Prerequisites
- Apple Developer Account (paid membership required)
- Physical iOS device (Apple Sign-In doesn't work in simulator for production)

## Step 1: Configure in Apple Developer Portal

### 1.1 Enable Sign in with Apple for Your App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. Find or create your App ID: `com.example.myfamily`
4. Enable **Sign in with Apple** capability
5. Click **Save**

### 1.2 Create Services ID (for Supabase)

1. In **Identifiers**, click **+** to add new identifier
2. Select **Services IDs** → Continue
3. Configure:
   - **Description**: `MyFamily Supabase Auth`
   - **Identifier**: `com.example.myfamily.auth` (must be unique)
4. Enable **Sign in with Apple**
5. Click **Configure**:
   - **Primary App ID**: Select `com.example.myfamily`
   - **Web Domain**: `vovfhxnmiximhzdjadvu.supabase.co`
   - **Return URLs**: `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback`
6. Save and Continue

### 1.3 Create Private Key (for Supabase)

1. Navigate to **Keys** → Click **+**
2. Configure:
   - **Key Name**: `MyFamily Supabase Apple Auth Key`
   - Enable **Sign in with Apple**
   - Click **Configure** → Select your Primary App ID
3. Click **Continue** → **Register**
4. **Download the .p8 key file** (you can only download once!)
5. Note the **Key ID** (e.g., `ABC123DEFG`)

## Step 2: Configure in Xcode

### 2.1 Enable Sign in with Apple Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple**
6. Ensure your Team and Bundle Identifier are correct

## Step 3: Configure Supabase

### 3.1 Add Apple Provider

1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Find **Apple** provider → Click to expand
3. Enable **Apple**
4. Configure:
   - **Services ID**: `com.example.myfamily.auth` (from Step 1.2)
   - **Apple Key ID**: Your Key ID (from Step 1.3)
   - **Apple Team ID**: Your Team ID (found in Apple Developer Portal)
   - **Apple Private Key**: Paste contents of .p8 file (from Step 1.3)
5. Click **Save**

## Step 4: Test

### 4.1 Run on Physical Device

```bash
flutter run -d [your-device-id]
```

### 4.2 Test Flow

1. Tap **Sign in with Apple**
2. Face ID / Touch ID authentication
3. Choose to share or hide email
4. Sign in should complete successfully

## Current Code Status

Your `auth_repository.dart` already has Apple Sign-In implemented:

```dart
Future<AuthResponse?> signInWithApple() async {
  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: appleCredential.identityToken!,
    );

    if (response.user != null) {
      await _createOrUpdateUserProfile(response.user!);
    }

    return response;
  } catch (e) {
    _logger.e('Apple sign in error: $e');
    rethrow;
  }
}
```

✅ Code is ready - just needs Apple Developer Portal + Supabase configuration!

## Troubleshooting

### "The operation couldn't be completed"
- Ensure you're using a physical device (not simulator)
- Check that Sign in with Apple capability is enabled in Xcode
- Verify Services ID configuration in Apple Developer Portal

### "Invalid client"
- Check Services ID matches in Apple Developer Portal and Supabase
- Verify Web Domain and Return URLs are correct

### "Email not provided"
- Apple only provides email on first sign-in
- User can choose to hide email (use privaterelay email)
- Handle null email gracefully in your code

## Security Notes

- 🔒 Keep your .p8 private key secure (never commit to git)
- 🔒 Users can choose to hide their email (use proxy email)
- 🔒 Name is only provided on first sign-in
- 🔒 Apple requires annual review for apps using Sign in with Apple


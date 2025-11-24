# CRITICAL FIX: iOS OAuth "error=invalid"

## What's Happening

You're seeing `https://myfamily.app/?error=invalid` in Safari. This means:

1. ✅ Google auth started successfully
2. ✅ Google redirected to Supabase
3. ❌ Supabase returned an error
4. ❌ It's trying to redirect to the Site URL instead of your app
5. ❌ The deep link isn't catching it

## The Root Cause

The **iOS Client ID in your Info.plist might not match your actual Google OAuth iOS client.**

## IMMEDIATE FIX

### Step 1: Get Your REAL iOS Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Look for an OAuth 2.0 Client ID of type **iOS**
   - If you don't have one, create it:
     - Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
     - Select **iOS**
     - Bundle ID: `com.example.myfamily`
     - Create

4. Open the iOS client and find the **Client ID**
   - It will look like: `123456789-xxxxxxxxx.apps.googleusercontent.com`
   - Copy this ENTIRE Client ID

### Step 2: Update Info.plist with Correct Reversed Client ID

The URL scheme in Info.plist should be the **reversed** version of your iOS Client ID:

**Format**: `com.googleusercontent.apps.YOUR-IOS-CLIENT-ID`

**Example**: 
- If iOS Client ID is: `123456789-abc.apps.googleusercontent.com`
- Reversed scheme is: `com.googleusercontent.apps.123456789-abc`

**Currently your Info.plist has**:
```
com.googleusercontent.apps.879363886187-d4oh6t8c7lfsk4979cvkrduta08gk095
```

**Verify this matches your iOS OAuth client ID!**

If it doesn't match:
1. Get the correct iOS Client ID from Google Cloud Console
2. Reverse it to: `com.googleusercontent.apps.YOUR-IOS-CLIENT-ID`
3. Update Info.plist

### Step 3: Check Google Cloud Console OAuth Clients

You MUST have **BOTH** configured:

#### Web OAuth Client (for Supabase)
- **Authorized redirect URIs**:
  ```
  https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
  ```

#### iOS OAuth Client (for mobile app)
- **Bundle ID**: `com.example.myfamily`
- This enables Google to accept OAuth requests from your iOS app

### Step 4: Update Supabase Google Provider Settings

In Supabase Dashboard → **Authentication** → **Providers** → **Google**:

1. **Client ID**: Use the **Web** OAuth Client ID
2. **Client Secret**: Use the **Web** OAuth Client Secret
3. **Authorized Client IDs** (if the field exists): Add your **iOS** Client ID here
   - This tells Supabase to accept requests from the iOS client too
   - Format: `123456789-xxxxxxxxx.apps.googleusercontent.com`

### Step 5: Remove or Ignore Site URL Error

The `error=invalid` is likely because:
1. The iOS Client ID doesn't match
2. OR Supabase doesn't recognize your iOS client

Make sure the iOS Client ID is added to **Authorized Client IDs** in Supabase if that field is available.

### Step 6: Clean and Test

```bash
# Delete the app from your device/simulator
# Then:
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

---

## Verification Checklist

### Google Cloud Console:
- [ ] Web OAuth client exists with Supabase callback URL
- [ ] iOS OAuth client exists with bundle ID `com.example.myfamily`
- [ ] Note both Client IDs

### Supabase Dashboard:
- [ ] Google provider enabled
- [ ] Using Web client credentials (Client ID & Secret)
- [ ] iOS Client ID added to Authorized Client IDs (if field exists)
- [ ] Site URL set to `https://myfamily.app`

### Info.plist:
- [ ] Reversed iOS Client ID matches: `com.googleusercontent.apps.XXX`
- [ ] Also has `myfamily` scheme

### Code:
- [ ] NO `redirectTo` parameter in signInWithOAuth

---

## Debug: Check the Exact Error

Add logging to see what's happening:

```dart
// In auth_repository.dart
Future<AuthResponse?> signInWithGoogle() async {
  try {
    _logger.i('=== Starting Google OAuth ===');
    _logger.i('Supabase URL: ${_supabase.auth.currentSession}');
    
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    _logger.i('OAuth flow initiated successfully');
    return null;
  } catch (e, stack) {
    _logger.e('=== Google OAuth Error ===');
    _logger.e('Error: $e');
    _logger.e('Stack: $stack');
    rethrow;
  }
}
```

Also add an auth state listener to see when auth succeeds:

```dart
// In your auth provider or main.dart
_supabase.auth.onAuthStateChange.listen((AuthState state) {
  final session = state.session;
  if (session != null) {
    print('✅ Auth successful! User: ${session.user.email}');
  } else {
    print('❌ No session');
  }
});
```

---

## Alternative: Try Explicit redirectTo

If the above doesn't work, try explicitly setting the redirect:

```dart
import 'dart:io';

Future<AuthResponse?> signInWithGoogle() async {
  try {
    // Try explicit redirect for iOS
    final redirectUrl = 'io.supabase.flutterquickstart://login-callback';
    
    _logger.i('Using redirect: $redirectUrl');
    
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    return null;
  } catch (e) {
    _logger.e('Error: $e');
    rethrow;
  }
}
```

And add to Info.plist:

```xml
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <string>io.supabase.flutterquickstart</string>
    </array>
</dict>
```

---

## Most Likely Issue

**The iOS Client ID in Info.plist doesn't match the actual iOS OAuth client in Google Cloud Console.**

Double-check:
1. iOS OAuth client in Google Console
2. The Client ID it shows
3. Reverse it: `com.googleusercontent.apps.CLIENT-ID`
4. Verify it matches Info.plist

This is the #1 cause of "error=invalid" on iOS with Supabase + Google OAuth.


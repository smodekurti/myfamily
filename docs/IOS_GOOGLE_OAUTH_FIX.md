# iOS Google OAuth Fix - redirect_uri_mismatch

## The Problem
Getting `redirect_uri_mismatch` error specifically on iOS when trying to sign in with Google.

## iOS-Specific Solution

### Step 1: Google Cloud Console Configuration

You need to configure **TWO OAuth clients** in Google Cloud Console:

#### 1A. Web Application OAuth Client (Required)
1. Go to [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**
2. Find or create an OAuth 2.0 Client ID of type **Web application**
3. Add this redirect URI:
   ```
   https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
   ```
4. Copy the **Client ID** and **Client Secret** - you'll need these for Supabase

#### 1B. iOS OAuth Client (Also Required)
1. In the same Credentials page, create a **new** OAuth 2.0 Client ID
2. Select type: **iOS**
3. Fill in:
   - **Name**: MyFamily iOS
   - **Bundle ID**: `com.example.myfamily`
4. Click **Create**
5. You'll get an iOS Client ID like: `123456789-abcdefgh.apps.googleusercontent.com`

**IMPORTANT**: 
- The iOS client gives you a different Client ID
- But you'll use the **Web application** credentials in Supabase
- Having both configured allows Google to accept OAuth requests from iOS

### Step 2: Supabase Dashboard Configuration

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → Your Project
2. Navigate to **Authentication** → **Providers** → **Google**
3. Configure:
   - **Enabled**: ON
   - **Client ID**: Use the **Web application** Client ID (not the iOS one)
   - **Client Secret**: Use the **Web application** Client Secret
   - **Authorized Client IDs**: Leave empty or add the iOS Client ID here if available
4. Click **Save**

5. Go to **Authentication** → **URL Configuration**
6. Add to **Redirect URLs**:
   ```
   com.example.myfamily://auth-callback
   ```
   Also try adding:
   ```
   myfamily://auth-callback
   ```
7. Set **Site URL** to:
   ```
   https://myfamily.app
   ```
8. Click **Save**

### Step 3: Verify iOS Info.plist

Make sure your `ios/Runner/Info.plist` has BOTH URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Supabase Deep Link -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myfamily</string>
        </array>
    </dict>
    <!-- Google Sign-In -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.879363886187-d4oh6t8c7lfsk4979cvkrduta08gk095</string>
        </array>
    </dict>
</array>
```

### Step 4: Alternative Approach - Use Bundle ID Scheme

Try updating Supabase redirect URLs to use your bundle ID:

In Supabase Dashboard → **Authentication** → **URL Configuration** → **Redirect URLs**, add:
```
com.example.myfamily://auth-callback
```

And update your code to match:

```dart
// In auth_repository.dart, try adding redirectTo for iOS
import 'dart:io' show Platform;

Future<AuthResponse?> signInWithGoogle() async {
  try {
    _logger.i('Starting Google OAuth sign in...');
    
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Platform.isIOS 
          ? 'com.example.myfamily://auth-callback'
          : null,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    return null;
  } catch (e) {
    _logger.e('Google sign in error: $e');
    rethrow;
  }
}
```

### Step 5: Clean and Test

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

Wait 2-3 minutes after making Google Cloud Console changes before testing.

---

## The OAuth Flow on iOS

```
iOS App
   ↓
Opens Safari/ASWebAuthenticationSession
   ↓
User signs in with Google
   ↓
Google redirects to: https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
(Configured in Web OAuth Client)
   ↓
Supabase processes the auth
   ↓
Supabase redirects to: com.example.myfamily://auth-callback or myfamily://auth-callback
(Configured in Supabase Redirect URLs)
   ↓
iOS handles the custom URL scheme
   ↓
App receives the deep link
   ↓
Supabase SDK processes the token
   ↓
Authentication complete!
```

---

## Common iOS-Specific Issues

### Issue 1: Only Web Client Configured
❌ **Problem**: Only have Web OAuth client in Google Cloud Console  
✅ **Solution**: Also create an iOS OAuth client with your bundle ID

### Issue 2: Wrong Redirect URI Format
❌ **Problem**: Using `myfamily://` when iOS expects bundle ID scheme  
✅ **Solution**: Try `com.example.myfamily://auth-callback`

### Issue 3: Missing Redirect URI in Supabase
❌ **Problem**: Redirect URL not configured in Supabase Dashboard  
✅ **Solution**: Add it to Authentication → URL Configuration → Redirect URLs

### Issue 4: Cached OAuth State
❌ **Problem**: iOS caching old OAuth configuration  
✅ **Solution**: Delete app, clean build, reinstall

---

## Debugging

### Check What Redirect URI is Being Sent

Add logging to see what's happening:

```dart
Future<AuthResponse?> signInWithGoogle() async {
  try {
    final redirectUri = Platform.isIOS 
        ? 'com.example.myfamily://auth-callback'
        : 'myfamily://auth-callback';
    
    _logger.i('Using redirect URI: $redirectUri');
    
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    return null;
  } catch (e) {
    _logger.e('Google sign in error: $e');
    rethrow;
  }
}
```

### Check Supabase Logs

1. Go to Supabase Dashboard → **Logs** → **Auth Logs**
2. Look for entries related to Google OAuth
3. Check for errors or warnings about redirect URIs

### Test with Different Schemes

Try these redirect URIs one at a time in Supabase Dashboard:

1. `com.example.myfamily://auth-callback`
2. `myfamily://auth-callback`
3. `com.example.myfamily://oauth2redirect`

---

## Quick Checklist for iOS

- [ ] Created **both** Web and iOS OAuth clients in Google Cloud Console
- [ ] Web OAuth client has Supabase callback URL
- [ ] iOS OAuth client has your bundle ID (`com.example.myfamily`)
- [ ] Supabase Google provider uses Web client credentials
- [ ] Supabase Redirect URLs includes iOS scheme (try bundle ID scheme)
- [ ] Info.plist has both URL schemes configured
- [ ] Cleaned and rebuilt the iOS app
- [ ] Waited 2-3 minutes after Google Cloud Console changes
- [ ] Tested on a real device (not just simulator)

---

## Still Not Working?

Try this nuclear option:

1. **Delete the app** from your iOS device/simulator
2. **Clean everything**:
   ```bash
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod deintegrate
   pod install
   cd ..
   ```
3. **Rebuild**:
   ```bash
   flutter pub get
   flutter run
   ```
4. **Test** with a fresh install

If it still fails, check Xcode console logs for more detailed error messages.


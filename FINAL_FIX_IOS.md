# FINAL FIX: iOS Google OAuth with Supabase

## The Real Issue

Supabase has strict validation on redirect URLs and won't accept custom schemes like `com.example.myfamily://auth-callback` in the dashboard. However, Supabase Flutter SDK **automatically handles deep links** without you needing to configure them in the dashboard!

## The Correct Solution

### Step 1: Google Cloud Console (REQUIRED)

**You need TWO OAuth clients:**

#### Web Application Client
1. Go to [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**
2. Find/Create OAuth 2.0 Client ID of type: **Web application**
3. Add **ONLY this one** redirect URI:
   ```
   https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
   ```
4. Save and copy the **Client ID** and **Client Secret**

#### iOS Application Client
1. In the same Credentials page, create **another** OAuth 2.0 Client ID
2. Select type: **iOS**
3. Fill in:
   - **Bundle ID**: `com.example.myfamily`
4. Create and copy the iOS Client ID

### Step 2: Supabase Dashboard (REQUIRED)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → Your Project
2. Navigate to **Authentication** → **Providers** → **Google**
3. Configure:
   - **Enabled**: Toggle ON
   - **Client ID**: Paste the **Web application** Client ID (not the iOS one)
   - **Client Secret**: Paste the **Web application** Client Secret
   - **Authorized Client IDs** (optional): Add the iOS Client ID if there's a field for it
4. Save

5. Navigate to **Authentication** → **URL Configuration**
6. **DO NOT add custom scheme redirect URLs** (Supabase won't accept them)
7. Just set **Site URL** to something like:
   ```
   https://myfamily.app
   ```
   (This can be any valid URL, doesn't have to be real)
8. Save

### Step 3: Verify Info.plist (Already Done)

Your `ios/Runner/Info.plist` should have (already configured):

```xml
<key>CFBundleURLTypes</key>
<array>
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

### Step 4: Code (Already Updated)

Your code in `auth_repository.dart` should NOT include `redirectTo`:

```dart
Future<AuthResponse?> signInWithGoogle() async {
  try {
    _logger.i('Starting Google OAuth sign in...');
    
    // Don't pass redirectTo - Supabase Flutter SDK will automatically
    // detect and use the URL schemes from Info.plist
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
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

**Wait 2-3 minutes** after making Google Cloud Console changes before testing.

---

## Why This Works

1. **Google redirects to Supabase**: Uses the Web OAuth client callback URL
2. **Supabase processes auth**: Handles the OAuth response
3. **Supabase Flutter SDK auto-detects**: Reads URL schemes from Info.plist
4. **Opens your app**: Uses the `myfamily://` or `com.googleusercontent.apps...` scheme
5. **Completes auth**: SDK processes the token automatically

**You DON'T need to configure the mobile deep links in Supabase dashboard!**

---

## Summary Checklist

### In Google Cloud Console:
- [ ] **Web OAuth client** with redirect URI: `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback`
- [ ] **iOS OAuth client** with Bundle ID: `com.example.myfamily`

### In Supabase Dashboard:
- [ ] **Google provider enabled** with Web client credentials
- [ ] **Site URL set** (any valid URL like `https://myfamily.app`)
- [ ] **DO NOT add custom schemes to Redirect URLs** - leave it empty or just use the Site URL

### In Your Code:
- [ ] **No `redirectTo` parameter** in `signInWithOAuth()`
- [ ] **Both URL schemes in Info.plist** (already done)

### Final Steps:
- [ ] Clean build
- [ ] Wait 2-3 minutes after Google changes
- [ ] Test on real device (simulator may have issues)

---

## The Key Insight

**Supabase Dashboard's "Redirect URLs" field is mainly for web applications!**

For mobile apps:
- Supabase Flutter SDK automatically handles deep links
- It reads URL schemes from your iOS/Android config files
- You don't need to (and can't) add them to the Supabase dashboard

The OAuth flow:
```
App → Google → Supabase (Web callback) → Supabase SDK detects deep link → Opens app
```

---

## If It Still Doesn't Work

### Check iOS Client ID Format

The Google Sign-In URL scheme in Info.plist should match your iOS OAuth client:

```xml
<string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
```

Update the reversed client ID if needed:
1. Get your iOS Client ID from Google Cloud Console
2. Reverse it: If Client ID is `123-abc.apps.googleusercontent.com`, use `com.googleusercontent.apps.123-abc`
3. Update Info.plist

### Enable More Logging

```dart
Future<AuthResponse?> signInWithGoogle() async {
  try {
    _logger.i('Starting Google OAuth...');
    _logger.i('Supabase URL: ${_supabase.auth.currentSession}');
    
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    _logger.i('OAuth initiated successfully');
    return null;
  } catch (e) {
    _logger.e('Error details: $e');
    _logger.e('Stack trace: ${StackTrace.current}');
    rethrow;
  }
}
```

### Check Supabase Auth Logs

Go to Supabase Dashboard → **Logs** → **Auth** to see what's happening during the OAuth flow.

---

## Test on Real Device

Simulators sometimes have issues with OAuth redirects. Always test on a real iPhone if possible.


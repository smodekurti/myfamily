# Complete Google Sign-In Setup Guide for Supabase + Flutter

## The Issue You're Facing

**Error 400: redirect_uri_mismatch** when trying to sign in with Google.

## Why This Happens

Google OAuth requires the redirect URI in your OAuth request to exactly match what's registered in Google Cloud Console. With Supabase + Flutter mobile apps, there are multiple redirect URIs involved in the flow.

## The Complete Solution

Follow these steps **in order** and **exactly**:

---

## Step 1: Configure Google Cloud Console

### 1.1 Navigate to Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Credentials**

### 1.2 Find the CORRECT OAuth Client
**CRITICAL**: You need to edit the **Web application** OAuth 2.0 Client ID, NOT the iOS or Android clients.

Look for an OAuth 2.0 Client ID with:
- Type: **Web application**
- This is the one Supabase uses

### 1.3 Add the Supabase Redirect URI

Click on the Web application OAuth client and add **ONLY THIS ONE** redirect URI:

```
https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
```

This is where Google sends the OAuth response. It MUST match your Supabase project URL exactly.

**IMPORTANT**: 
- Google Cloud Console Web OAuth clients ONLY accept HTTPS URLs
- Do NOT try to add `myfamily://` or `com.googleusercontent.apps...` URLs here - they will be rejected
- Those deep links are configured in your app and Supabase dashboard, not in Google Cloud Console

### 1.4 Save
Click **Save** and wait 2-3 minutes for changes to propagate.

---

## Step 2: Configure Supabase Dashboard

### 2.1 Navigate to Authentication
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Authentication** → **URL Configuration**

### 2.2 Set Redirect URLs
In the **Redirect URLs** section, add:
```
myfamily://auth-callback
```

### 2.3 Set Site URL
Set the **Site URL** to any valid URL (it doesn't have to be real):
```
https://myfamily.app
```

### 2.4 Configure Google Provider
1. Go to **Authentication** → **Providers**
2. Find **Google** and click to configure
3. Ensure:
   - ✅ **Enabled** toggle is ON
   - ✅ **Client ID** matches your Google Cloud Console Web application Client ID
   - ✅ **Client Secret** matches your Google Cloud Console Web application Client Secret

**IMPORTANT**: Use the credentials from the **Web application** OAuth client, not iOS or Android clients.

### 2.5 Save
Click **Save**.

---

## Step 3: Verify Your Code

### 3.1 Check main.dart
Your Supabase initialization should look like this:

```dart
await Supabase.initialize(
  url: 'https://vovfhxnmiximhzdjadvu.supabase.co',
  anonKey: 'your-anon-key',
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);
```

### 3.2 Check auth_repository.dart
Your Google sign-in method should NOT include `redirectTo`:

```dart
Future<AuthResponse?> signInWithGoogle() async {
  await _supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    authScreenLaunchMode: LaunchMode.externalApplication,
  );
  return null;
}
```

**Do NOT pass `redirectTo` parameter** - Supabase will handle it automatically.

### 3.3 Check AndroidManifest.xml
Should have BOTH intent filters:

```xml
<!-- Deep link for OAuth callbacks -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="myfamily" android:host="auth-callback"/>
</intent-filter>

<!-- Google OAuth redirect for Android -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data 
        android:scheme="com.googleusercontent.apps.879363886187-d4oh6t8c7lfsk4979cvkrduta08gk095"
        android:host="oauth2redirect"/>
</intent-filter>
```

### 3.4 Check Info.plist (iOS)
Should have both URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Supabase Deep Link -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myfamily</string>
        </array>
    </dict>
    <!-- Google Sign-In -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.879363886187-d4oh6t8c7lfsk4979cvkrduta08gk095</string>
        </array>
    </dict>
</array>
```

---

## Step 4: Test

1. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Wait 2-3 minutes** after making Google Cloud Console changes

3. **Test the sign-in flow**:
   - Tap "Sign in with Google"
   - Select your Google account
   - Should redirect back to your app successfully

---

## How It Works

```
User taps "Sign in with Google"
           ↓
App opens Google OAuth in browser
           ↓
User authenticates with Google
           ↓
Google redirects to: https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
(This URL must be in Google Cloud Console)
           ↓
Supabase processes the OAuth response
           ↓
Supabase redirects to: myfamily://auth-callback (iOS) or 
    com.googleusercontent.apps...:/oauth2redirect (Android)
(These must be in Supabase Dashboard and app config)
           ↓
Your app receives the deep link
           ↓
Authentication complete!
```

---

## Common Mistakes

❌ **Editing the wrong OAuth client** - Must be Web application, not iOS/Android  
❌ **Missing Supabase callback URL** - Must have the HTTPS callback in Google Cloud Console  
❌ **Trying to add deep links to Google Cloud Console** - Only HTTPS URLs are accepted there  
❌ **Wrong Client ID in Supabase** - Must match Web application client  
❌ **Including `redirectTo` in code** - Should be omitted for mobile apps  
❌ **Not waiting for changes to propagate** - Google changes take 2-3 minutes  

---

## Still Not Working?

1. **Check Supabase Logs**:
   - Dashboard → Logs → Auth Logs
   - Look for specific error messages

2. **Verify Client IDs match**:
   - Compare the Client ID in Supabase Google provider
   - With the Web application Client ID in Google Cloud Console
   - They must be identical

3. **Try with a different Google account**:
   - Sometimes account-specific consent issues occur

4. **Clear browser cache**:
   - OAuth state can get cached

5. **Reinstall the app**:
   - Sometimes app data caching causes issues

---

## Quick Checklist

- [ ] Added Supabase HTTPS callback URL to Google Cloud Console Web OAuth client
- [ ] Did NOT try to add mobile deep links to Google Cloud Console (they won't work there)
- [ ] Configured Supabase Authentication URL Configuration with deep link
- [ ] Set Supabase Site URL
- [ ] Enabled Google provider in Supabase with correct credentials
- [ ] Removed `redirectTo` from `signInWithOAuth()` code
- [ ] Added both intent filters to AndroidManifest.xml
- [ ] Added both URL schemes to iOS Info.plist
- [ ] Cleaned and rebuilt the app
- [ ] Waited 2-3 minutes after Google Cloud Console changes

If you've checked all of these, it should work!


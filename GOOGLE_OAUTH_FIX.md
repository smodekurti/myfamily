# Fixing Google OAuth Redirect URI Mismatch

## Problem
You're seeing the error: **"Error 400: redirect_uri_mismatch"** when trying to sign in with Google.

## Solution
The redirect URI must be configured in **TWO places**: Google Cloud Console AND Supabase Dashboard. The redirect URI that Google receives is actually the Supabase callback URL, not the deep link.

## Steps to Fix

### Step 1: Configure Google Cloud Console (REQUIRED)

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one if needed)
3. Navigate to **APIs & Services** → **Credentials**
4. Find your **OAuth 2.0 Client ID** (look for type "Web application")
5. Click on it to edit
6. In the **Authorized redirect URIs** section, add **ONLY THIS ONE**:

```
https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback
```

**This is the ONLY redirect URI you need in Google Cloud Console.**

7. Click **Save**

**IMPORTANT**: 
- Only add the HTTPS Supabase URL here
- Do NOT add the `myfamily://` or `com.googleusercontent.apps` URLs - those won't be accepted by Google Cloud Console Web clients
- Those deep links are handled by Supabase and your mobile OS, not by Google

### Step 2: Configure Supabase Dashboard (REQUIRED)

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add:

```
myfamily://auth-callback
```

5. Also verify that **Site URL** is set (can be any valid URL, e.g., `https://myfamily.app`)

6. Go to **Authentication** → **Providers** → **Google**
7. Make sure Google provider is **Enabled**
8. Verify your **Client ID** and **Client Secret** are correctly entered
9. Save changes

### Step 3: Wait and Test
1. Wait 2-3 minutes for changes to propagate
2. **Completely restart your app** (not just hot reload)
3. Try signing in with Google again

## What We Changed in the Code

1. **Updated `auth_repository.dart`**: Removed the `redirectTo` parameter - Supabase Flutter automatically detects and uses the deep link configured in your app
2. **Updated `AndroidManifest.xml`**: Added deep link intent filter for `myfamily://auth-callback`
3. **iOS already configured**: Your `Info.plist` already has the `myfamily://` URL scheme configured

**Important**: For mobile apps, do NOT pass `redirectTo` in `signInWithOAuth()`. Supabase will automatically:
- Use its callback URL (`https://your-project.supabase.co/auth/v1/callback`) when talking to Google
- Redirect back to your app using the deep link (`myfamily://`) after processing

## Testing

After making the Google Cloud Console changes:

1. Wait 2-3 minutes for changes to propagate
2. Restart your app completely
3. Try signing in with Google again

The OAuth flow should now work correctly!

## How It Works

1. User taps "Sign in with Google" in your app
2. App opens Google OAuth in browser
3. User authenticates with Google
4. **Google redirects to Supabase**: `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback` ← This must be in Google Cloud Console
5. Supabase processes the OAuth response
6. **Supabase redirects to your app**: `myfamily://auth-callback` ← This must be in Supabase Dashboard
7. Your app receives the deep link and completes authentication

## Troubleshooting

If it still doesn't work:

1. **Double-check Google Cloud Console has the Supabase callback URL**:
   - `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback`
   
   (No trailing slash, exact match - this is the ONLY URL you need in Google Cloud Console)

2. **Verify you're editing the Web OAuth client**: In Google Cloud Console, make sure you're editing the "Web application" OAuth 2.0 Client ID, NOT the iOS or Android clients.

3. **Double-check Supabase Dashboard**:
   - Redirect URLs: `myfamily://auth-callback`
   - Site URL: Any valid URL (e.g., `https://myfamily.app`)
   - Google provider: Enabled with correct Client ID and Secret

4. **Clear app data and reinstall**: Sometimes cached OAuth state can cause issues
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check Supabase logs**: Go to **Logs** → **Auth Logs** in Supabase dashboard to see detailed error messages

6. **Verify Client ID matches**: The Client ID in Supabase Google provider settings must match the Web application Client ID from Google Cloud Console

## Additional Notes

- The deep link `myfamily://auth-callback` is handled by Supabase Flutter SDK automatically
- For production, you may want to use your actual bundle ID as the scheme (e.g., `com.example.myfamily://auth-callback`)
- Make sure you're using the same OAuth Client ID in both Google Cloud Console and Supabase Dashboard


# Fix: iOS Unacceptable Audience Error

## The Error
```
AuthApiException(message: Unacceptable audience in id_token: [985416533716-n3cn247pk6ftagt9c7kdq3h4k3fqj0nu.apps.googleusercontent.com], statusCode: 400, code: null)
```

## The Problem
The iOS OAuth client ID `985416533716-n3cn247pk6ftagt9c7kdq3h4k3fqj0nu.apps.googleusercontent.com` is **NOT** in Supabase's "Authorized Client IDs" list.

## The Solution

### Step 1: Go to Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **Providers** → **Google**

### Step 2: Add the iOS Client ID to Authorized Client IDs
1. Find the **"Authorized Client IDs"** field (or "Allowed Client IDs")
2. Add this iOS client ID:
   ```
   985416533716-n3cn247pk6ftagt9c7kdq3h4k3fqj0nu.apps.googleusercontent.com
   ```
3. If there are other client IDs already there, keep them and add this one (comma-separated or one per line)
4. Ensure **"Skip nonce checks"** is **Enabled** (required for native mobile sign-in)
5. Click **Save**

### Step 3: Verify All Client IDs
Make sure you have ALL these client IDs in Supabase's "Authorized Client IDs":
- ✅ **Web Client ID** (for Supabase server) - the main one configured in "Client ID" field
- ✅ **Android Client ID**: `985416533716-aovmnhh45glq9oos67c5nlgql6lmllf7.apps.googleusercontent.com`
- ✅ **iOS Client ID**: `985416533716-n3cn247pk6ftagt9c7kdq3h4k3fqj0nu.apps.googleusercontent.com` ⬅️ **Add this one!**

### Step 4: Wait and Test
1. **Wait 1-2 minutes** for changes to propagate
2. **Test Google Sign-In on iOS again**

## Why This Happens

When you use native Google Sign-In on iOS:
1. Google Sign-In SDK gets an ID token
2. The ID token contains an "audience" field (the OAuth client ID that issued it)
3. Supabase validates that this audience is in the "Authorized Client IDs" list
4. If not found → "Unacceptable audience" error

## Summary

**Add this to Supabase "Authorized Client IDs":**
```
985416533716-n3cn247pk6ftagt9c7kdq3h4k3fqj0nu.apps.googleusercontent.com
```

**Also ensure you have:**
- Android: `985416533716-aovmnhh45glq9oos67c5nlgql6lmllf7.apps.googleusercontent.com`
- Web: (Your main Supabase Google OAuth Client ID)

After adding it and waiting a minute, Google Sign-In on iOS should work! 🎉




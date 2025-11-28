# Fix: Unacceptable Audience Error

## ✅ Good News!
Google Sign-In is now working! You got past Error 10. The issue now is that Supabase doesn't recognize the client ID in the token.

## The Error
```
Unacceptable audience in id_token: [985416533716-28r12jock8ajote1gqv4dl8fdsl42n2r.apps.googleusercontent.com]
```

## The Problem
The Android OAuth client ID `985416533716-28r12jock8ajote1gqv4dl8fdsl42n2r.apps.googleusercontent.com` is **NOT** in Supabase's "Authorized Client IDs" list.

## The Solution

### Step 1: Go to Supabase Dashboard
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** → **Providers** → **Google**

### Step 2: Add the Client ID to Authorized Client IDs
1. Find the **"Authorized Client IDs"** field (or "Allowed Client IDs")
2. Add this client ID:
   ```
   985416533716-28r12jock8ajote1gqv4dl8fdsl42n2r.apps.googleusercontent.com
   ```
3. If there are other client IDs already there, keep them and add this one (comma-separated or one per line)
4. Ensure **"Skip nonce checks"** is **Enabled**
5. Click **Save**

### Step 3: Verify All Client IDs
Make sure you have ALL these client IDs in Supabase's "Authorized Client IDs":
- ✅ **Web Client ID** (for Supabase server) - usually the main one configured
- ✅ **Android Client ID**: `985416533716-28r12jock8ajote1gqv4dl8fdsl42n2r.apps.googleusercontent.com` (the one causing the error)
- ✅ **iOS Client ID** (if you're using iOS): `879363886187-d4oh6t8c7lfsk4979cvkrduta08gk095.apps.googleusercontent.com`

### Step 4: Wait and Test
1. **Wait 1-2 minutes** for changes to propagate
2. **Test Google Sign-In again**

## Why This Happens

When you use native Google Sign-In:
1. Google Sign-In SDK gets an ID token
2. The ID token contains an "audience" field (the OAuth client ID that issued it)
3. Supabase validates that this audience is in the "Authorized Client IDs" list
4. If not found → "Unacceptable audience" error

## Summary

**Add this to Supabase "Authorized Client IDs":**
```
985416533716-28r12jock8ajote1gqv4dl8fdsl42n2r.apps.googleusercontent.com
```

After adding it and waiting a minute, Google Sign-In should work! 🎉



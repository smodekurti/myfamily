# iOS Google OAuth Setup - CRITICAL FIX

## The Problem
The app crashes because Google Sign-In SDK requires an **iOS OAuth Client ID** in Google Cloud Console, but you only have a Web client configured.

## Step 1: Create iOS OAuth Client

1. **Go to Google Cloud Console**
   - https://console.cloud.google.com/apis/credentials
   - **Make sure you're in the SAME project** as your Web OAuth client

2. **Click "Create Credentials" → "OAuth 2.0 Client ID"**

3. **Select "iOS" as Application Type**

4. **Configure iOS Client:**
   - **Name**: `MyFamily iOS App`
   - **Bundle ID**: `com.example.myfamily` (MUST match your app's bundle ID)
   - Click "Create"

5. **Copy the Client ID** (it will look like: `123456789-xxxxx.apps.googleusercontent.com`)
   - **Don't use this Client ID anywhere in your code!**
   - It's just for Google to know your iOS app is authorized

## Step 2: Verify Your Info.plist

Your current `GIDClientID` should remain as the **Web OAuth Client ID**:
```
667205355253-27f7j56brcs23uusvfo7gpt2cn6lcblo.apps.googleusercontent.com
```

**DO NOT change `GIDClientID` to the iOS client ID!**

## Step 3: Test

After creating the iOS OAuth client, try signing in again. The crash should be fixed.

## Why This Happens

Google Sign-In on iOS works like this:
1. Native SDK checks if an **iOS OAuth client** exists for your bundle ID
2. If not found → **CRASH** ❌
3. If found → Opens Google sign-in
4. After sign-in → Validates ID token using **Web OAuth client** (GIDClientID)

You had step 4 configured, but missed step 1!

## Current Configuration Summary

- ✅ Web OAuth Client: `667205355253-27f7j56brcs23uusvfo7gpt2cn6lcblo.apps.googleusercontent.com`
- ✅ GIDClientID in Info.plist: (same as Web client)
- ✅ URL Scheme: `com.googleusercontent.apps.667205355253-27f7j56brcs23uusvfo7gpt2cn6lcblo`
- ❌ **iOS OAuth Client: NOT CREATED YET** ← This is causing the crash!

## After Creating iOS Client

Once you create the iOS OAuth client with bundle ID `com.example.myfamily`, Google's servers will recognize your iOS app and the crash will be fixed.

**No code changes needed!** Just create the iOS OAuth client in Google Cloud Console.


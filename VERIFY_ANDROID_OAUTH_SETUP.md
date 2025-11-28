# Verify Android OAuth Setup - Error 10 Fix

## ✅ SHA-1 Fingerprint Status
You already have SHA-1 registered in Firebase:
- **SHA-1**: `e5:f4:83:90:e2:a5:54:35:2e:7e:ce:8f:53:9e:5a:76:cf:30:53:67`

Since Error 10 persists, let's verify the complete setup:

## Step 1: Verify Android OAuth Client in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **myfamily-e897d**
3. Navigate to **APIs & Services** → **Credentials**
4. Look for an **Android** OAuth 2.0 Client ID
   - Should have package name: `com.example.myfamily`
   - Should have SHA-1: `e5:f4:83:90:e2:a5:54:35:2e:7e:ce:8f:53:9e:5a:76:cf:30:53:67`

**If Android OAuth client doesn't exist:**
1. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Select **Android** as application type
3. Enter:
   - **Name**: MyFamily Android
   - **Package name**: `com.example.myfamily`
   - **SHA-1 certificate fingerprint**: `e5:f4:83:90:e2:a5:54:35:2e:7e:ce:8f:53:9e:5a:76:cf:30:53:67`
4. Click **Create**
5. Copy the **Client ID** (looks like: `879363886187-xxxxx.apps.googleusercontent.com`)

## Step 2: Add Android Client ID to Supabase

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Authentication** → **Providers** → **Google**
3. In **Authorized Client IDs** field, add:
   - Your **Android OAuth Client ID** (from Step 1)
   - Your **Web OAuth Client ID** (if not already there)
4. Ensure:
   - ✅ **Skip nonce checks** is **Enabled**
   - ✅ Google provider is **Enabled**
5. Click **Save**

## Step 3: Verify google-services.json

Your `google-services.json` should have the Android OAuth client. Check that it includes:
- Package name: `com.example.myfamily`
- OAuth client with `client_type: 3` (Android)

## Step 4: Rebuild and Test

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Rebuild app**:
   ```bash
   flutter run
   ```

3. **Wait 2-3 minutes** after making Google Cloud Console changes

4. **Test Google Sign-In**

## Common Issues

### Issue: SHA-1 doesn't match
- Verify the SHA-1 in Firebase matches your actual app's keystore
- For debug builds, use: `~/.android/debug.keystore`
- Get SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

### Issue: Android OAuth client not found
- Create it in Google Cloud Console (see Step 1)
- Make sure package name and SHA-1 match exactly

### Issue: Still getting Error 10
- Verify Android OAuth client ID is in Supabase "Authorized Client IDs"
- Wait 5-10 minutes for changes to propagate
- Completely uninstall and reinstall the app
- Check that you're using the correct keystore (debug vs release)

## Quick Checklist

- [ ] SHA-1 fingerprint registered in Firebase ✅ (You have this)
- [ ] Android OAuth client created in Google Cloud Console
- [ ] Android OAuth client ID added to Supabase "Authorized Client IDs"
- [ ] "Skip nonce checks" enabled in Supabase
- [ ] App rebuilt after configuration changes
- [ ] Waited 2-3 minutes for changes to propagate

---

**The most likely issue**: Android OAuth client ID not added to Supabase "Authorized Client IDs"



# Google OAuth Final Solution - Same Project Required

## The Error

```
The audience client and the client need to be in the same project
```

This means your iOS OAuth client and Web OAuth client are in **different** Google Cloud projects. They MUST be in the SAME project!

---

## SOLUTION: Ensure Both OAuth Clients in Same Project

### Step 1: Go to Google Cloud Console

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. **SELECT THE PROJECT** where your Web OAuth client exists (the one you're using in Supabase)

### Step 2: Verify Web OAuth Client Exists

1. Go to **APIs & Services** → **Credentials**
2. Find your **Web application** OAuth 2.0 Client ID
3. Note the Client ID: `667205355253-2m542escb9oc8rrjhaajhm537j1n8gh4.apps.googleusercontent.com`
4. Verify the redirect URI is: `https://vovfhxnmiximhzdjadvu.supabase.co/auth/v1/callback`

### Step 3: Create/Verify iOS OAuth Client in SAME Project

**CRITICAL**: Create the iOS client in the **SAME project** as the Web client!

1. In the **SAME project**, click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**
2. Select **iOS** as application type
3. Fill in:
   - **Name**: MyFamily iOS
   - **Bundle ID**: `com.example.myfamily`
4. Click **Create**
5. **Copy the iOS Client ID** (e.g., `879363886187-xxxxxxx.apps.googleusercontent.com`)

### Step 4: Update Info.plist with Correct iOS Client ID

Update both places in `ios/Runner/Info.plist`:

```xml
<!-- Add this at the top level -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID_HERE.apps.googleusercontent.com</string>

<!-- And update the URL scheme -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reverse the iOS Client ID -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

**Example**: If your iOS Client ID is `123456789-abc.apps.googleusercontent.com`, then:
- `GIDClientID`: `123456789-abc.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.123456789-abc`

---

## Quick Fix Alternative: Use Only Web Client

If creating an iOS client is problematic, you can use **only the Web OAuth client** for both:

### Update Info.plist

```xml
<key>GIDClientID</key>
<string>667205355253-2m542escb9oc8rrjhaajhm537j1n8gh4.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.667205355253-2m542escb9oc8rrjhaajhm537j1n8gh4</string>
        </array>
    </dict>
</array>
```

This uses your Web OAuth client for both native sign-in and server authentication.

---

## After Making Changes

```bash
flutter clean
cd ios
pod install
cd ..
flutter run
```

---

## Verification Checklist

- [ ] Both Web and iOS OAuth clients exist in Google Cloud Console
- [ ] They are in the **SAME Google Cloud project**
- [ ] Web Client ID matches what's in Supabase Dashboard
- [ ] iOS Client ID is in Info.plist `GIDClientID`
- [ ] Reversed iOS Client ID is in Info.plist URL schemes
- [ ] `serverClientId` in code matches Web Client ID
- [ ] Cleaned and rebuilt the app

---

## Test

1. Tap "Sign in with Google"
2. Native iOS account picker appears
3. Select account
4. ✅ Authentication succeeds!

The key is ensuring both OAuth clients are in the **same Google Cloud project**.


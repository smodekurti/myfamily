# Push Notifications Setup Guide (FCM API v1)

## Important: Firebase Has Deprecated Server Key

Firebase has **deprecated the legacy Server Key** (as of June 2023). The new approach uses **FCM API v1** with **Service Account credentials** and OAuth 2.0 tokens.

---

## Step 1: Get Service Account Credentials

### 1.1 Navigate to Service Accounts

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **MyFamily**
3. Click the **gear icon** (⚙️) → **Project settings**
4. Go to the **"Service accounts"** tab

### 1.2 Generate Service Account Key

1. In the **Service accounts** tab, you'll see:
   - **Firebase Admin SDK** section
   - A button: **"Generate new private key"**

2. Click **"Generate new private key"**
3. A dialog will appear warning about keeping the key secure
4. Click **"Generate key"**
5. A JSON file will download (e.g., `myfamily-d1388-firebase-adminsdk-xxxxx.json`)

**⚠️ Important:** Keep this file secure! Never commit it to git.

---

## Step 2: Extract Information from Service Account JSON

Open the downloaded JSON file. You'll need:

1. **Project ID**: Found in `project_id` field (e.g., `"myfamily-d1388"`)
2. **Client Email**: Found in `client_email` field
3. **Private Key**: Found in `private_key` field (entire key including `-----BEGIN PRIVATE KEY-----`)

---

## Step 3: Set Up Supabase Secrets

### 3.1 Set Service Account JSON

In Supabase Dashboard or via CLI:

```bash
# Option 1: Via Supabase CLI
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<paste entire JSON content here>'

# Option 2: Via Supabase Dashboard
# Go to: Project Settings → Edge Functions → Secrets
# Add: FCM_SERVICE_ACCOUNT_JSON = <paste JSON>
```

**Note:** The entire JSON file content should be set as the secret value.

### 3.2 Set Project ID

```bash
supabase secrets set FCM_PROJECT_ID='myfamily-d1388'
```

Or extract from the JSON file's `project_id` field.

---

## Step 4: Edge Function is Ready!

✅ **Good news!** The Edge Function (`supabase/functions/send-push-notification/index.ts`) is already updated to use FCM API v1 with Service Account credentials.

It uses the `jose` JWT library for Deno to sign tokens properly. No changes needed!

---

## Step 5: Deploy Edge Function

```bash
supabase functions deploy send-push-notification
```

---

## Step 6: Test

1. Run your Flutter app
2. Create a task and assign it to another user
3. Check Supabase Edge Function logs for any errors
4. The other user should receive a push notification

---

## Alternative: Simpler Approach Using HTTP

If JWT signing is complex in Deno Edge Functions, you can:

1. **Use a Cloud Function** (Firebase Functions or Cloud Run) to handle FCM sending
2. **Call that function** from your Supabase Edge Function
3. This separates the OAuth complexity from Supabase

---

## Troubleshooting

### Error: "FCM_SERVICE_ACCOUNT_JSON not configured"

- Make sure you set the secret in Supabase
- The entire JSON content should be set as the secret value
- No line breaks or formatting issues

### Error: "Failed to get access token"

- Check that the service account JSON is valid
- Ensure the private key includes the full key (with BEGIN/END markers)
- Verify the `client_email` and `project_id` are correct

### Error: "FCM_PROJECT_ID not configured"

- Set the `FCM_PROJECT_ID` secret
- Or extract it from the service account JSON's `project_id` field

### Notifications Not Received

- Check Edge Function logs in Supabase Dashboard
- Verify FCM tokens are saved in `user_fcm_tokens` table
- Ensure the device has notification permissions enabled
- Check Firebase Console → Cloud Messaging for delivery status

---

## Summary

✅ **What Changed:**
- No more Server Key (deprecated)
- Now using Service Account JSON
- Using FCM API v1 with OAuth 2.0 tokens
- More secure and modern approach

✅ **What You Need:**
1. Service Account JSON file from Firebase
2. Set `FCM_SERVICE_ACCOUNT_JSON` secret in Supabase
3. Set `FCM_PROJECT_ID` secret in Supabase
4. Update Edge Function to use FCM API v1

The Edge Function code I provided needs JWT signing implementation. You can either:
- Use a JWT library for Deno (like `jose`)
- Use a separate Cloud Function for FCM
- Use Supabase's database functions with pgcrypto

Let me know which approach you'd prefer, and I can help implement it!


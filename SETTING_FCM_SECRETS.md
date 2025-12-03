# Setting FCM Secrets in Supabase

## Important: JSON Format

**NO parentheses needed!** Just copy the complete JSON object.

## Method 1: Using Supabase Dashboard (Recommended)

1. Go to **Supabase Dashboard** → Your Project
2. Navigate to **Edge Functions** → **Secrets**
3. Click **Add Secret** or edit existing secret

### For `FCM_SERVICE_ACCOUNT_JSON`:

**Copy the ENTIRE JSON file content** from your service account JSON file. It should look like this:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

**Paste it directly** into the secret value field. The Supabase Dashboard will handle it correctly.

### For `FCM_PROJECT_ID`:

Just paste your Firebase project ID (e.g., `myfamily-12345`). No quotes, no JSON, just the ID.

---

## Method 2: Using Supabase CLI

### For `FCM_SERVICE_ACCOUNT_JSON`:

**Option A: Using a file (Easiest)**

```bash
# Read the JSON file and set it as secret
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
```

**Option B: Inline (Requires escaping)**

```bash
# You need to escape quotes and handle newlines
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"your-project",...}'
```

⚠️ **Warning:** Inline method is tricky because you need to:
- Escape all double quotes: `"` becomes `\"`
- Handle newlines in the private key
- Keep it as a single line or use proper escaping

**Recommendation:** Use Option A (file method) or use the Dashboard.

### For `FCM_PROJECT_ID`:

```bash
supabase secrets set FCM_PROJECT_ID='your-project-id'
```

---

## What NOT to Do

❌ **Don't wrap it in parentheses:**
```
(FCM_SERVICE_ACCOUNT_JSON)  ← Wrong!
```

❌ **Don't add extra quotes:**
```
"{"type":"service_account",...}"  ← Wrong! (double quotes)
```

❌ **Don't use single quotes around the JSON:**
```
'{"type":"service_account",...}'  ← Wrong for Dashboard (OK for CLI)
```

✅ **Do paste the raw JSON:**
```
{"type":"service_account","project_id":"...",...}  ← Correct!
```

---

## Verification

After setting the secrets, you can verify they're set (but not see their values):

```bash
supabase secrets list
```

You should see:
- `FCM_SERVICE_ACCOUNT_JSON` ✓
- `FCM_PROJECT_ID` ✓

---

## Example: Complete Service Account JSON

Your service account JSON file should contain something like this (this is what you copy):

```json
{
  "type": "service_account",
  "project_id": "myfamily-12345",
  "private_key_id": "a1b2c3d4e5f6...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7vN...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-abc123@myfamily-12345.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-abc123%40myfamily-12345.iam.gserviceaccount.com"
}
```

**Copy this entire JSON object** (from `{` to `}`) and paste it into the Supabase Dashboard secret field.

---

## Quick Checklist

- [ ] Downloaded service account JSON from Firebase Console
- [ ] Opened the JSON file in a text editor
- [ ] Selected ALL content (Ctrl+A / Cmd+A)
- [ ] Copied it (Ctrl+C / Cmd+C)
- [ ] Pasted into Supabase Dashboard → Edge Functions → Secrets → `FCM_SERVICE_ACCOUNT_JSON`
- [ ] Set `FCM_PROJECT_ID` to your Firebase project ID (just the ID, no JSON)
- [ ] Deployed the Edge Function: `supabase functions deploy send-push-notification`



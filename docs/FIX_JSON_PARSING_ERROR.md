# Fixing JSON Parsing Error in FCM_SERVICE_ACCOUNT_JSON

## Error Message
```
Error parsing SERVICE_ACCOUNT_JSON: SyntaxError: Unexpected non-whitespace character after JSON at position 6
```

This means the JSON string has extra characters or is malformed.

## Common Causes

### 1. Extra Characters Before/After JSON
The secret might have:
- Extra spaces or newlines
- Extra quotes around the JSON
- Comments or other text

### 2. Double-Encoded JSON
The JSON might be wrapped in quotes, making it a string containing JSON instead of actual JSON.

### 3. Incomplete Copy
Only part of the JSON was copied.

## How to Fix

### Step 1: Get Your Service Account JSON File

1. Go to **Firebase Console** → Your Project
2. Click **Project Settings** (gear icon)
3. Go to **Service Accounts** tab
4. Click **Generate new private key**
5. Download the JSON file (e.g., `myfamily-12345-firebase-adminsdk-abc123.json`)

### Step 2: Open the JSON File

Open the downloaded file in a text editor (VS Code, TextEdit, etc.)

### Step 3: Verify the JSON Format

The file should start with `{` and end with `}`. It should look like:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  ...
}
```

**Important:** 
- Must start with `{` (no spaces, no quotes before it)
- Must end with `}` (no spaces, no quotes after it)
- No extra text before or after

### Step 4: Copy the ENTIRE Content

1. **Select ALL** (Ctrl+A / Cmd+A)
2. **Copy** (Ctrl+C / Cmd+C)
3. Make sure you got everything from `{` to `}`

### Step 5: Set the Secret in Supabase

#### Option A: Using Supabase Dashboard (Recommended)

1. Go to **Supabase Dashboard** → Your Project
2. Navigate to **Edge Functions** → **Secrets**
3. Find `FCM_SERVICE_ACCOUNT_JSON` or create it
4. **Delete the old value completely**
5. **Paste the JSON** directly (Ctrl+V / Cmd+V)
6. **Don't add any quotes** around it
7. **Don't add any spaces** before or after
8. Click **Save**

#### Option B: Using Supabase CLI

```bash
# Read the JSON file directly (this avoids copy/paste issues)
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat /path/to/your-service-account-key.json)"
```

Replace `/path/to/your-service-account-key.json` with the actual path to your downloaded JSON file.

### Step 6: Verify the Secret

The secret should contain:
- Starts with `{`
- Contains `"type": "service_account"`
- Contains `"private_key": "-----BEGIN PRIVATE KEY-----..."`
- Contains `"client_email": "..."`
- Ends with `}`

## Common Mistakes to Avoid

❌ **Don't wrap in quotes:**
```
"{...}"  ← Wrong! This makes it a string containing JSON
```

❌ **Don't add extra spaces:**
```
  {...}  ← Wrong! Extra spaces before/after
```

❌ **Don't copy only part of it:**
```
"type": "service_account",  ← Wrong! Need the entire object
```

❌ **Don't add comments:**
```
// Service account
{...}  ← Wrong! JSON doesn't support comments
```

✅ **Do copy the entire JSON object:**
```
{...}  ← Correct! The entire object from { to }
```

## Testing After Fix

1. **Deploy the updated function:**
   ```bash
   supabase functions deploy send-push-notification
   ```

2. **Test by creating a task** and assigning it to yourself

3. **Check the logs** in Supabase Dashboard → Edge Functions → send-push-notification → Logs

The updated function now:
- Trims whitespace automatically
- Removes surrounding quotes if present
- Provides better error messages

## Still Having Issues?

If you're still getting errors:

1. **Check the secret value** in Supabase Dashboard:
   - Does it start with `{`?
   - Does it end with `}`?
   - Is it valid JSON? (you can test at jsonlint.com)

2. **Try using the CLI method** instead of Dashboard:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
   ```

3. **Check the logs** for the first/last 100 characters of the JSON string to see what was actually stored



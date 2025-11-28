# Fixing 500 Error in send-push-notification Edge Function

## Common Causes of 500 Error

The 500 error you're seeing is typically caused by one of these issues:

### 1. Missing Secrets (Most Common)

The Edge Function requires two secrets to be configured in Supabase:

- `FCM_SERVICE_ACCOUNT_JSON` - The full service account JSON from Firebase
- `FCM_PROJECT_ID` - Your Firebase project ID

**How to Check:**
1. Go to Supabase Dashboard → Your Project
2. Navigate to **Edge Functions** → **Secrets**
3. Verify both secrets are set:
   - `FCM_SERVICE_ACCOUNT_JSON` should contain the full JSON (not just a path)
   - `FCM_PROJECT_ID` should be your Firebase project ID (e.g., `myfamily-12345`)

**How to Fix:**
1. If secrets are missing, follow the steps in `PUSH_NOTIFICATIONS_SETUP_V1.md`
2. Set the secrets using Supabase CLI:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
   supabase secrets set FCM_PROJECT_ID='your-project-id'
   ```
   Or set them in the Supabase Dashboard under Edge Functions → Secrets

### 2. Invalid Service Account JSON Format

The `FCM_SERVICE_ACCOUNT_JSON` must be:
- Valid JSON (properly escaped if set via CLI)
- Contain `private_key` field (PKCS8 format)
- Contain `client_email` field
- The full JSON object, not just a path

**How to Check:**
1. In Supabase Dashboard → Edge Functions → Secrets
2. View the `FCM_SERVICE_ACCOUNT_JSON` value
3. Verify it's a complete JSON object starting with `{"type":"service_account",...}`

**How to Fix:**
1. Download the service account JSON from Firebase Console:
   - Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file
2. Copy the entire JSON content
3. Set it as the secret (make sure to escape quotes if using CLI)

### 3. Check Edge Function Logs

To see the actual error message:

1. **Via Supabase Dashboard:**
   - Go to Supabase Dashboard → Your Project
   - Navigate to **Edge Functions** → **send-push-notification**
   - Click on **Logs** tab
   - Look for error messages in the most recent invocations

2. **Via Supabase CLI:**
   ```bash
   # This will show recent logs
   supabase functions logs send-push-notification
   ```

### 4. Verify Secrets Are Set Correctly

Run this command to verify your secrets (they won't show the values, just confirm they exist):

```bash
supabase secrets list
```

You should see:
- `FCM_SERVICE_ACCOUNT_JSON` (marked as set)
- `FCM_PROJECT_ID` (marked as set)

### 5. Test the Edge Function Locally

You can test the function locally to see detailed error messages:

```bash
# Start local Supabase (if not already running)
supabase start

# Serve the function locally
supabase functions serve send-push-notification

# In another terminal, test it:
curl -X POST http://localhost:54321/functions/v1/send-push-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-id",
    "title": "Test",
    "body": "Test message"
  }'
```

## Quick Fix Checklist

- [ ] `FCM_SERVICE_ACCOUNT_JSON` secret is set in Supabase
- [ ] `FCM_PROJECT_ID` secret is set in Supabase
- [ ] Service account JSON is valid and complete
- [ ] Service account JSON contains `private_key` field
- [ ] Service account JSON contains `client_email` field
- [ ] Firebase project ID matches the one in service account JSON
- [ ] Edge Function is deployed (run `supabase functions deploy send-push-notification`)

## Next Steps

1. **Check the logs** in Supabase Dashboard to see the exact error message
2. **Verify secrets** are set correctly
3. **Redeploy the function** after fixing secrets:
   ```bash
   supabase functions deploy send-push-notification
   ```
4. **Test again** by creating a task and assigning it to yourself

## Updated Error Handling

The Edge Function has been updated with better error handling that will:
- Check for missing secrets early and return clear error messages
- Validate JSON format before parsing
- Provide detailed error messages for debugging
- Log full error details to Supabase logs

After deploying the updated function, you'll get more specific error messages that will help identify the exact issue.


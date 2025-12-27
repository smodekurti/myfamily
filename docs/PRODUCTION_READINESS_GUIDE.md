# 🚀 Supabase Production Readiness Guide

This guide addresses the 5 critical security recommendations from Supabase to make your app production-ready.

## 📊 Priority Assessment

| Priority | Item | Impact | Effort | Status |
|----------|------|--------|--------|--------|
| 🔴 **CRITICAL** | 1. Enable RLS on all tables | **HIGH** - Security vulnerability | Medium | ⚠️ Needs work |
| 🟠 **HIGH** | 2. Secure Storage Bucket | **HIGH** - Data exposure risk | Low | ⚠️ Needs work |
| 🟡 **MEDIUM** | 3. SSL & Network Restrictions | **MEDIUM** - Best practice | Low | ✅ Dashboard only |
| 🟡 **MEDIUM** | 4. JWT Signing Keys Migration | **MEDIUM** - Security improvement | Low | ✅ Dashboard only |
| 🟢 **LOW** | 5. CAPTCHA & Password Protection | **LOW** - Nice to have | Low | ✅ Dashboard only |

---

## 🔴 Priority 1: Enable Row-Level Security (RLS) on All Tables

### Current Status
- ✅ RLS policies exist in SQL files
- ⚠️ RLS may not be enabled on all tables
- ⚠️ Some policies may need updates for family-based access

### Action Required

#### Step 1: Verify RLS Status
Run this in Supabase SQL Editor to check which tables have RLS enabled:

```sql
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'families', 'family_members', 'tasks', 
    'grocery_lists', 'grocery_list_items', 'calendar_events',
    'announcements', 'grocery_templates', 'task_templates',
    'points_history', 'achievements', 'user_fcm_tokens'
  )
ORDER BY tablename;
```

#### Step 2: Enable RLS on All Tables
Run this script to enable RLS on all user-facing tables:

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
```

#### Step 3: Create Comprehensive RLS Policies
See `PRODUCTION_RLS_POLICIES.sql` (created below) for complete policy definitions.

### Testing Checklist
- [ ] Verify all tables have RLS enabled
- [ ] Test that users can only see their own data
- [ ] Test that family members can see shared family data
- [ ] Test that realtime streams still work with RLS enabled
- [ ] Test that users cannot access other families' data

---

## 🟠 Priority 2: Secure Storage Bucket

### Current Status
- ⚠️ Bucket is **public** (`public: true`)
- ⚠️ Code uses `getPublicUrl()` which requires public access
- ✅ Storage policies exist but may need updates

### Action Required

#### Option A: Keep Public (Recommended for Avatars)
If you want public avatar URLs (simpler, but less secure):

1. **Keep bucket public** but add stricter policies
2. **Update policies** to only allow authenticated users to upload/update/delete
3. **Keep using `getPublicUrl()`** in code

#### Option B: Make Private (More Secure)
If you want private storage with signed URLs:

1. **Change bucket to private** in Supabase Dashboard
2. **Update code** to use `createSignedUrl()` instead of `getPublicUrl()`
3. **Update storage policies** to restrict access

### Implementation: Option B (Private Bucket)

#### Step 1: Update Storage Bucket
In Supabase Dashboard → Storage → `user-content` bucket:
- Change **Public** to **Private**

#### Step 2: Update Storage Policies
Run this SQL:

```sql
-- Drop existing public read policy
DROP POLICY IF EXISTS "Public can view files" ON storage.objects;

-- Create private read policy (only authenticated users)
CREATE POLICY "Authenticated users can view their own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Allow family members to view each other's avatars (optional)
CREATE POLICY "Family members can view avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  EXISTS (
    SELECT 1 FROM family_members fm1
    JOIN family_members fm2 ON fm1.family_id = fm2.family_id
    WHERE fm1.user_id = auth.uid()
    AND fm2.user_id::text = (storage.foldername(name))[2]
  )
);
```

#### Step 3: Update Code
See code changes in `PRODUCTION_STORAGE_CHANGES.md` (created below).

### Testing Checklist
- [ ] Verify bucket is private
- [ ] Test avatar upload works
- [ ] Test avatar display works with signed URLs
- [ ] Test that users cannot access other users' avatars
- [ ] Test signed URL expiration (default 1 hour)

---

## 🟡 Priority 3: SSL & Network Restrictions

### Action Required (Dashboard Only)

1. **Go to**: Supabase Dashboard → Settings → Database
2. **Enable SSL**: Toggle "Require SSL connections" to **ON**
3. **Network Restrictions**: 
   - Go to Settings → Network Restrictions
   - Add your server IPs (if using server-side code)
   - For mobile apps, you can leave this open (Supabase handles it)

### Impact
- ✅ Encrypts all database connections
- ✅ Reduces attack surface
- ⚠️ No code changes needed
- ⚠️ May need to update connection strings if using direct PostgreSQL connections

---

## 🟡 Priority 4: JWT Signing Keys Migration

### Action Required (Dashboard Only)

1. **Go to**: Supabase Dashboard → Settings → API
2. **Check JWT Settings**: 
   - Look for "JWT Secret" (legacy) vs "JWT Signing Keys" (new)
3. **Migrate**:
   - If you see "Migrate to JWT Signing Keys" button, click it
   - Follow the migration wizard
4. **Disable Legacy Verification**:
   - Go to Edge Functions settings
   - Turn OFF "Verify JWT with legacy secret"
5. **Update Edge Functions** (if you have any):
   - Update to use new JWT verification method

### Impact
- ✅ Better security
- ✅ Easier key rotation
- ⚠️ No Flutter app changes needed (Supabase SDK handles it)
- ⚠️ Edge Functions may need updates

---

## 🟢 Priority 5: CAPTCHA & Password Protection

### Action Required (Dashboard Only)

1. **Go to**: Supabase Dashboard → Authentication → Attack Protection
2. **Enable CAPTCHA**:
   - Toggle "CAPTCHA Protection" to **ON**
   - Choose provider: hCaptcha or Cloudflare Turnstile
   - Add your site key and secret
3. **Enable Password Leak Check**:
   - Toggle "Password Leak Check" to **ON**

### Impact
- ✅ Prevents automated attacks
- ✅ Prevents weak password reuse
- ⚠️ May require UI changes for CAPTCHA (if using custom auth UI)
- ⚠️ Supabase Auth UI handles CAPTCHA automatically

### Code Changes (If Using Custom Auth UI)
If you're using Supabase's built-in auth UI, no changes needed. If you have custom auth forms, you may need to add CAPTCHA widgets.

---

## 📝 Implementation Checklist

### Immediate (Before Production)
- [ ] Enable RLS on all tables
- [ ] Verify RLS policies work correctly
- [ ] Secure storage bucket (private + signed URLs)
- [ ] Test all features with RLS enabled

### Before Launch
- [ ] Enable SSL connections
- [ ] Configure network restrictions (if applicable)
- [ ] Migrate to JWT signing keys
- [ ] Disable legacy JWT verification
- [ ] Enable CAPTCHA protection
- [ ] Enable password leak check

### Post-Launch Monitoring
- [ ] Monitor RLS policy performance
- [ ] Monitor signed URL generation (storage)
- [ ] Review authentication logs for attacks
- [ ] Monitor edge function JWT verification

---

## 🧪 Testing Guide

### Test RLS Policies
```sql
-- Test as User A
SET ROLE authenticated;
SET request.jwt.claim.sub = 'user-a-id';
SELECT * FROM tasks WHERE family_id = 'test-family-id';

-- Test as User B (should see same tasks if in same family)
SET request.jwt.claim.sub = 'user-b-id';
SELECT * FROM tasks WHERE family_id = 'test-family-id';
```

### Test Storage Access
1. Upload avatar as User A
2. Try to access avatar URL as User B (should fail if private)
3. Generate signed URL and verify it works
4. Wait 1 hour and verify signed URL expires

---

## 📚 Additional Resources

- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Storage Security](https://supabase.com/docs/guides/storage/security)
- [Supabase JWT Guide](https://supabase.com/docs/guides/auth/jwts)
- [Supabase Attack Protection](https://supabase.com/docs/guides/auth/auth-attack-protection)

---

## ⚠️ Important Notes

1. **RLS is Mandatory**: Supabase considers RLS mandatory for production. Without it, your data is exposed.

2. **Storage Security**: Public buckets are fine for truly public content (like blog images), but user avatars should be private.

3. **Testing**: Always test RLS policies thoroughly. A misconfigured policy can lock users out of their own data.

4. **Performance**: RLS policies add a small overhead. Monitor query performance after enabling.

5. **Backup**: Before making changes, backup your database and test in a staging environment first.



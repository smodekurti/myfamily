# 🔒 Private Storage Bucket Implementation - Complete

This document summarizes the code changes made to support **Option B: Private Bucket with Signed URLs**.

## ✅ What Was Changed

### 1. Created `AvatarUrlService` 
**File**: `lib/app/core/services/avatar_url_service.dart`

- Generates signed URLs for private storage buckets
- Caches signed URLs to avoid frequent regeneration
- Handles both storage paths and full URLs
- Automatically refreshes URLs before expiry (1 hour before 1-year expiry)

### 2. Created `AvatarWidget` 
**File**: `lib/app/common/widgets/avatar_widget.dart`

- Reusable widget for displaying avatars with signed URL support
- Automatically loads signed URLs using `AvatarUrlService`
- Handles loading states and errors gracefully
- Shows fallback initial when no avatar is available

### 3. Updated `EditProfilePage`
**File**: `lib/app/features/profile/presentation/pages/edit_profile_page.dart`

- Changed `_uploadImage()` to return storage path instead of public URL
- Updated avatar display to use `AvatarWidget`
- Now stores storage path (e.g., `avatars/user-id_timestamp.jpg`) in database

### 4. Added Provider
**File**: `lib/app/core/providers/providers.dart`

- Added `avatarUrlServiceProvider` for dependency injection

## 📋 Next Steps (Supabase Dashboard)

### Step 1: Make Storage Bucket Private

1. Go to **Supabase Dashboard** → **Storage** → **Buckets**
2. Click on `user-content` bucket
3. Toggle **Public** to **Private** (or uncheck the public checkbox)
4. Click **Save**

### Step 2: Update Storage Policies

Run this SQL in Supabase SQL Editor:

```sql
-- Drop existing public read policy
DROP POLICY IF EXISTS "Public can view files" ON storage.objects;
DROP POLICY IF EXISTS "Public read access" ON storage.objects;

-- Create private read policy (only authenticated users can view their own avatars)
CREATE POLICY "Authenticated users can view their own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Allow family members to view each other's avatars
CREATE POLICY "Family members can view avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  (
    -- Own avatar
    auth.uid()::text = (storage.foldername(name))[2]
    OR
    -- Family member's avatar
    EXISTS (
      SELECT 1 FROM family_members fm1
      JOIN family_members fm2 ON fm1.family_id = fm2.family_id
      WHERE fm1.user_id = auth.uid()
      AND fm2.user_id::text = (storage.foldername(name))[2]
    )
  )
);
```

### Step 3: Verify Existing Policies

Ensure these policies still exist (for upload/update/delete):

```sql
-- Users can upload their own files
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Users can update their own files
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
)
WITH CHECK (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Users can delete their own files
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[2]
);
```

## 🔄 Migration Notes

### Database Migration

**Important**: Existing avatar URLs in the database may be full public URLs. The `AvatarUrlService` handles this by:

1. Detecting if the stored value is a full URL
2. If it's a Supabase public URL, extracting the path and generating a signed URL
3. If it's already a signed URL or external URL, using it as-is

**No database migration needed** - the service handles both old and new formats.

### Code Migration

All avatar displays should eventually use `AvatarWidget` for consistency. Current implementation:

- ✅ `EditProfilePage` - Uses `AvatarWidget`
- ⚠️ Other pages - Still use `CircleAvatar` with `NetworkImage` directly

**Recommended**: Gradually migrate other pages to use `AvatarWidget` for consistency and automatic signed URL support.

## 🧪 Testing Checklist

- [ ] Make bucket private in Supabase Dashboard
- [ ] Run storage policy SQL
- [ ] Test avatar upload (should work)
- [ ] Test avatar display (should show signed URL)
- [ ] Test avatar display for family members (should work with policy)
- [ ] Test avatar display for non-family members (should fail gracefully)
- [ ] Verify signed URLs expire after 1 year
- [ ] Verify cache refreshes before expiry

## 📝 Usage Examples

### Using AvatarWidget

```dart
// Simple usage
AvatarWidget(
  avatarPath: user.avatarUrl, // Storage path or URL
  radius: 30,
  displayName: user.displayName,
)

// With custom styling
AvatarWidget(
  avatarPath: member.photoURL,
  radius: 40,
  displayName: member.displayName,
  backgroundColor: Colors.blue,
  textColor: Colors.white,
  showBorder: true,
  borderColor: Colors.grey,
)
```

### Using AvatarUrlService Directly

```dart
final avatarService = ref.read(avatarUrlServiceProvider);
final signedUrl = await avatarService.getAvatarUrl('avatars/user-id.jpg');
if (signedUrl != null) {
  Image.network(signedUrl);
}
```

## ⚠️ Important Notes

1. **Signed URLs expire**: URLs are valid for 1 year, but the service refreshes them 1 hour before expiry
2. **Caching**: URLs are cached in memory to avoid frequent regeneration
3. **Backward compatibility**: The service handles both old public URLs and new storage paths
4. **Performance**: Signed URL generation is async, so `AvatarWidget` shows a loading indicator initially

## 🔍 Troubleshooting

### Avatars not showing
- Check if bucket is set to private
- Verify storage policies are correct
- Check browser console for signed URL generation errors

### "Bucket not found" error
- Verify bucket name is `user-content`
- Check bucket exists in Supabase Dashboard

### "Permission denied" error
- Verify storage policies allow authenticated users to read
- Check if user is authenticated
- Verify file path matches policy pattern (`avatars/user-id_filename.jpg`)



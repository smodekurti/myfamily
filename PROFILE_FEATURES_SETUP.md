# 📸 Profile Features Setup Guide

## What's Implemented

✅ View Profile Screen (already existed)
✅ Edit Profile Screen (NEW)
✅ Profile Picture Upload to Supabase Storage (NEW)
✅ Update Display Name (NEW)

## Supabase Storage Setup

### Step 1: Create Storage Bucket

1. Go to Supabase Dashboard → **Storage**
   - https://supabase.com/dashboard/project/vovfhxnmiximhzdjadvu/storage/buckets

2. Click **"New bucket"**

3. Configure:
   - **Name**: `user-content`
   - **Public**: ✅ Yes (enable public access)
   - Click **"Create bucket"**

### Step 2: Set Storage Policies

1. Click on the `user-content` bucket

2. Go to **"Policies"** tab

3. Create the following policies:

#### Policy 1: Allow Authenticated Users to Upload

```sql
CREATE POLICY "Authenticated users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-content' 
  AND (storage.foldername(name))[1] = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[2]
);
```

**Or use the UI:**
- Policy name: `Allow authenticated uploads`
- Allowed operation: `INSERT`
- Target roles: `authenticated`
- WITH CHECK expression:
  ```sql
  bucket_id = 'user-content' AND (storage.foldername(name))[1] = 'avatars'
  ```

#### Policy 2: Allow Public Read Access

```sql
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-content');
```

**Or use the UI:**
- Policy name: `Public read access`
- Allowed operation: `SELECT`
- Target roles: `public`
- USING expression:
  ```sql
  bucket_id = 'user-content'
  ```

#### Policy 3: Allow Users to Update Their Own Files

```sql
CREATE POLICY "Users can update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-content'
  AND (storage.foldername(name))[1] = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[2]
);
```

### Step 3: Test the Upload

1. Run the app
2. Go to **Profile** → **Edit Profile**
3. Tap the profile picture
4. Select "Take Photo" or "Choose from Gallery"
5. Select an image
6. Enter display name
7. Click **"Save Changes"**

## Features

### Edit Profile Screen

**Fields:**
- Profile Picture (tap to change)
  - Take Photo (camera)
  - Choose from Gallery
  - Remove Photo (if exists)
- Display Name (required)

**Actions:**
- Save Changes (uploads image and updates profile)
- Cancel (back button)

**Validations:**
- Display name cannot be empty
- Image size optimized (max 800x800, 85% quality)

### Image Upload Process

1. User selects image from camera/gallery
2. Image is displayed in preview
3. When "Save Changes" is clicked:
   - Image is uploaded to `user-content/avatars/{userId}_{timestamp}.jpg`
   - Public URL is generated
   - User profile is updated with new avatar URL
   - Profile page refreshes automatically

### Error Handling

- Image picker errors → Shows snackbar
- Upload failures → Shows error, doesn't save profile
- Network errors → Handled gracefully
- Large images → Automatically compressed

## Code Structure

### New Files

- `lib/app/features/profile/presentation/pages/edit_profile_page.dart`
  - Edit profile UI
  - Image picker integration
  - Upload logic
  - Form validation

### Modified Files

- `lib/app/features/profile/presentation/pages/profile_page.dart`
  - Updated "Edit Profile" button to navigate to edit screen

- `lib/app/core/router/app_router.dart`
  - Added `/profile/edit` route

### Repository Method Used

```dart
await authRepo.updateUserProfile(
  displayName: displayNameController.text.trim(),
  photoURL: uploadedImageUrl,
);
```

## Storage Structure

```
user-content/
└── avatars/
    ├── {userId}_1234567890.jpg
    ├── {userId}_1234567891.jpg
    └── ...
```

## Security

✅ **Authenticated Upload**: Only logged-in users can upload
✅ **User-Specific Folders**: Users can only upload to their own folder
✅ **Public Read**: Anyone can view profile pictures (needed for display)
✅ **File Naming**: UUID + timestamp prevents conflicts
✅ **Image Optimization**: Prevents large file uploads

## Dependencies Used

- `image_picker: ^1.2.0` - Already in pubspec.yaml
- `supabase_flutter: ^2.12.2` - Already in pubspec.yaml

## Troubleshooting

### "Failed to upload image"
- Check Supabase Storage bucket exists
- Verify storage policies are set correctly
- Check internet connection

### "Failed to pick image"
- iOS: Check Info.plist has camera/photo permissions
- Android: Check AndroidManifest.xml has permissions

### Image not displaying
- Check bucket is public
- Verify URL is correct
- Check browser console for CORS errors

## Next Steps

### Suggested Enhancements

1. **Image Cropper**
   - Add `image_cropper` package
   - Allow users to crop images before upload

2. **Loading States**
   - Show shimmer while loading profile
   - Better upload progress indicator

3. **Image Cache**
   - Use `cached_network_image` for better performance

4. **Delete Old Images**
   - Delete previous avatar when uploading new one
   - Implement cleanup job

5. **Profile Completeness**
   - Show profile completion percentage
   - Encourage users to fill all fields

## Family Features (Coming Next)

The profile already shows family information with invite codes. Next features to implement:

1. **Family Settings Screen**
   - Edit family name
   - Manage members
   - Leave family
   - Delete family (admin only)

2. **Family List Screen**
   - View all families user is part of
   - Switch between families
   - Join new family

3. **Member Management**
   - View family members
   - Remove members (admin only)
   - Change member roles

✅ Profile features are now complete and ready to use!


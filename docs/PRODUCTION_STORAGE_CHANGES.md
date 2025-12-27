# 🔒 Storage Bucket Security - Code Changes

This document outlines the code changes needed to switch from public to private storage bucket with signed URLs.

## Current Implementation (Public Bucket)

```dart
// lib/app/features/profile/presentation/pages/edit_profile_page.dart
final publicUrl = storage.getPublicUrl(filePath);
```

## New Implementation (Private Bucket with Signed URLs)

### Step 1: Update Avatar Upload Method

Replace the `_uploadImage` method in `edit_profile_page.dart`:

```dart
Future<String?> _uploadImage(File imageFile) async {
  try {
    setState(() => _isUploadingImage = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Create unique file path
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = 'avatars/$fileName';

    // Upload to Supabase Storage
    final storage = Supabase.instance.client.storage.from('user-content');
    
    // Check if bucket exists, if not show helpful error
    try {
      await storage.upload(filePath, imageFile, fileOptions: const FileOptions(upsert: true));
    } catch (e) {
      if (e.toString().contains('Bucket not found')) {
        throw Exception(
          'Storage bucket not found. Please run the setup_storage_buckets.sql migration in your Supabase SQL Editor.'
        );
      }
      rethrow;
    }

    // Get signed URL (valid for 1 hour by default, can be extended)
    // For avatars, we'll generate a long-lived signed URL (1 year)
    final signedUrl = await storage.createSignedUrl(
      filePath,
      31536000, // 1 year in seconds (365 * 24 * 60 * 60)
    );

    return signedUrl;
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    return null;
  } finally {
    if (mounted) {
      setState(() => _isUploadingImage = false);
    }
  }
}
```

### Step 2: Create Avatar URL Helper Service

Create a new service to manage avatar URLs with caching and automatic refresh:

```dart
// lib/app/core/services/avatar_url_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class AvatarUrlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  
  // Cache signed URLs to avoid regenerating on every access
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlExpiry = {};
  
  static const int _urlValiditySeconds = 31536000; // 1 year
  
  /// Get signed URL for an avatar
  /// If the URL is cached and not expired, returns cached URL
  /// Otherwise, generates a new signed URL
  Future<String?> getAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    
    // Check cache
    if (_urlCache.containsKey(avatarPath)) {
      final expiry = _urlExpiry[avatarPath];
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        return _urlCache[avatarPath];
      }
    }
    
    try {
      final storage = _supabase.storage.from('user-content');
      final signedUrl = await storage.createSignedUrl(
        avatarPath,
        _urlValiditySeconds,
      );
      
      // Cache the URL
      _urlCache[avatarPath] = signedUrl;
      _urlExpiry[avatarPath] = DateTime.now().add(
        Duration(seconds: _urlValiditySeconds - 3600), // Refresh 1 hour before expiry
      );
      
      return signedUrl;
    } catch (e, stackTrace) {
      _logger.e('Error generating signed URL for avatar: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Clear cache for a specific avatar path
  void clearCache(String avatarPath) {
    _urlCache.remove(avatarPath);
    _urlExpiry.remove(avatarPath);
  }
  
  /// Clear all cached URLs
  void clearAllCache() {
    _urlCache.clear();
    _urlExpiry.clear();
  }
}
```

### Step 3: Update Profile Display to Use Signed URLs

Update any widgets that display avatars to use the new service:

```dart
// Example: In user profile widget
final avatarUrlService = AvatarUrlService();
final avatarUrl = await avatarUrlService.getAvatarUrl(user.avatarUrl);

if (avatarUrl != null) {
  Image.network(avatarUrl)
} else {
  // Fallback to default avatar
}
```

### Step 4: Update User Model/Repository

If you store avatar URLs in the database, you may want to store just the path (not the full signed URL):

```dart
// Store: 'avatars/user-id_timestamp.jpg'
// Generate signed URL on-demand when displaying
```

## Alternative: Keep Public Bucket but Restrict Access

If you prefer to keep the bucket public but add stricter policies:

### Update Storage Policies

```sql
-- Remove public read access
DROP POLICY IF EXISTS "Public can view files" ON storage.objects;

-- Only authenticated users can read
CREATE POLICY "Authenticated users can view avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-content' AND
  (storage.foldername(name))[1] = 'avatars'
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

### Keep Using getPublicUrl()

No code changes needed, but the bucket should remain public.

## Recommendation

**Use Private Bucket with Signed URLs** because:
- ✅ Better security (URLs expire)
- ✅ More control over access
- ✅ Can revoke access by not regenerating URLs
- ⚠️ Slightly more complex (caching needed)
- ⚠️ URLs expire (need refresh logic)

**Keep Public Bucket** only if:
- ✅ You need truly public avatars (e.g., for sharing)
- ✅ You want simpler implementation
- ⚠️ Less secure (anyone with URL can access)
- ⚠️ Cannot revoke access without changing file path

## Testing Checklist

- [ ] Upload avatar works
- [ ] Avatar displays correctly with signed URL
- [ ] Signed URL expires after set time
- [ ] Cache refreshes before expiry
- [ ] Users cannot access other users' avatars
- [ ] Family members can see each other's avatars (if policy allows)



# Avatar Storage Issue - Complete Fix Summary

## Problem
The app is crashing with: `Invalid argument(s): No host specified in URI file:///avatars/...`

## Root Cause
Multiple files are using `NetworkImage` directly with storage paths instead of using the `AvatarWidget` component that generates signed URLs.

## Why This Happens
1. Profile pictures are stored in Supabase private storage as paths: `avatars/{userId}/{timestamp}.jpg`
2. These paths need to be converted to signed URLs before displaying
3. Many components bypass `AvatarWidget` and use `NetworkImage` directly
4. `NetworkImage` expects HTTP/HTTPS URLs, not storage paths

## Solution Overview
Replace ALL direct `NetworkImage` usage with `AvatarWidget` component.

## Files That Need Fixing

### ✅ Already Fixed:
- `lib/app/features/profile/presentation/pages/profile_page.dart`
- `lib/app/common/widgets/avatar_widget.dart` (has validation)

### ❌ Still Need Fixing:
1. **lib/app/features/tasks/presentation/pages/tasks_page.dart** (5 instances)
   - Lines: 845, 871, 897, 1296, 1472

2. **lib/app/features/calendar/presentation/pages/calendar_page.dart** (2 instances)
   - Lines: 335, 877

3. **lib/app/features/family/presentation/pages/family_settings_page.dart** (1 instance)
   - Line: 536

4. **lib/app/features/gamification/presentation/pages/leaderboard_page.dart** (1 instance)
   - Line: 231

5. **lib/app/features/tasks/presentation/pages/edit_task_page.dart** (3 instances)
   - Lines: 549, 605, 672

6. **lib/app/features/tasks/presentation/pages/create_task_page.dart** (3 instances)
   - Lines: 911, 978, 1058

## How to Fix Each Instance

### Pattern to Replace:
```dart
// OLD - Direct NetworkImage usage
CircleAvatar(
  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
  child: photoUrl == null ? Icon(...) : null,
)
```

### Replace With:
```dart
// NEW - Use AvatarWidget
AvatarWidget(
  avatarPath: photoUrl,
  radius: 20, // adjust as needed
  displayName: displayName, // for fallback initials
)
```

## Steps to Complete Fix

1. **Add AvatarWidget import** to each file:
   ```dart
   import '../../../../common/widgets/avatar_widget.dart';
   ```

2. **Replace each CircleAvatar** that uses NetworkImage with AvatarWidget

3. **Test the app** - do a FULL RESTART (not hot reload)

4. **Verify** no more `file:///` errors in console

## Alternative Quick Fix (Temporary)

If you need a quick temporary fix, you can modify the avatar URLs at the source to always return full HTTP URLs instead of storage paths. However, this is NOT recommended as it bypasses the signed URL security.

## Supabase Storage Configuration

Ensure these are set up in Supabase:
1. **Storage bucket** `user-content` exists and is set to PRIVATE
2. **RLS policies** are configured (run `setup_storage_buckets_private.sql`)
3. **Path structure** matches: `avatars/{userId}/{filename}.jpg`

## Testing After Fix

1. Stop the app completely
2. Run `flutter clean` (optional but recommended)
3. Run `flutter run`
4. Upload a new profile picture
5. Navigate to different screens
6. Verify no crashes and avatars display correctly

## Why Hot Reload Doesn't Work

Widget state and image caching mean hot reload won't pick up these changes. Always do a full restart when fixing image loading issues.


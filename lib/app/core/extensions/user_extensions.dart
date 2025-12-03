import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../services/avatar_url_service.dart';

/// Extensions for Supabase Auth [User] to provide convenient accessors
extension SupabaseUserExtensions on User {
  /// Get user's display name or email fallback
  String? get displayNameOrEmail {
    // Try to get display name from user metadata
    final displayName = userMetadata?['display_name'] as String? ?? 
                       userMetadata?['name'] as String?;
    return displayName ?? email?.split('@').first;
  }

  /// Get user's photo URL (cleaned to remove file:// prefixes)
  /// Note: For storage paths, use AvatarWidget or AvatarUrlService.getAvatarUrl()
  /// to get signed URLs. This getter only returns the cleaned path/URL.
  String? get avatarUrl {
    final rawUrl = userMetadata?['avatar_url'] as String? ?? 
                   userMetadata?['picture'] as String?;
    // Clean any file:// prefixes that might have been incorrectly stored
    return AvatarUrlService.cleanAvatarPath(rawUrl);
  }
}


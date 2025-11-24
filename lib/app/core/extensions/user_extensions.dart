import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Extensions for Supabase Auth [User] to provide convenient accessors
extension SupabaseUserExtensions on User {
  /// Get user's display name or email fallback
  String? get displayNameOrEmail {
    // Try to get display name from user metadata
    final displayName = userMetadata?['display_name'] as String? ?? 
                       userMetadata?['name'] as String?;
    return displayName ?? email?.split('@').first;
  }

  /// Get user's photo URL
  String? get avatarUrl {
    return userMetadata?['avatar_url'] as String? ?? 
           userMetadata?['picture'] as String?;
  }
}


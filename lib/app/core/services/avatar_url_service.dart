import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Service for managing avatar URLs with signed URL generation and caching
/// Supports private storage buckets by generating signed URLs on-demand
class AvatarUrlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  
  // Cache signed URLs to avoid regenerating on every access
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlExpiry = {};
  
  /// URL validity duration: 1 year (31536000 seconds)
  /// This is long enough to avoid frequent regeneration but still allows revocation
  static const int _urlValiditySeconds = 31536000; // 1 year
  
  /// Get signed URL for an avatar
  /// If the URL is cached and not expired, returns cached URL
  /// Otherwise, generates a new signed URL
  /// 
  /// [avatarPath] should be the storage path (e.g., 'avatars/user-id_timestamp.jpg')
  /// or a full URL (in which case it's returned as-is if it's already a signed URL)
  Future<String?> getAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    
    // If it's already a full URL (not a storage path), return as-is
    // This handles cases where old public URLs might still be in the database
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      // Check if it's a Supabase public URL - if so, we need to convert to signed URL
      if (avatarPath.contains('/storage/v1/object/public/')) {
        // Extract the path from the public URL
        final uri = Uri.parse(avatarPath);
        final pathParts = uri.path.split('/storage/v1/object/public/');
        if (pathParts.length > 1) {
          final bucketAndPath = pathParts[1];
          final parts = bucketAndPath.split('/');
          if (parts.length >= 2) {
            final bucket = parts[0];
            final path = parts.sublist(1).join('/');
            return await _generateSignedUrl(bucket, path);
          }
        }
      }
      // If it's already a signed URL or external URL, return as-is
      return avatarPath;
    }
    
    // It's a storage path, generate signed URL
    return await _generateSignedUrl('user-content', avatarPath);
  }
  
  /// Generate a signed URL for a storage path
  Future<String?> _generateSignedUrl(String bucket, String path) async {
    // Check cache first
    final cacheKey = '$bucket/$path';
    if (_urlCache.containsKey(cacheKey)) {
      final expiry = _urlExpiry[cacheKey];
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        return _urlCache[cacheKey];
      }
    }
    
    try {
      final storage = _supabase.storage.from(bucket);
      final signedUrl = await storage.createSignedUrl(
        path,
        _urlValiditySeconds,
      );
      
      // Cache the URL
      _urlCache[cacheKey] = signedUrl;
      _urlExpiry[cacheKey] = DateTime.now().add(
        Duration(seconds: _urlValiditySeconds - 3600), // Refresh 1 hour before expiry
      );
      
      return signedUrl;
    } catch (e, stackTrace) {
      _logger.e('Error generating signed URL for avatar: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Clear cache for a specific avatar path
  void clearCache(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return;
    
    // Try to find the cache key
    for (final key in _urlCache.keys.toList()) {
      if (key.contains(avatarPath) || avatarPath.contains(key)) {
        _urlCache.remove(key);
        _urlExpiry.remove(key);
      }
    }
  }
  
  /// Clear all cached URLs
  void clearAllCache() {
    _urlCache.clear();
    _urlExpiry.clear();
  }
  
  /// Preload avatar URLs for a list of users
  /// Useful for preloading avatars before displaying them
  Future<void> preloadAvatarUrls(List<String?> avatarPaths) async {
    for (final path in avatarPaths) {
      if (path != null && path.isNotEmpty) {
        await getAvatarUrl(path);
      }
    }
  }
}


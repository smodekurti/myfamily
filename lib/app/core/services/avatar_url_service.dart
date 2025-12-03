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
  /// [avatarPath] should be the storage path (e.g., 'avatars/user-id/timestamp.jpg')
  /// or a full URL (in which case it's returned as-is if it's already a signed URL)
  Future<String?> getAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    
    // Clean up the path - remove any file:// prefix that might have been incorrectly added
    String cleanPath = avatarPath;
    if (cleanPath.startsWith('file://')) {
      _logger.w('Avatar path has incorrect file:// prefix, removing it: $avatarPath');
      cleanPath = cleanPath.replaceFirst('file://', '');
      // Remove leading slashes
      cleanPath = cleanPath.replaceFirst(RegExp(r'^/+'), '');
    }
    
    // If it's already a full URL (not a storage path), return as-is
    // This handles cases where old public URLs might still be in the database
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      // Check if it's a Supabase public URL - if so, we need to convert to signed URL
      if (cleanPath.contains('/storage/v1/object/public/')) {
        // Extract the path from the public URL
        final uri = Uri.parse(cleanPath);
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
      return cleanPath;
    }
    
    // Remove leading slash if present (storage paths shouldn't start with /)
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    // It's a storage path, generate signed URL
    return await _generateSignedUrl('user-content', cleanPath);
  }
  
  /// Generate a signed URL for a storage path
  Future<String?> _generateSignedUrl(String bucket, String path) async {
    _logger.i('Generating signed URL for: $bucket/$path');
    
    // Check cache first
    final cacheKey = '$bucket/$path';
    if (_urlCache.containsKey(cacheKey)) {
      final expiry = _urlExpiry[cacheKey];
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        _logger.i('Using cached URL for: $cacheKey');
        return _urlCache[cacheKey];
      }
    }
    
    try {
      final storage = _supabase.storage.from(bucket);
      _logger.i('Calling createSignedUrl for path: $path');
      final signedUrl = await storage.createSignedUrl(
        path,
        _urlValiditySeconds,
      );
      
      _logger.i('Generated signed URL: $signedUrl');
      
      // Validate the signed URL
      if (!signedUrl.startsWith('http://') && !signedUrl.startsWith('https://')) {
        _logger.e('Invalid signed URL generated (not HTTP/HTTPS): $signedUrl');
        return null;
      }
      
      // Cache the URL
      _urlCache[cacheKey] = signedUrl;
      _urlExpiry[cacheKey] = DateTime.now().add(
        Duration(seconds: _urlValiditySeconds - 3600), // Refresh 1 hour before expiry
      );
      
      return signedUrl;
    } catch (e, stackTrace) {
      _logger.e('Error generating signed URL for avatar: $e', error: e, stackTrace: stackTrace);
      _logger.e('Bucket: $bucket, Path: $path');
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



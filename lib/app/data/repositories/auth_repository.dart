import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../../core/services/avatar_url_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  // Lazy initialize GoogleSignIn to avoid early crashes
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
    );
    return _googleSignInInstance!;
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createOrUpdateUserProfile(response.user!);
      }

      return response;
    } on AuthException catch (e) {
      _logger.e('Email sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Email sign in error: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<AuthResponse?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      // Try to create profile, but don't fail the sign-up if it fails
      if (response.user != null) {
        // Don't await - let it run in background
        _createOrUpdateUserProfile(response.user!);
      }

      return response;
    } on AuthException catch (e) {
      _logger.e('Email sign up error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Email sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with Google using native Google Sign-In SDK
  /// This provides a native UI experience on both iOS and Android
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Initialize and sign in with native Google Sign-In SDK
      final googleUser = await _googleSignIn.signIn().catchError((error) {
        _logger.e('GoogleSignIn.signIn() error: $error');
        throw Exception('Failed to open Google Sign-In: $error');
      });

      if (googleUser == null) {
        _logger.w('Google sign in cancelled by user');
        return null;
      }

      // Get the authentication details
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      // Sign in to Supabase with the Google ID token
      // Note: For native iOS/Android sign-in, "Skip nonce checks" must be enabled in Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );


      if (response.user != null) {
        await _createOrUpdateUserProfile(response.user!);
      }

      return response;
    } catch (e, stackTrace) {
      _logger.e('=== Google Sign-In Failed ===');
      _logger.e('Error: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<AuthResponse?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: appleCredential.identityToken!,
      );

      if (response.user != null) {
        await _createOrUpdateUserProfile(response.user!);
      }

      return response;
    } catch (e) {
      _logger.e('Apple sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      _logger.e('Sign out error: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      _logger.e('Password reset error: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Password reset error: $e');
      rethrow;
    }
  }

  /// Update user profile
  /// Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Merge with existing metadata
      final currentMetadata = user.userMetadata ?? {};
      final updatedMetadata = {...currentMetadata, ...metadata};

      await _supabase.auth.updateUser(UserAttributes(data: updatedMetadata));

    } catch (e) {
      _logger.e('Update user metadata error: $e');
      rethrow;
    }
  }

  /// Get user's accepted consent version
  String? getUserConsentVersion() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata;
    return metadata?['consent_version'] as String?;
  }

  /// Check if user has completed walkthrough
  bool hasCompletedWalkthrough() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final metadata = user.userMetadata;
    return metadata?['walkthrough_completed'] == true;
  }

  Future<UserResponse> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      // Clean avatar URL to remove any file:// prefixes before storing
      if (photoURL != null) {
        final cleanedUrl = AvatarUrlService.cleanAvatarPath(photoURL);
        if (cleanedUrl != null) {
          updates['avatar_url'] = cleanedUrl;
        }
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      // Directly update the users table with the provided values
      // This ensures the database is updated immediately
      final dbUpdates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) dbUpdates['display_name'] = displayName;
      // Clean avatar URL to remove any file:// prefixes before storing
      if (photoURL != null) {
        final cleanedUrl = AvatarUrlService.cleanAvatarPath(photoURL);
        if (cleanedUrl != null) {
          dbUpdates['avatar_url'] = cleanedUrl;
        }
      }

      if (dbUpdates.isNotEmpty) {
        try {
          await _supabase.from('users').update(dbUpdates).eq('id', user.id);
        } catch (e) {
          _logger.e('Error updating user in database: $e');
          // Still try the metadata approach as fallback
          if (response.user != null) {
            await _createOrUpdateUserProfile(response.user!);
          }
        }
      }

      return response;
    } catch (e) {
      _logger.e('Update profile error: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Delete user data from database
      await _supabase.from('users').delete().eq('id', user.id);

      // Note: Supabase doesn't have a direct delete account method
      // You need to implement this on the backend or use RLS policies
      _logger.w('Account deletion requested for user: ${user.id}');
    } catch (e) {
      _logger.e('Delete account error: $e');
      rethrow;
    }
  }

  /// Create or update user profile in database
  Future<void> _createOrUpdateUserProfile(User user) async {
    try {
      // Wait a bit to ensure the user is fully authenticated
      await Future.delayed(const Duration(milliseconds: 500));

      final userModel = UserModel(
        uid: user.id,
        email: user.email ?? '',
        displayName:
            user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email?.split('@')[0] ??
            'User',
        photoURL:
            user.userMetadata?['avatar_url'] as String? ??
            user.userMetadata?['picture'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Try to insert first, then update if it fails
      try {
        await _supabase.from('users').insert(userModel.toSupabase());
      } catch (insertError) {
        // If insert fails (user already exists), try update
        _logger.w('Insert failed, trying update: $insertError');
        await _supabase
            .from('users')
            .update(userModel.toSupabase())
            .eq('id', user.id);
      }
    } catch (e) {
      _logger.e('Create/update user profile error: $e');
      // Don't rethrow - let the auth flow continue even if profile creation fails
      // The user can still use the app and we can retry profile creation later
    }
  }

  /// Get user profile from database
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;

      return UserModelSupabase.fromSupabase(response);
    } catch (e) {
      _logger.e('Get user profile error: $e');
      return null;
    }
  }

  /// Stream user profile from database
  Stream<UserModel?> streamUserProfile(String uid) {
    return _supabase.from('users').stream(primaryKey: ['id']).eq('id', uid).map(
      (data) {
        if (data.isEmpty) return null;
        return UserModelSupabase.fromSupabase(data.first);
      },
    );
  }

  /// Check if user exists
  Future<bool> userExists(String email) async {
    try {
      // Supabase doesn't provide a direct way to check if user exists
      // This is a workaround - in production, implement a backend endpoint
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.e('Check user exists error: $e');
      return false;
    }
  }

  /// Update user preferences (theme, notifications, etc.)
  Future<void> updateUserPreferences({
    String? themePreference,
    bool? notificationsEnabled,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (themePreference != null) {
        updates['theme_preference'] = themePreference;
      }

      if (notificationsEnabled != null) {
        updates['notifications_enabled'] = notificationsEnabled;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', user.id);
      }
    } catch (e) {
      _logger.e('Update user preferences error: $e');
      rethrow;
    }
  }
}

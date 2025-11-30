import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Service for handling biometric authentication (Face ID / Touch ID)
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  /// Check if biometric authentication is available on the device
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) {
      return false; // Only support iOS for now
    }

    try {
      // Check if device is supported (may fail if plugin not ready)
      final isDeviceSupported = await _localAuth.isDeviceSupported().catchError((e) {
        _logger.w('Device support check failed (plugin may not be ready): $e');
        return false;
      });
      
      if (!isDeviceSupported) {
        return false;
      }
      
      // Check if biometrics can be checked
      final canCheckBiometrics = await _localAuth.canCheckBiometrics.catchError((e) {
        _logger.w('Can check biometrics failed (plugin may not be ready): $e');
        return false;
      });
      
      final isAvailable = isDeviceSupported && canCheckBiometrics;
      
      _logger.i('Biometric availability: supported=$isDeviceSupported, canCheck=$canCheckBiometrics, available=$isAvailable');
      return isAvailable;
    } catch (e, stackTrace) {
      _logger.e('Error checking biometric availability: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics().catchError((e) {
        _logger.w('Error getting available biometrics (plugin may not be ready): $e');
        return <BiometricType>[];
      });
    } catch (e) {
      _logger.e('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if Face ID is available
  Future<bool> isFaceIdAvailable() async {
    if (!Platform.isIOS) return false;
    
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } catch (e) {
      _logger.e('Error checking Face ID availability: $e');
      return false;
    }
  }

  /// Check if Touch ID is available
  Future<bool> isTouchIdAvailable() async {
    if (!Platform.isIOS) return false;
    
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      _logger.e('Error checking Touch ID availability: $e');
      return false;
    }
  }

  /// Get the biometric type name for display
  Future<String> getBiometricTypeName() async {
    try {
      if (await isFaceIdAvailable()) {
        return 'Face ID';
      } else if (await isTouchIdAvailable()) {
        return 'Touch ID';
      }
      return 'Biometric';
    } catch (e) {
      _logger.w('Error getting biometric type name: $e');
      return 'Face ID'; // Default to Face ID
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication succeeds, false otherwise
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }

      final biometricType = await getBiometricTypeName();
      final localizedReason = reason.replaceAll('authenticate', biometricType.toLowerCase());

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only use biometrics, not device passcode
        ),
      ).catchError((e) {
        _logger.e('Biometric authentication failed: $e');
        return false;
      });

      if (didAuthenticate) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger.w('Biometric authentication failed or cancelled');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication platform error: ${e.code} - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      _logger.e('Biometric authentication error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Save credentials securely for biometric login
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: 'biometric_email', value: email).catchError((e) {
        _logger.e('Error saving email: $e');
        throw Exception('Failed to save credentials: $e');
      });
      await _secureStorage.write(key: 'biometric_password', value: password).catchError((e) {
        _logger.e('Error saving password: $e');
        throw Exception('Failed to save credentials: $e');
      });
      await _secureStorage.write(key: 'biometric_enabled', value: 'true').catchError((e) {
        _logger.e('Error saving enabled flag: $e');
        throw Exception('Failed to save credentials: $e');
      });
      _logger.i('Credentials saved securely for biometric login');
    } catch (e, stackTrace) {
      _logger.e('Error saving credentials: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'biometric_email').catchError((e) {
        _logger.w('Error reading email (plugin may not be ready): $e');
        return null;
      });
      final password = await _secureStorage.read(key: 'biometric_password').catchError((e) {
        _logger.w('Error reading password (plugin may not be ready): $e');
        return null;
      });
      
      if (email != null && password != null) {
        return {
          'email': email,
          'password': password,
        };
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Error reading saved credentials: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: 'biometric_enabled').catchError((e) {
        _logger.w('Error reading biometric_enabled (plugin may not be ready): $e');
        return null;
      });
      return enabled == 'true';
    } catch (e) {
      _logger.e('Error checking biometric login status: $e');
      return false;
    }
  }

  /// Enable biometric login
  Future<void> enableBiometricLogin() async {
    try {
      await _secureStorage.write(key: 'biometric_enabled', value: 'true').catchError((e) {
        _logger.e('Error enabling biometric login: $e');
        throw Exception('Failed to enable biometric login: $e');
      });
      _logger.i('Biometric login enabled');
    } catch (e, stackTrace) {
      _logger.e('Error enabling biometric login: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Disable biometric login and clear saved credentials
  Future<void> disableBiometricLogin() async {
    try {
      await _secureStorage.delete(key: 'biometric_enabled').catchError((e) {
        _logger.w('Error deleting enabled flag: $e');
      });
      await _secureStorage.delete(key: 'biometric_email').catchError((e) {
        _logger.w('Error deleting email: $e');
      });
      await _secureStorage.delete(key: 'biometric_password').catchError((e) {
        _logger.w('Error deleting password: $e');
      });
      _logger.i('Biometric login disabled and credentials cleared');
    } catch (e, stackTrace) {
      _logger.e('Error disabling biometric login: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - allow graceful degradation
    }
  }

  /// Clear all saved credentials
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: 'biometric_email').catchError((e) {
        _logger.w('Error deleting email: $e');
      });
      await _secureStorage.delete(key: 'biometric_password').catchError((e) {
        _logger.w('Error deleting password: $e');
      });
      _logger.i('Credentials cleared');
    } catch (e, stackTrace) {
      _logger.e('Error clearing credentials: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - allow graceful degradation
    }
  }
}

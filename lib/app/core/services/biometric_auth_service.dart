import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _keyEmail = 'biometric_email';
  static const _keyPassword = 'biometric_password';
  static const _keyEnabled = 'biometric_enabled';

  Future<bool> get isDeviceSupported async {
    try {
      return await auth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isAvailable() async {
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<String> getBiometricTypeName() async {
    try {
      final biometrics = await auth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Touch ID';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris Scanner';
      }
    } catch (_) {}
    return 'Biometrics';
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Re-auth if app moved to background
          biometricOnly: false, // Allow PIN/Pattern fallback
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        // Biometrics not available
        return false;
      } else if (e.code == auth_error.notEnrolled) {
        // User has not enrolled biometrics
        return false;
      } else {
        // Other error
        return false;
      }
    }
  }

  // Persistence for Login
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final enabled = await _storage.read(key: _keyEnabled);
    if (enabled != 'true') return null;

    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<bool> isBiometricLoginEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  Future<void> disableBiometricLogin() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }
}

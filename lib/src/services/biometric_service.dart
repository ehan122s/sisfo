import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyEmail = 'biometric_email';
  static const String _keyPassword =
      'biometric_password'; // Caution: storing password

  /// Check if biometrics are available directly
  Future<bool> get isBiometricAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Trigger biometric prompt
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan sidik jari atau wajah untuk login',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Enable biometric login by saving credentials securely
  Future<void> enableBiometric(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }

  /// Check if biometric login is enabled (credentials exist)
  Future<bool> get isBiometricEnabled async {
    final email = await _storage.read(key: _keyEmail);
    return email != null;
  }

  /// Retrieve stored credentials
  Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

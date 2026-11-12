import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Thin, crash-safe wrapper around device biometrics.
///
/// Web and desktop builds report "not available" instead of throwing, and the
/// app always keeps password sign-in as the fallback.
abstract final class Biometrics {
  static final LocalAuthentication _auth = LocalAuthentication();

  static bool get supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> isAvailable() async {
    if (!supportedPlatform) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (error) {
      debugPrint('Biometrics unavailable: $error');
      return false;
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    if (!supportedPlatform) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (error) {
      debugPrint('Biometric authentication failed: $error');
      return false;
    }
  }
}

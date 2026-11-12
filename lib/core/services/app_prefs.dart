import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small persisted settings store for onboarding and session security.
///
/// Falls back to an in-memory map when platform storage is unavailable (widget
/// tests, unsupported platforms) so screens never crash and never block.
abstract final class AppPrefs {
  static const _kOnboardingSeen = 'relearn.onboarding_seen';
  static const _kBiometricsEnabled = 'relearn.biometrics_enabled';
  static const _kLastActive = 'relearn.last_active_at';

  static SharedPreferences? _prefs;
  static final Map<String, Object> _memory = {};
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (error) {
      debugPrint('AppPrefs: using the in-memory fallback ($error)');
    }
  }

  static bool get onboardingSeen => _getBool(_kOnboardingSeen) ?? false;

  static Future<void> setOnboardingSeen(bool value) =>
      _setBool(_kOnboardingSeen, value);

  static bool get biometricsEnabled => _getBool(_kBiometricsEnabled) ?? false;

  static Future<void> setBiometricsEnabled(bool value) =>
      _setBool(_kBiometricsEnabled, value);

  static DateTime? get lastActiveAt {
    final raw = _getInt(_kLastActive);
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  static Future<void> setLastActiveAt(DateTime value) =>
      _setInt(_kLastActive, value.millisecondsSinceEpoch);

  static bool? _getBool(String key) {
    final prefs = _prefs;
    if (prefs != null) return prefs.getBool(key);
    final value = _memory[key];
    return value is bool ? value : null;
  }

  static int? _getInt(String key) {
    final prefs = _prefs;
    if (prefs != null) return prefs.getInt(key);
    final value = _memory[key];
    return value is int ? value : null;
  }

  static Future<void> _setBool(String key, bool value) async {
    _memory[key] = value;
    await _prefs?.setBool(key, value);
  }

  static Future<void> _setInt(String key, int value) async {
    _memory[key] = value;
    await _prefs?.setInt(key, value);
  }
}

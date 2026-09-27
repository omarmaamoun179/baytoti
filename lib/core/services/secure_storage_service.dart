import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SecureStorageService {
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tempTokenKey = 'temp_token';
  static const String languageKey = 'app_language';

  static const String userKey = 'auth_user';

  static const String otpEnabledKey = 'auth_otp_enabled';

  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();

  Future<void> clearOnReinstall();
}

class SecureStorageServiceImpl implements SecureStorageService {
  static const String _freshInstallKey = 'secure_storage_initialized';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  SecureStorageServiceImpl(this._secureStorage, this._prefs);

  @override
  Future<void> clearOnReinstall() async {
    final isInitialized = _prefs.getBool(_freshInstallKey) ?? false;
    if (!isInitialized) {
      log('SecureStorageService: fresh install detected, clearing stale data');
      await _secureStorage.deleteAll();
      await _prefs.setBool(_freshInstallKey, true);
    }
  }

  @override
  Future<void> write({required String key, required String value}) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _secureStorage.read(key: key);

  @override
  Future<void> delete({required String key}) => _secureStorage.delete(key: key);

  @override
  Future<void> deleteAll() => _secureStorage.deleteAll();

  @override
  Future<Map<String, String>> readAll() => _secureStorage.readAll();
}

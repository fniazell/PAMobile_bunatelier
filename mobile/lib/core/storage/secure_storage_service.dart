import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final Map<String, String> _testMemory = {};
  static final Map<String, String> _memoryFallback = {};

  static bool get _isTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> _write(String key, String value) async {
    _memoryFallback[key] = value;
    if (_isTest) {
      _testMemory[key] = value;
      return;
    }
    try {
      await _storage
          .write(key: key, value: value)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    if (_isTest) {
      return _testMemory[key];
    }
    try {
      final val = await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 2));
      return val ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _delete(String key) async {
    _memoryFallback.remove(key);
    if (_isTest) {
      _testMemory.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    _memoryFallback.clear();
    if (_isTest) {
      _testMemory.clear();
      return;
    }
    try {
      await _storage.deleteAll().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  static const _keyAccessToken = 'bun_access_token';
  static const _keyRefreshToken = 'bun_refresh_token';
  static const _keyUserData = 'bun_user_data';
  static const _keyBiometricUserData = 'bun_biometric_user_data';
  static const _keyBiometricEnabled = 'bun_biometric_enabled';
  static const _keyLanguage = 'bun_settings_language';
  static const _keyThemeMode = 'bun_settings_theme_mode';
  static const _keyNotificationsEnabled = 'bun_settings_notifications_enabled';

  // Key for storing all registered accounts
  static const _keyRegisteredAccounts = 'bun_registered_accounts';

  // Registered Accounts List
  Future<List<Map<String, dynamic>>> getRegisteredAccounts() async {
    final raw = await _read(_keyRegisteredAccounts);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRegisteredAccounts(
    List<Map<String, dynamic>> accounts,
  ) async {
    await _write(_keyRegisteredAccounts, jsonEncode(accounts));
  }

  Future<Map<String, dynamic>?> findAccountByEmail(String email) async {
    final accounts = await getRegisteredAccounts();
    try {
      return accounts.firstWhere(
        (a) => (a['email'] as String).toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    final account = await findAccountByEmail(email);
    return account != null;
  }

  // Access Token
  Future<void> saveAccessToken(String token) async {
    await _write(_keyAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    return await _read(_keyAccessToken);
  }

  // Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _write(_keyRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    return await _read(_keyRefreshToken);
  }

  // User Profile Data
  Future<void> saveUserData(Map<String, dynamic> user) async {
    await _write(_keyUserData, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final raw = await _read(_keyUserData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBiometricUserData(Map<String, dynamic> user) async {
    await _write(_keyBiometricUserData, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getBiometricUserData() async {
    final raw = await _read(_keyBiometricUserData);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearBiometricUserData() async {
    await _delete(_keyBiometricUserData);
  }

  // Biometrics
  Future<void> setBiometricEnabled(bool enabled) async {
    await _write(_keyBiometricEnabled, enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _read(_keyBiometricEnabled);
    return val == 'true';
  }

  // Clear Session (Logout)
  Future<void> clearAuthSession() async {
    await _delete(_keyAccessToken);
    await _delete(_keyRefreshToken);
    await _delete(_keyUserData);
  }

  // Settings Preferences
  Future<void> setLanguage(String lang) async {
    try {
      await _write(_keyLanguage, lang);
    } catch (_) {}
  }

  Future<String?> getLanguage() async {
    try {
      return await _read(_keyLanguage);
    } catch (_) {
      return null;
    }
  }

  Future<void> setThemeMode(String mode) async {
    try {
      await _write(_keyThemeMode, mode);
    } catch (_) {}
  }

  Future<String?> getThemeMode() async {
    try {
      return await _read(_keyThemeMode);
    } catch (_) {
      return null;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _write(_keyNotificationsEnabled, enabled.toString());
    } catch (_) {}
  }

  Future<bool> isNotificationsEnabled() async {
    try {
      final val = await _read(_keyNotificationsEnabled);
      if (val == null) return true; // default enabled
      return val == 'true';
    } catch (_) {
      return true;
    }
  }

  Future<void> clearAll() async {
    await _deleteAll();
  }
}

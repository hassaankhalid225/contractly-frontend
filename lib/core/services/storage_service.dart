import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Handles secure JWT token storage (FlutterSecureStorage) and lightweight
/// preferences / cached data via Hive.
class StorageService {
  StorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static Box<dynamic>? _prefsBox;

  /// Must be called once at app startup before any prefs methods.
  static Future<void> init() async {
    await Hive.initFlutter();
    _prefsBox = await Hive.openBox<dynamic>(AppConstants.hivePrefsBox);
    await Hive.openBox<dynamic>(AppConstants.hiveNotificationsBox);
  }

  // ---- Tokens -----------------------------------------------------------

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  static Future<void> saveAccessToken(String access) =>
      _storage.write(key: _accessTokenKey, value: access);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<bool> hasTokens() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  // ---- Prefs (Hive) -----------------------------------------------------

  static Box<dynamic> get _prefs {
    final box = _prefsBox;
    if (box == null) {
      throw StateError('StorageService.init() has not been called.');
    }
    return box;
  }

  static T? readPref<T>(String key) {
    final value = _prefs.get(key);
    if (value is T) return value;
    return null;
  }

  static Future<void> writePref(String key, Object? value) =>
      _prefs.put(key, value);

  static Future<void> deletePref(String key) => _prefs.delete(key);

  // ---- Cached user (raw JSON) -------------------------------------------

  static Map<String, dynamic>? readCachedUser() {
    final raw = _prefs.get(AppConstants.prefCachedUser);
    if (raw is String && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> writeCachedUser(Map<String, dynamic>? json) async {
    if (json == null) {
      await _prefs.delete(AppConstants.prefCachedUser);
    } else {
      await _prefs.put(AppConstants.prefCachedUser, jsonEncode(json));
    }
  }
}

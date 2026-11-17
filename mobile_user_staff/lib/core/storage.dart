import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Penyimpanan lokal: alamat server (prefs) dan token JWT (secure storage).
class Store {
  Store._();

  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static late SharedPreferences _prefs;
  static String? _access;
  static String? _refresh;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      _access = await _secure.read(key: 'accessToken');
      _refresh = await _secure.read(key: 'refreshToken');
    } catch (_) {
      _access = null;
      _refresh = null;
    }
  }

  // ---------- Server ----------
  static String get serverUrl => _prefs.getString('serverUrl') ?? AppConfig.defaultServerUrl;
  static String get apiBase => '$serverUrl/api';

  static String normalizeServerUrl(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return AppConfig.defaultServerUrl;
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(s)) s = 'http://$s';
    s = s.replaceAll(RegExp(r'/+$'), '');
    s = s.replaceAll(RegExp(r'/api$', caseSensitive: false), '');
    return s;
  }

  static Future<void> setServerUrl(String raw) async {
    await _prefs.setString('serverUrl', normalizeServerUrl(raw));
  }

  // ---------- Mode Tema (Terang / Gelap / Sistem) ----------
  static String get themeModeStr => _prefs.getString('themeMode') ?? 'light';

  static ThemeMode get themeMode {
    switch (themeModeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('themeMode', mode.name);
  }

  /// Ubah path upload backend ("/uploads/logo.png") menjadi URL penuh.
  static String asset(String? path) {
    if (path == null || path.isEmpty) return '';
    if (RegExp(r'^(https?:|data:)', caseSensitive: false).hasMatch(path)) return path;
    return '$serverUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  // ---------- Token ----------
  static String? get accessToken => _access;
  static String? get refreshToken => _refresh;

  static Future<void> saveTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    try {
      await _secure.write(key: 'accessToken', value: access);
      await _secure.write(key: 'refreshToken', value: refresh);
    } catch (_) {}
  }

  static Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    try {
      await _secure.delete(key: 'accessToken');
      await _secure.delete(key: 'refreshToken');
    } catch (_) {}
    await _prefs.remove('user');
  }

  // ---------- Cache user (agar aplikasi tetap terbuka saat server belum terjangkau) ----------
  static Map<String, dynamic>? get cachedUser {
    final raw = _prefs.getString('user');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('user', jsonEncode(user));
  }

  static String? getString(String key) => _prefs.getString(key);

  static Future<void> setString(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  static String get lastUsername => _prefs.getString('lastUsername') ?? '';
  static Future<void> setLastUsername(String v) async {
    await _prefs.setString('lastUsername', v);
  }
}

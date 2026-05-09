import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyAccessToken = 'access_token';
  static const _keyProfile = 'profile';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ── access token ───────────────────────────────────────────────────────────

  String? getAccessToken() => _prefs.getString(_keyAccessToken);

  Future<void> saveAccessToken(String token) =>
      _prefs.setString(_keyAccessToken, token);

  Future<void> clearAccessToken() => _prefs.remove(_keyAccessToken);

  // ── profile ────────────────────────────────────────────────────────────────

  Map<String, dynamic>? getProfile() {
    final raw = _prefs.getString(_keyProfile);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveProfile(Map<String, dynamic> profileJson) =>
      _prefs.setString(_keyProfile, jsonEncode(profileJson));

  Future<void> clearProfile() => _prefs.remove(_keyProfile);

  // ── clear all ──────────────────────────────────────────────────────────────

  Future<void> clearAll() => _prefs.clear();
}
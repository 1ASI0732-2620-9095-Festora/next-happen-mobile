import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );

  static const _tokenKey = 'nh_token';
  static const _roleKey = 'nh_role';
  static const _userIdKey = 'nh_user_id';

  // In-memory cache for immediate, zero-latency access across all platforms
  static String? _cachedToken;
  static String? _cachedRole;
  static String? _cachedUserId;

  Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
  }) async {
    _cachedToken = token;
    _cachedRole = role;
    _cachedUserId = userId;

    try {
      await Future.wait([
        _storage.write(key: _tokenKey, value: token),
        _storage.write(key: _roleKey, value: role),
        _storage.write(key: _userIdKey, value: userId),
      ]);
    } catch (e) {
      debugPrint('⚠️ SecureStorage saveSession error: $e');
    }
  }

  Future<String?> readToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    try {
      final token = await _storage.read(key: _tokenKey);
      _cachedToken = token;
      return token;
    } catch (e) {
      debugPrint('⚠️ SecureStorage readToken error: $e');
      return _cachedToken;
    }
  }

  Future<String?> readRole() async {
    if (_cachedRole != null && _cachedRole!.isNotEmpty) {
      return _cachedRole;
    }
    try {
      final role = await _storage.read(key: _roleKey);
      _cachedRole = role;
      return role;
    } catch (e) {
      return _cachedRole;
    }
  }

  Future<String?> readUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId;
    }
    try {
      final userId = await _storage.read(key: _userIdKey);
      _cachedUserId = userId;
      return userId;
    } catch (e) {
      return _cachedUserId;
    }
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedRole = null;
    _cachedUserId = null;
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _roleKey),
        _storage.delete(key: _userIdKey),
      ]);
    } catch (e) {
      debugPrint('⚠️ SecureStorage clearSession error: $e');
    }
  }

  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

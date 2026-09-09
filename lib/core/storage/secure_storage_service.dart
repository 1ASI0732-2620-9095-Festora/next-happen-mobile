import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'nh_token';
  static const _roleKey = 'nh_role';
  static const _userIdKey = 'nh_user_id';

  Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<String?> readRole() => _storage.read(key: _roleKey);
  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _userIdKey),
    ]);
  }

  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

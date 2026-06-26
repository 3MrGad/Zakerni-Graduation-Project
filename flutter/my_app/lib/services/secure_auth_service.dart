import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'secure_auth_token';
  static const _roleKey = 'secure_user_role';
  static const _rememberKey = 'remember_me_enabled';
  static const _expiresKey = 'secure_token_expires_at';

  static Future<void> saveRememberedSession({
    required String token,
    required String role,
    String? expiresAt,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _rememberKey, value: 'true');
    if (expiresAt != null) {
      await _storage.write(key: _expiresKey, value: expiresAt);
    }
  }

  static Future<void> clearRememberedSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _rememberKey);
    await _storage.delete(key: _expiresKey);
  }

  static Future<bool> isRememberedSessionExpired() async {
    final expires = await _storage.read(key: _expiresKey);
    if (expires == null || expires.isEmpty) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(expires));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isRememberMeEnabled() async {
    return (await _storage.read(key: _rememberKey)) == 'true';
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<String?> getRole() => _storage.read(key: _roleKey);
}

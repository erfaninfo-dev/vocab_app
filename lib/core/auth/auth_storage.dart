import 'package:shared_preferences/shared_preferences.dart';

const _kAuthTokenKey = 'auth_token_v1';

/// Persists the API bearer token (uses [SharedPreferences] on all platforms —
/// avoids Windows build issues with `flutter_secure_storage` / ATL).
class AuthStorage {
  Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAuthTokenKey);
  }

  Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAuthTokenKey, token);
  }

  Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAuthTokenKey);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/auth_user.dart';

const _kAuthTokenKey = 'auth_token_v1';
const _kAuthUserKey = 'auth_user_v1';
const _kAuthExtraSessionsKey = 'auth_extra_sessions_v1';

/// Persists the API bearer token (uses [SharedPreferences] on all platforms —
/// avoids Windows build issues with `flutter_secure_storage` / ATL).
///
/// Also caches the last successfully fetched [AuthUser] so we can restore the
/// session instantly on cold start, even when the network is slow or offline.
/// The token remains the source of truth; the cached user is only a hint we
/// use to avoid a blank splash screen while the background verification call
/// hits `/me.php`.
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
    await p.remove(_kAuthUserKey);
  }

  /// Returns the last-known [AuthUser] or null if none was saved / decode fails.
  Future<AuthUser?> readCachedUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAuthUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      // Corrupt payload — drop it silently so future logins re-seed it.
      await p.remove(_kAuthUserKey);
      return null;
    }
  }

  /// Persists the user payload we got back from the server so it can be
  /// restored on the next cold start before the network call resolves.
  Future<void> saveCachedUser(AuthUser user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAuthUserKey, jsonEncode(user.toJson()));
  }

  Future<void> clearCachedUser() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAuthUserKey);
  }

  /// Other signed-in sessions besides the active [auth_token_v1] slot.
  Future<List<AuthSession>> readExtraSessions() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAuthExtraSessionsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await p.remove(_kAuthExtraSessionsKey);
        return const [];
      }
      final sessions = <AuthSession>[];
      final seen = <int>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final session = AuthSession.fromJson(Map<String, dynamic>.from(item));
          if (session.token.isEmpty || seen.contains(session.user.id)) {
            continue;
          }
          seen.add(session.user.id);
          sessions.add(session);
        } catch (_) {
          continue;
        }
      }
      return sessions;
    } catch (_) {
      await p.remove(_kAuthExtraSessionsKey);
      return const [];
    }
  }

  Future<void> saveExtraSessions(List<AuthSession> sessions) async {
    final p = await SharedPreferences.getInstance();
    final activeToken = p.getString(_kAuthTokenKey);
    final unique = <int, AuthSession>{};
    for (final session in sessions) {
      if (session.token.isEmpty) continue;
      if (activeToken != null && session.token == activeToken) continue;
      unique[session.user.id] = session;
    }
    if (unique.isEmpty) {
      await p.remove(_kAuthExtraSessionsKey);
      return;
    }
    await p.setString(
      _kAuthExtraSessionsKey,
      jsonEncode(unique.values.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> clearExtraSessions() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAuthExtraSessionsKey);
  }
}

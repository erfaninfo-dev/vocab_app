import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_user.dart';
import '../../data/services/api_service.dart';
import '../cache/api_disk_cache.dart';
import '../../features/home/home_displayed_books_provider.dart';
import '../profile/profile_photo_cache.dart';
import 'auth_storage.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

/// Handles sign-in, sign-out and cold-start session restoration.
///
/// Cold-start contract (this is where the "I got logged out on every launch"
/// bug used to live):
///
///   1. If there's no saved token → user is signed out. Simple.
///   2. If there's a saved token AND a cached user → return the cached session
///      immediately so the UI doesn't flash "signed out". Then verify with the
///      server in the background. Only an explicit 401 clears the token;
///      network/timeout/5xx errors leave the session intact.
///   3. If there's a saved token but no cached user → wait for one network
///      call (with a 10 s timeout). On success cache the user and return the
///      session. On 401 clear the token. **On any other failure keep the
///      token** but return null for this launch; the next launch retries.
class AuthNotifier extends AsyncNotifier<AuthSession?> {
  final AuthStorage _storage = AuthStorage();

  @override
  Future<AuthSession?> build() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final cachedUser = await _storage.readCachedUser();
    if (cachedUser != null) {
      // Resume immediately; verify in the background without blocking the UI.
      unawaited(_verifyInBackground(token));
      return AuthSession(token: token, user: cachedUser);
    }

    // No cache yet → we have to hit /me.php once to learn who the user is.
    try {
      final user = await ApiService(authToken: token).fetchCurrentUser();
      await _storage.saveCachedUser(user);
      return AuthSession(token: token, user: user);
    } on UnauthorizedException {
      // Server said "this token is dead" — wipe it so we stop showing the
      // half-signed-in state next launch.
      await _storage.clearToken();
      return null;
    } catch (_) {
      // Network/timeout/5xx — keep the token so the user stays signed in once
      // connectivity returns. The UI will prompt for sign-in for this session
      // only, and the next cold start will try again.
      return null;
    }
  }

  /// Verifies [token] against the server and reconciles state silently.
  ///
  /// This is fired-and-forgotten from [build] when we already restored a
  /// cached session. It never throws and never flips the UI to "signed out"
  /// unless the server explicitly rejects the token (401).
  Future<void> _verifyInBackground(String token) async {
    try {
      final user = await ApiService(authToken: token).fetchCurrentUser();
      await _storage.saveCachedUser(user);
      final current = state.valueOrNull;
      // Only update if we're still logged in with the same token — otherwise
      // the user signed out between our request and the response.
      if (current != null && current.token == token) {
        state = AsyncData(AuthSession(token: token, user: user));
      }
    } on UnauthorizedException {
      await _storage.clearToken();
      state = const AsyncData(null);
    } catch (_) {
      // Swallow transient errors; the cached session stays as-is.
    }
  }

  Future<void> login(String email, String password) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final session = await ApiService().login(
        email: email,
        password: password,
      );
      await _storage.saveToken(session.token);
      await _storage.saveCachedUser(session.user);
      await ApiDiskCache.instance.clearAll();
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
    bool registerAsStudent = false,
    String? studentCode,
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final session = await ApiService().register(
        email: email,
        password: password,
        displayName: displayName,
        registerAsStudent: registerAsStudent,
        studentCode: studentCode,
      );
      await _storage.saveToken(session.token);
      await _storage.saveCachedUser(session.user);
      await ApiDiskCache.instance.clearAll();
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Refreshes profile from GET /me.php (e.g. after redeeming student code).
  ///
  /// Only clears the session on an explicit 401; network failures leave the
  /// current session untouched so the user isn't punished for a flaky
  /// connection.
  Future<void> refreshSession() async {
    final s = state.valueOrNull;
    if (s == null) return;
    try {
      final user = await ApiService(authToken: s.token).fetchCurrentUser();
      await _storage.saveCachedUser(user);
      state = AsyncData(AuthSession(token: s.token, user: user));
    } on UnauthorizedException {
      await _storage.clearToken();
      state = const AsyncData(null);
    } catch (_) {
      // Transient: keep the current session.
    }
  }

  /// POST /student_redeem_code.php — updates session user.
  Future<void> redeemStudentCode(String code) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(authToken: s.token).redeemStudentCode(code);
    await _storage.saveCachedUser(user);
    state = AsyncData(AuthSession(token: s.token, user: user));
    await ApiDiskCache.instance.clearAll();
    ref.invalidate(apiPublicBooksForHomeProvider);
    ref.invalidate(apiStudentBooksForHomeProvider);
  }

  Future<void> logout() async {
    final s = state.valueOrNull;
    if (s != null) {
      try {
        await ApiService(authToken: s.token).logout();
      } catch (_) {}
    }
    await _storage.clearToken();
    await ApiDiskCache.instance.clearAll();
    state = const AsyncData(null);
  }

  /// Updates display name + avatar on the server and refreshes local session.
  Future<void> updateProfile({
    required String displayName,
    required String avatar,
  }) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(authToken: s.token).updateProfile(
      displayName: displayName,
      avatar: avatar,
    );
    await _storage.saveCachedUser(user);
    state = AsyncData(AuthSession(token: s.token, user: user));
  }

  /// Uploads a JPEG; server stores it and sets avatar to `custom`.
  Future<void> uploadProfilePhoto(Uint8List jpegBytes) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(authToken: s.token).uploadProfilePhoto(
      jpegBytes,
    );
    await _storage.saveCachedUser(user);
    ref.read(profilePhotoCacheNonceProvider.notifier).state++;
    state = AsyncData(AuthSession(token: s.token, user: user));
  }
}

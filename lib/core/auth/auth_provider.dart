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

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final storage = AuthStorage();
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final user = await ApiService(authToken: token).fetchCurrentUser();
      return AuthSession(token: token, user: user);
    } catch (_) {
      await storage.clearToken();
      return null;
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
      await AuthStorage().saveToken(session.token);
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
      await AuthStorage().saveToken(session.token);
      await ApiDiskCache.instance.clearAll();
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Refreshes profile from GET /me.php (e.g. after redeeming student code).
  Future<void> refreshSession() async {
    final s = state.valueOrNull;
    if (s == null) return;
    try {
      final user = await ApiService(authToken: s.token).fetchCurrentUser();
      state = AsyncData(AuthSession(token: s.token, user: user));
    } catch (_) {}
  }

  /// POST /student_redeem_code.php — updates session user.
  Future<void> redeemStudentCode(String code) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(authToken: s.token).redeemStudentCode(code);
    state = AsyncData(AuthSession(token: s.token, user: user));
    await ApiDiskCache.instance.clearAll();
    ref.invalidate(apiHomeBooksProvider);
  }

  Future<void> logout() async {
    final s = state.valueOrNull;
    if (s != null) {
      try {
        await ApiService(authToken: s.token).logout();
      } catch (_) {}
    }
    await AuthStorage().clearToken();
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
    ref.read(profilePhotoCacheNonceProvider.notifier).state++;
    state = AsyncData(AuthSession(token: s.token, user: user));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_user.dart';
import '../../data/services/api_service.dart';
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
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    try {
      final session = await ApiService().register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await AuthStorage().saveToken(session.token);
      state = AsyncData(session);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> logout() async {
    final s = state.valueOrNull;
    if (s != null) {
      try {
        await ApiService(authToken: s.token).logout();
      } catch (_) {}
    }
    await AuthStorage().clearToken();
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
}

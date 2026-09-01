import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_user.dart';
import '../../data/services/api_service.dart';
import '../cache/api_disk_cache.dart';
import '../../features/home/home_displayed_books_provider.dart';
import '../profile/profile_photo_cache.dart';
import '../../domain/api_remote_data_epoch.dart';
import 'auth_storage.dart';

const kMaxAuthAccounts = 4;

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);

/// All locally signed-in sessions, active first. Empty when signed out.
final authAccountSlotsProvider = StateProvider<List<AuthSession>>(
  (ref) => const [],
);

class AuthAddAccountNotAllowedException implements Exception {}

class AuthAddAccountLimitException implements Exception {
  const AuthAddAccountLimitException(this.max);
  final int max;
}

bool canAddAuthAccount({
  required AuthSession? active,
  required List<AuthSession> slots,
}) {
  if (active == null || !active.user.isAdmin) return false;
  return slots.length < kMaxAuthAccounts;
}

bool showsAuthAccountSwitcher({
  required AuthSession? active,
  required List<AuthSession> slots,
}) {
  final effective = effectiveAuthSlots(
    active: active,
    publishedSlots: slots,
  );
  if (effective.length > 1) return true;
  return active?.user.isAdmin == true;
}

/// Merges the Riverpod slot list with the active session so UI matches storage
/// after cold start or account switch (provider can briefly be empty).
List<AuthSession> effectiveAuthSlots({
  required AuthSession? active,
  required List<AuthSession> publishedSlots,
}) {
  if (publishedSlots.isNotEmpty) {
    if (active == null) {
      return List<AuthSession>.unmodifiable(publishedSlots);
    }
    final out = <AuthSession>[];
    final seen = <int>{};
    out.add(active);
    seen.add(active.user.id);
    for (final session in publishedSlots) {
      if (seen.add(session.user.id)) {
        out.add(session);
      }
    }
    return List<AuthSession>.unmodifiable(out);
  }
  if (active != null) {
    return List<AuthSession>.unmodifiable([active]);
  }
  return const [];
}

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
  var _disposed = false;

  @override
  Future<AuthSession?> build() async {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final extras = await _storage.readExtraSessions();
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      if (extras.isEmpty) {
        _publishSlots(const [], defer: true);
        return null;
      }
      final next = extras.first;
      final remaining = extras.skip(1).toList();
      await _storage.saveToken(next.token);
      await _storage.saveCachedUser(next.user);
      await _storage.saveExtraSessions(remaining);
      _publishSlots(_mergeSlots(next, remaining), defer: true);
      unawaited(_verifyInBackground(next.token));
      return next;
    }

    final cachedUser = await _storage.readCachedUser();
    if (cachedUser != null) {
      final session = AuthSession(token: token, user: cachedUser);
      _publishSlots(_mergeSlots(session, extras), defer: true);
      unawaited(_verifyInBackground(token));
      return session;
    }

    try {
      final user = await ApiService(authToken: token).fetchCurrentUser();
      await _storage.saveCachedUser(user);
      final session = AuthSession(token: token, user: user);
      _publishSlots(_mergeSlots(session, extras), defer: true);
      return session;
    } on UnauthorizedException {
      return _promoteDuringBuild(extras);
    } catch (_) {
      _publishSlots(const [], defer: true);
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
      if (current != null && current.token == token) {
        final extras = await _storage.readExtraSessions();
        final session = AuthSession(token: token, user: user);
        state = AsyncData(session);
        _publishSlots(_mergeSlots(session, extras));
      }
    } on UnauthorizedException {
      await _dropActiveAndPromote();
    } catch (_) {
      // Swallow transient errors; the cached session stays as-is.
    }
  }

  Future<void> login(String email, String password) async {
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    AuthSession? created;
    try {
      created = await ApiService().login(
        email: email,
        password: password,
      );
      await _storage.clearExtraSessions();
      await _activateSession(created, extras: const [], clearCache: true);
    } catch (e, st) {
      if (created != null && await _recoverIfSessionPersisted(created)) {
        return;
      }
      state = AsyncData(previous);
      if (previous != null) {
        final extras = await _storage.readExtraSessions();
        _publishSlots(_mergeSlots(previous, extras));
      } else {
        _publishSlots(const []);
      }
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Adds another signed-in session without signing out the current one.
  ///
  /// Admin-only. Lands on the newly added account (Telegram-style).
  Future<void> addAccount(String email, String password) async {
    final session = await ApiService().login(email: email, password: password);
    await _adoptAdditionalSession(session);
  }

  Future<void> switchAccount(int userId) async {
    final current = state.valueOrNull;
    if (current == null || current.user.id == userId) return;
    final extras = await _storage.readExtraSessions();
    AuthSession? target;
    for (final extra in extras) {
      if (extra.user.id == userId) {
        target = extra;
        break;
      }
    }
    if (target == null) return;
    final kept = <AuthSession>[
      current,
      ...extras.where((s) => s.user.id != userId),
    ];
    await _activateSession(target, extras: kept, clearCache: true);
    await resyncSlotsFromStorage();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
    bool registerAsStudent = false,
    String? studentCode,
    bool keepCurrent = false,
  }) async {
    final previous = state.valueOrNull;
    final adding = keepCurrent && previous?.user.isAdmin == true;
    if (adding) {
      AuthSession? created;
      try {
        created = await ApiService().register(
          email: email,
          password: password,
          displayName: displayName,
          registerAsStudent: registerAsStudent,
          studentCode: studentCode,
        );
        await _adoptAdditionalSession(created);
      } catch (e, st) {
        if (created != null && await _recoverIfSessionPersisted(created)) {
          return;
        }
        Error.throwWithStackTrace(e, st);
      }
      return;
    }
    state = const AsyncLoading();
    AuthSession? created;
    try {
      created = await ApiService().register(
        email: email,
        password: password,
        displayName: displayName,
        registerAsStudent: registerAsStudent,
        studentCode: studentCode,
      );
      await _storage.clearExtraSessions();
      await _activateSession(created, extras: const [], clearCache: true);
    } catch (e, st) {
      if (created != null && await _recoverIfSessionPersisted(created)) {
        return;
      }
      state = AsyncData(previous);
      if (previous != null) {
        final extras = await _storage.readExtraSessions();
        _publishSlots(_mergeSlots(previous, extras));
      } else {
        _publishSlots(const []);
      }
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
      final extras = await _storage.readExtraSessions();
      final session = AuthSession(token: s.token, user: user);
      state = AsyncData(session);
      _publishSlots(_mergeSlots(session, extras));
    } on UnauthorizedException {
      await _dropActiveAndPromote();
    } catch (_) {
      // Transient: keep the current session.
    }
  }

  /// POST /teacher_student_codes.php — registers a one-time code (teacher/admin).
  Future<String> createTeacherStudentCode(String code) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    return ApiService(authToken: s.token).createTeacherStudentCode(code);
  }

  /// POST /student_redeem_code.php — updates session user.
  Future<void> redeemStudentCode(String code) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(authToken: s.token).redeemStudentCode(code);
    await _storage.saveCachedUser(user);
    final extras = await _storage.readExtraSessions();
    final session = AuthSession(token: s.token, user: user);
    state = AsyncData(session);
    _publishSlots(_mergeSlots(session, extras));
    await ApiDiskCache.instance.clearAll();
    ref.invalidate(apiPublicBooksForHomeProvider);
    ref.invalidate(apiStudentBooksForHomeProvider);
  }

  /// True when another account remains in storage after signing out the active one.
  Future<bool> hasOtherSavedAccounts() async {
    final extras = await _storage.readExtraSessions();
    return extras.isNotEmpty;
  }

  /// Signs out the active account. If another saved account exists, it becomes
  /// active; otherwise the device is fully signed out.
  Future<AuthSession?> logout() async {
    final s = state.valueOrNull;
    if (s != null) {
      unawaited(_silentLogout(s.token));
    }
    return _dropActiveAndPromote();
  }

  /// Signs out every saved account on this device.
  Future<void> logoutAllAccounts() async {
    final current = state.valueOrNull;
    final extras = await _storage.readExtraSessions();
    final tokens = <String>{
      if (current != null && current.token.isNotEmpty) current.token,
      for (final extra in extras)
        if (extra.token.isNotEmpty) extra.token,
    };
    for (final token in tokens) {
      unawaited(_silentLogout(token));
    }
    await _storage.clearToken();
    await _storage.clearExtraSessions();
    await ApiDiskCache.instance.clearAll();
    ref.read(apiRemoteDataEpochProvider.notifier).state++;
    ref.invalidate(apiPublicBooksForHomeProvider);
    ref.invalidate(apiStudentBooksForHomeProvider);
    _publishSlots(const []);
    state = const AsyncData(null);
  }

  /// Rebuilds [authAccountSlotsProvider] from persisted storage.
  Future<void> resyncSlotsFromStorage() async {
    final active = state.valueOrNull;
    final extras = await _storage.readExtraSessions();
    _publishSlots(_mergeSlots(active, extras));
  }

  /// Signs out a non-active saved account. Returns false if nothing was removed.
  Future<bool> removeSavedAccount(int userId) async {
    final current = state.valueOrNull;
    if (current != null && current.user.id == userId) {
      await logout();
      return true;
    }
    final extras = await _storage.readExtraSessions();
    AuthSession? removed;
    final kept = <AuthSession>[];
    for (final extra in extras) {
      if (extra.user.id == userId) {
        removed = extra;
      } else {
        kept.add(extra);
      }
    }
    if (removed == null) {
      final published = ref.read(authAccountSlotsProvider);
      final effective = effectiveAuthSlots(
        active: current,
        publishedSlots: published,
      );
      for (final session in effective) {
        if (session.user.id == userId) {
          removed = session;
          break;
        }
      }
      if (removed == null) {
        await resyncSlotsFromStorage();
        return false;
      }
      final rebuiltExtras = <AuthSession>[];
      for (final session in effective) {
        if (session.user.id == current?.user.id) continue;
        if (session.user.id == userId) continue;
        rebuiltExtras.add(session);
      }
      unawaited(_silentLogout(removed.token));
      await _storage.saveExtraSessions(rebuiltExtras);
      if (current != null) {
        _publishSlots(_mergeSlots(current, rebuiltExtras));
      } else {
        _publishSlots(rebuiltExtras);
      }
      return true;
    }
    unawaited(_silentLogout(removed.token));
    await _storage.saveExtraSessions(kept);
    if (current != null) {
      _publishSlots(_mergeSlots(current, kept));
    } else {
      _publishSlots(kept);
    }
    return true;
  }

  /// Updates display name + avatar on the server and refreshes local session.
  Future<void> updateProfile({
    required String displayName,
    required String bio,
    required String avatar,
  }) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(
      authToken: s.token,
    ).updateProfile(displayName: displayName, bio: bio, avatar: avatar);
    await _storage.saveCachedUser(user);
    final extras = await _storage.readExtraSessions();
    final session = AuthSession(token: s.token, user: user);
    state = AsyncData(session);
    _publishSlots(_mergeSlots(session, extras));
  }

  /// POST /change_password.php — other sessions revoked; this token kept.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    await ApiService(authToken: s.token).changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Uploads a JPEG; server stores it and sets avatar to `custom`.
  Future<void> uploadProfilePhoto(Uint8List jpegBytes) async {
    final s = state.valueOrNull;
    if (s == null) {
      throw StateError('Not signed in');
    }
    final user = await ApiService(
      authToken: s.token,
    ).uploadProfilePhoto(jpegBytes);
    await _storage.saveCachedUser(user);
    ref.read(profilePhotoCacheNonceProvider.notifier).state++;
    final extras = await _storage.readExtraSessions();
    final session = AuthSession(token: s.token, user: user);
    state = AsyncData(session);
    _publishSlots(_mergeSlots(session, extras));
  }

  /// Keeps the current admin session in the extra slots and activates [session].
  Future<void> _adoptAdditionalSession(AuthSession session) async {
    final current = state.valueOrNull;
    if (current == null || !current.user.isAdmin) {
      unawaited(_silentLogout(session.token));
      throw AuthAddAccountNotAllowedException();
    }
    final extras = await _storage.readExtraSessions();
    final uniqueIds = <int>{current.user.id, ...extras.map((s) => s.user.id)};
    final alreadyStored = uniqueIds.contains(session.user.id);
    if (!alreadyStored && uniqueIds.length >= kMaxAuthAccounts) {
      unawaited(_silentLogout(session.token));
      throw AuthAddAccountLimitException(kMaxAuthAccounts);
    }
    if (session.user.id == current.user.id) {
      if (session.token != current.token) {
        unawaited(_silentLogout(current.token));
      }
      await _activateSession(session, extras: extras, clearCache: true);
      return;
    }
    AuthSession? replaced;
    for (final extra in extras) {
      if (extra.user.id == session.user.id) {
        replaced = extra;
        break;
      }
    }
    if (replaced != null && replaced.token != session.token) {
      unawaited(_silentLogout(replaced.token));
    }
    final kept = <AuthSession>[
      current,
      ...extras.where((s) => s.user.id != session.user.id),
    ];
    await _activateSession(session, extras: kept, clearCache: true);
  }

  Future<void> _activateSession(
    AuthSession session, {
    required List<AuthSession> extras,
    required bool clearCache,
  }) async {
    final others = extras
        .where((s) => s.user.id != session.user.id)
        .toList(growable: false);
    await _storage.saveToken(session.token);
    await _storage.saveCachedUser(session.user);
    await _storage.saveExtraSessions(others);
    state = AsyncData(session);
    _publishSlots(_mergeSlots(session, others));
    try {
      if (clearCache) {
        await ApiDiskCache.instance.clearAll();
      }
      ref.read(apiRemoteDataEpochProvider.notifier).state++;
      ref.invalidate(apiPublicBooksForHomeProvider);
      ref.invalidate(apiStudentBooksForHomeProvider);
      ref.read(profilePhotoCacheNonceProvider.notifier).state++;
    } catch (_) {
      // Token is already persisted; cache/provider refresh must not fail auth.
    }
    unawaited(resyncSlotsFromStorage());
  }

  /// After a post-register/login step fails, the token may already be on disk.
  Future<bool> _recoverIfSessionPersisted(AuthSession session) async {
    final savedToken = await _storage.readToken();
    if (savedToken != session.token) {
      return false;
    }
    final extras = await _storage.readExtraSessions();
    state = AsyncData(session);
    _publishSlots(_mergeSlots(session, extras));
    return true;
  }

  Future<AuthSession?> _promoteDuringBuild(List<AuthSession> extras) async {
    await _storage.clearToken();
    if (extras.isEmpty) {
      await _storage.clearExtraSessions();
      _publishSlots(const [], defer: true);
      return null;
    }
    final next = extras.first;
    final rest = extras.skip(1).toList();
    await _storage.saveToken(next.token);
    await _storage.saveCachedUser(next.user);
    await _storage.saveExtraSessions(rest);
    _publishSlots(_mergeSlots(next, rest), defer: true);
    unawaited(_verifyInBackground(next.token));
    return next;
  }

  Future<AuthSession?> _dropActiveAndPromote({
    List<AuthSession>? extras,
  }) async {
    final remaining = extras ?? await _storage.readExtraSessions();
    if (remaining.isEmpty) {
      await _storage.clearToken();
      await _storage.clearExtraSessions();
      await ApiDiskCache.instance.clearAll();
      ref.read(apiRemoteDataEpochProvider.notifier).state++;
      ref.invalidate(apiPublicBooksForHomeProvider);
      ref.invalidate(apiStudentBooksForHomeProvider);
      _publishSlots(const []);
      state = const AsyncData(null);
      return null;
    }
    final next = remaining.first;
    final rest = remaining.skip(1).toList();
    await _activateSession(next, extras: rest, clearCache: true);
    return next;
  }

  List<AuthSession> _mergeSlots(AuthSession? active, List<AuthSession> extras) {
    if (active == null) return List<AuthSession>.unmodifiable(extras);
    final slots = <AuthSession>[active];
    final seen = <int>{active.user.id};
    for (final extra in extras) {
      if (seen.add(extra.user.id)) {
        slots.add(extra);
      }
    }
    return List<AuthSession>.unmodifiable(slots);
  }

  void _publishSlots(List<AuthSession> slots, {bool defer = false}) {
    final copy = List<AuthSession>.unmodifiable(slots);
    void apply() {
      if (_disposed) return;
      ref.read(authAccountSlotsProvider.notifier).state = copy;
    }

    if (defer) {
      Future.microtask(apply);
    } else {
      apply();
    }
  }

  Future<void> _silentLogout(String token) async {
    try {
      await ApiService(authToken: token).logout();
    } catch (_) {}
  }
}

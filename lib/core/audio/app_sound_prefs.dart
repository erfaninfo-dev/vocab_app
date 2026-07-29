import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app sound prefs (Settings → Sound).
///
/// Keys are versioned. On first launch after upgrade, older keys are migrated
/// into these three toggles (legacy value applied to all three when present).
class AppSoundPrefs {
  static const musicKey = 'sound_music_enabled_v1';
  static const sfxKey = 'sound_sfx_enabled_v1';
  static const hapticsKey = 'sound_haptics_enabled_v1';

  /// Legacy keys that previously gated “all game sound”.
  static const _legacySplash = 'splash_sound_enabled';
  static const _legacySessionSfx = 'word_builder_session_sfx_v1';
  static const _legacySessionBgm = 'word_builder_session_bgm_v1';

  static bool? _legacyUnified(SharedPreferences prefs) {
    if (prefs.containsKey(_legacySplash)) {
      return prefs.getBool(_legacySplash);
    }
    if (prefs.containsKey(_legacySessionSfx)) {
      return prefs.getBool(_legacySessionSfx);
    }
    if (prefs.containsKey(_legacySessionBgm)) {
      return prefs.getBool(_legacySessionBgm);
    }
    return null;
  }

  static Future<void> migrateIfNeeded(SharedPreferences prefs) async {
    final legacy = _legacyUnified(prefs);
    final hasAnyNew = prefs.containsKey(musicKey) ||
        prefs.containsKey(sfxKey) ||
        prefs.containsKey(hapticsKey);
    if (hasAnyNew || legacy == null) return;
    await prefs.setBool(musicKey, legacy);
    await prefs.setBool(sfxKey, legacy);
    await prefs.setBool(hapticsKey, legacy);
  }
}

class AppMusicEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await AppSoundPrefs.migrateIfNeeded(prefs);
      final v = prefs.getBool(AppSoundPrefs.musicKey) ?? true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSoundPrefs.musicKey, value);
      // Keep session BGM key in sync for older session-sheet readers.
      await prefs.setBool('word_builder_session_bgm_v1', value);
    } catch (_) {}
  }
}

class AppSfxEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await AppSoundPrefs.migrateIfNeeded(prefs);
      final v = prefs.getBool(AppSoundPrefs.sfxKey) ?? true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSoundPrefs.sfxKey, value);
      await prefs.setBool('word_builder_session_sfx_v1', value);
    } catch (_) {}
  }
}

class AppHapticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await AppSoundPrefs.migrateIfNeeded(prefs);
      final v = prefs.getBool(AppSoundPrefs.hapticsKey) ?? true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSoundPrefs.hapticsKey, value);
    } catch (_) {}
  }
}

final appMusicEnabledProvider =
    NotifierProvider<AppMusicEnabledNotifier, bool>(AppMusicEnabledNotifier.new);

final appSfxEnabledProvider =
    NotifierProvider<AppSfxEnabledNotifier, bool>(AppSfxEnabledNotifier.new);

final appHapticsEnabledProvider =
    NotifierProvider<AppHapticsEnabledNotifier, bool>(
      AppHapticsEnabledNotifier.new,
    );

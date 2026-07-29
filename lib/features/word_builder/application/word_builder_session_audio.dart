import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/app_audio_session.dart';
import '../../../core/audio/app_sound_prefs.dart';
import 'word_builder_tray_prison_audio.dart';
import 'word_builder_tray_train_audio.dart';
import 'word_builder_tray_water_audio.dart';

final wordBuilderBgmPlayerProvider = Provider<WordBuilderBgmPlayer>((ref) {
  final player = WordBuilderBgmPlayer();
  ref.onDispose(() {
    unawaited(player.dispose());
  });
  return player;
});

final wordBuilderGameSfxEnabledProvider =
    NotifierProvider<WordBuilderGameSfxNotifier, bool>(
      WordBuilderGameSfxNotifier.new,
    );

final wordBuilderGameBgmEnabledProvider =
    NotifierProvider<WordBuilderGameBgmNotifier, bool>(
      WordBuilderGameBgmNotifier.new,
    );

final wordBuilderGameWaterSfxEnabledProvider =
    NotifierProvider<WordBuilderGameWaterSfxNotifier, bool>(
      WordBuilderGameWaterSfxNotifier.new,
    );

final wordBuilderSessionAudioLifecycleProvider = Provider.autoDispose
    .family<int, int>((ref, bookKey) {
      final bgm = ref.read(wordBuilderBgmPlayerProvider);

      ref.watch(wordBuilderTrayWaterAudioProvider(bookKey));
      ref.watch(wordBuilderTrayTrainAudioProvider(bookKey));
      ref.watch(wordBuilderTrayPrisonAudioProvider(bookKey));

      ref.listen<bool>(wordBuilderGameBgmEnabledProvider, (prev, next) {
        unawaited(bgm.applyFromRef(ref));
      });

      ref.listen<bool>(wordBuilderGameWaterSfxEnabledProvider, (prev, next) {
        if (!next) {
          unawaited(
            ref.read(wordBuilderTrayWaterAudioProvider(bookKey)).stopAll(),
          );
          unawaited(
            ref.read(wordBuilderTrayTrainAudioProvider(bookKey)).stopAll(),
          );
          unawaited(
            ref.read(wordBuilderTrayPrisonAudioProvider(bookKey)).stopAll(),
          );
        }
      });

      unawaited(configureAppAudioSession());
      unawaited(bgm.onEnter(ref));

      ref.onDispose(() {
        unawaited(
          ref.read(wordBuilderTrayWaterAudioProvider(bookKey)).stopAll(),
        );
        unawaited(
          ref.read(wordBuilderTrayTrainAudioProvider(bookKey)).stopAll(),
        );
        unawaited(
          ref.read(wordBuilderTrayPrisonAudioProvider(bookKey)).stopAll(),
        );
        unawaited(bgm.onLeave());
      });

      return 0;
    });

class WordBuilderGameSfxNotifier extends Notifier<bool> {
  static const _key = 'word_builder_session_sfx_v1';

  @override
  bool build() {
    // Mirror global Settings → Sound → SFX when available.
    ref.listen<bool>(appSfxEnabledProvider, (prev, next) {
      if (next != state) state = next;
    });
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await AppSoundPrefs.migrateIfNeeded(prefs);
      final v = prefs.getBool(AppSoundPrefs.sfxKey) ??
          prefs.getBool(_key) ??
          true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSoundPrefs.sfxKey, value);
      await prefs.setBool(_key, value);
    } catch (_) {}
    // Sync Settings toggle without re-entering if already matched.
    if (ref.read(appSfxEnabledProvider) != value) {
      await ref.read(appSfxEnabledProvider.notifier).setEnabled(value);
    }
  }
}

class WordBuilderGameWaterSfxNotifier extends Notifier<bool> {
  static const _key = 'word_builder_session_water_sfx_v1';

  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_key) ?? true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

class WordBuilderGameBgmNotifier extends Notifier<bool> {
  static const _key = 'word_builder_session_bgm_v1';

  @override
  bool build() {
    ref.listen<bool>(appMusicEnabledProvider, (prev, next) {
      if (next != state) {
        state = next;
        unawaited(ref.read(wordBuilderBgmPlayerProvider).applyFromRef(ref));
      }
    });
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await AppSoundPrefs.migrateIfNeeded(prefs);
      final v = prefs.getBool(AppSoundPrefs.musicKey) ??
          prefs.getBool(_key) ??
          true;
      state = v;
      await ref.read(wordBuilderBgmPlayerProvider).applyFromRef(ref);
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppSoundPrefs.musicKey, value);
      await prefs.setBool(_key, value);
    } catch (_) {}
    await ref.read(appMusicEnabledProvider.notifier).setEnabled(value);
    await ref.read(wordBuilderBgmPlayerProvider).applyFromRef(ref);
  }
}

class WordBuilderBgmPlayer {
  WordBuilderBgmPlayer();

  static const _asset = 'assets/audio/words_game_bgmusic.mp3';
  static const _volume = 0.32;

  AudioPlayer? _player;
  int _sessions = 0;
  bool _userWantsBgm = true;
  int _sfxBurstHolds = 0;

  Future<void> applyFromRef(Ref ref) async {
    _userWantsBgm = ref.read(wordBuilderGameBgmEnabledProvider);
    await _syncPlayback();
  }

  Future<void> apply({required bool enabled}) async {
    _userWantsBgm = enabled;
    await _syncPlayback();
  }

  Future<void> onEnter(Ref ref) async {
    _sessions++;
    await applyFromRef(ref);
  }

  Future<void> onLeave() async {
    if (_sessions > 0) _sessions--;
    if (_sessions < 0) _sessions = 0;
    await _syncPlayback();
  }

  /// Pause BGM while a burst of SFX plays (Windows just_audio is fragile).
  Future<void> beginSfxBurst() async {
    _sfxBurstHolds++;
    final player = _player;
    if (player == null) return;
    try {
      await player.pause();
    } catch (_) {}
  }

  Future<void> endSfxBurst() async {
    if (_sfxBurstHolds > 0) _sfxBurstHolds--;
    await _syncPlayback();
  }

  Future<void> stopForAppBackground() => _stop();

  Future<void> _syncPlayback() async {
    final should = _sessions > 0 && _userWantsBgm && _sfxBurstHolds == 0;
    if (should) {
      await _ensureLooping();
    } else {
      await _pauseOrStop();
    }
  }

  Future<void> _ensureLooping() async {
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_volume);
      if (player.playing) return;
      await player.setAudioSource(AudioSource.asset(_asset), preload: true);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderBgmPlayer: $e\n$st');
    }
  }

  Future<void> _pauseOrStop() async {
    final player = _player;
    if (player == null) return;
    try {
      // Pause during SFX burst so resume is cheap; full stop when leaving.
      if (_sfxBurstHolds > 0) {
        await player.pause();
      } else {
        await player.stop();
      }
    } catch (_) {}
  }

  Future<void> _stop() async {
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    _sessions = 0;
    _sfxBurstHolds = 0;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}

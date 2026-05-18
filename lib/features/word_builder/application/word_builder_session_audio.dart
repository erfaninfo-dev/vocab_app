import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/app_audio_session.dart';

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

final wordBuilderSessionAudioLifecycleProvider =
    Provider.autoDispose.family<int, int>((ref, bookKey) {
  final bgm = ref.read(wordBuilderBgmPlayerProvider);

  ref.listen<bool>(
    wordBuilderGameBgmEnabledProvider,
    (prev, next) {
      unawaited(bgm.applyFromRef(ref));
    },
  );

  unawaited(bgm.onEnter(ref));

  ref.onDispose(() {
    unawaited(bgm.onLeave());
  });

  return 0;
});

class WordBuilderGameSfxNotifier extends Notifier<bool> {
  static const _key = 'word_builder_session_sfx_v1';

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
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_key) ?? true;
      state = v;
      await ref.read(wordBuilderBgmPlayerProvider).applyFromRef(ref);
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
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

  Future<void> applyFromRef(Ref ref) async {
    _userWantsBgm = ref.read(wordBuilderGameBgmEnabledProvider);
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

  Future<void> _syncPlayback() async {
    final should = _sessions > 0 && _userWantsBgm;
    if (should) {
      await _ensureLooping();
    } else {
      await _stop();
    }
  }

  Future<void> _ensureLooping() async {
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_volume);
      if (player.playing) return;
      await player.setAudioSource(AudioSource.asset(_asset));
      await player.play();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WordBuilderBgmPlayer: $e\n$st');
      }
    }
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
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }
}

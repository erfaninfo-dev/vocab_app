import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';

enum WordBuilderSound {
  correct,
  wrong,
  levelComplete,
  gameOver,
  letterPop,
  /// Angry Words candy / barrier bubble pop (`pop.WAV`).
  candyPop,
}

class WordBuilderSoundService {
  static const _paths = {
    WordBuilderSound.correct: 'assets/audio/word_success.mp3',
    WordBuilderSound.wrong: 'assets/audio/word_error.mp3',
    WordBuilderSound.levelComplete: 'assets/audio/level_success.mp3',
    WordBuilderSound.gameOver: 'assets/audio/failure_game.mp3',
    WordBuilderSound.letterPop: 'assets/audio/letters_pop.MP3',
    WordBuilderSound.candyPop: 'assets/audio/pop.WAV',
  };

  static const _volumes = {
    WordBuilderSound.correct: 0.72,
    WordBuilderSound.wrong: 0.68,
    WordBuilderSound.levelComplete: 0.88,
    WordBuilderSound.gameOver: 0.9,
    WordBuilderSound.letterPop: 0.82,
    WordBuilderSound.candyPop: 0.86,
  };

  /// Windows `just_audio` is fragile under stop/seek thrash and missing assets.
  static bool get isFragileDesktopAudio =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  AudioPlayer? _player;
  WordBuilderSound? _loaded;
  Future<void> _queue = Future<void>.value();

  /// Plays [sound]. Calls are fully serialized (no mid-load cancel) so Windows
  /// does not leave the native player half-configured and silent.
  Future<void> play(WordBuilderSound sound, {required bool enabled}) {
    if (!enabled) return Future<void>.value();
    final done = Completer<void>();
    _queue = _queue
        .then((_) async {
          try {
            await _playExclusive(sound);
          } finally {
            if (!done.isCompleted) done.complete();
          }
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('WordBuilderSoundService: queue error ($e)\n$st');
          if (!done.isCompleted) done.complete();
        });
    return done.future;
  }

  Future<void> _playExclusive(WordBuilderSound sound) async {
    final path = _paths[sound]!;
    if (!await audioAssetExists(path)) {
      debugPrint('WordBuilderSoundService: missing asset $path');
      return;
    }

    var attemptedRecreate = false;
    while (true) {
      try {
        await configureAppAudioSession();
        final player = _player ??= AudioPlayer();

        try {
          if (player.playing) {
            await player.pause();
          }
        } catch (_) {}

        // Reload only when the clip changes (or after a failed seek).
        // Reloading every play on Windows was thrashing MediaPlayer / hanging.
        if (_loaded != sound || attemptedRecreate) {
          await player.setLoopMode(LoopMode.off);
          await player.setVolume(_volumes[sound]!);
          await player.setAudioSource(
            AudioSource.asset(path),
            preload: true,
          );
          _loaded = sound;
        } else {
          try {
            await player.seek(Duration.zero);
          } catch (_) {
            await player.setAudioSource(
              AudioSource.asset(path),
              preload: true,
            );
            _loaded = sound;
          }
          await player.setVolume(_volumes[sound]!);
        }

        // Await play so the next queued SFX starts on a settled player.
        await player.play();
        return;
      } catch (e, st) {
        debugPrint('WordBuilderSoundService: failed $sound ($e)\n$st');
        _loaded = null;
        await _recreatePlayer();
        if (attemptedRecreate) return;
        attemptedRecreate = true;
      }
    }
  }

  Future<void> _recreatePlayer() async {
    final old = _player;
    _player = null;
    _loaded = null;
    if (old == null) return;
    try {
      await old.stop();
    } catch (_) {}
    try {
      await old.dispose();
    } catch (_) {}
    // Brief gap so Windows MediaPlayer finishes Shutdown before a new instance.
    if (isFragileDesktopAudio) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> stop() async {
    final p = _player;
    if (p == null) return;
    try {
      await p.pause();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _recreatePlayer();
  }
}

final wordBuilderSoundServiceProvider = Provider<WordBuilderSoundService>((
  ref,
) {
  final service = WordBuilderSoundService();
  ref.onDispose(service.dispose);
  return service;
});

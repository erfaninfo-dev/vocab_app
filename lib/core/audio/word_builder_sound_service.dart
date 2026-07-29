import 'dart:async';
import 'dart:collection';

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
  /// Angry Words candy / barrier bubble pop (`pop.wav`).
  candyPop,
}

class WordBuilderSoundService {
  static const _paths = {
    WordBuilderSound.correct: 'assets/audio/word_success.mp3',
    WordBuilderSound.wrong: 'assets/audio/word_error.mp3',
    WordBuilderSound.levelComplete: 'assets/audio/level_success.mp3',
    WordBuilderSound.gameOver: 'assets/audio/failure_game.mp3',
    WordBuilderSound.letterPop: 'assets/audio/letters_pop.mp3',
    WordBuilderSound.candyPop: 'assets/audio/pop.wav',
  };

  static const _volumes = {
    WordBuilderSound.correct: 0.72,
    WordBuilderSound.wrong: 0.68,
    WordBuilderSound.levelComplete: 0.88,
    WordBuilderSound.gameOver: 0.9,
    WordBuilderSound.letterPop: 0.82,
    WordBuilderSound.candyPop: 0.86,
  };

  /// All known Word Builder sound-service asset paths (for tests).
  static Iterable<String> get allDeclaredAssetPaths => _paths.values;

  /// Windows `just_audio` is fragile under stop/seek thrash and missing assets.
  static bool get isFragileDesktopAudio =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Max simultaneous one-shots. Excess [play] calls are dropped (no delay).
  static int get maxConcurrentPlays => isFragileDesktopAudio ? 2 : 4;

  final _idlePlayers = Queue<AudioPlayer>();
  final _busyPlayers = <AudioPlayer>{};
  int _inFlight = 0;

  /// Plays [sound]. Concurrent up to [maxConcurrentPlays]; further requests
  /// are dropped immediately so cascades cannot stall or thrash Windows.
  Future<void> play(WordBuilderSound sound, {required bool enabled}) {
    if (!enabled) return Future<void>.value();
    if (_inFlight >= maxConcurrentPlays) {
      return Future<void>.value();
    }
    _inFlight++;
    return _playOnPool(sound).whenComplete(() {
      _inFlight = (_inFlight - 1).clamp(0, maxConcurrentPlays);
    });
  }

  Future<void> _playOnPool(WordBuilderSound sound) async {
    final path = _paths[sound]!;
    if (!await audioAssetExists(path)) {
      debugPrint('WordBuilderSoundService: missing asset $path');
      return;
    }

    AudioPlayer? player;
    try {
      await configureAppAudioSession();
      player = _idlePlayers.isNotEmpty
          ? _idlePlayers.removeFirst()
          : AudioPlayer();
      _busyPlayers.add(player);

      try {
        if (player.playing) await player.pause();
      } catch (_) {}

      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_volumes[sound]!);
      await player.setAudioSource(AudioSource.asset(path), preload: true);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderSoundService: failed $sound ($e)\n$st');
      if (player != null) {
        _busyPlayers.remove(player);
        try {
          await player.dispose();
        } catch (_) {}
        player = null;
      }
    } finally {
      if (player != null) {
        _busyPlayers.remove(player);
        // Keep a small idle pool; dispose extras to limit native handles.
        if (_idlePlayers.length < maxConcurrentPlays) {
          try {
            await player.pause();
          } catch (_) {}
          _idlePlayers.add(player);
        } else {
          try {
            await player.dispose();
          } catch (_) {}
        }
      }
    }
  }

  Future<void> stop() async {
    for (final p in [..._busyPlayers, ..._idlePlayers]) {
      try {
        await p.pause();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    final all = [..._busyPlayers, ..._idlePlayers];
    _busyPlayers.clear();
    _idlePlayers.clear();
    _inFlight = 0;
    for (final p in all) {
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }
}

final wordBuilderSoundServiceProvider = Provider<WordBuilderSoundService>((
  ref,
) {
  final service = WordBuilderSoundService();
  ref.onDispose(service.dispose);
  return service;
});

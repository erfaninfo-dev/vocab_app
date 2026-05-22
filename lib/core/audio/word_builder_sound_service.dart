import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';

enum WordBuilderSound {
  correct,
  wrong,
  levelComplete,
  gameOver,
}

class WordBuilderSoundService {
  static const _paths = {
    WordBuilderSound.correct: 'assets/audio/word_success.mp3',
    WordBuilderSound.wrong: 'assets/audio/word_error.mp3',
    WordBuilderSound.levelComplete: 'assets/audio/level_success.mp3',
    WordBuilderSound.gameOver: 'assets/audio/failure_game.mp3',
  };

  static const _volumes = {
    WordBuilderSound.correct: 0.72,
    WordBuilderSound.wrong: 0.68,
    WordBuilderSound.levelComplete: 0.88,
    WordBuilderSound.gameOver: 0.9,
  };

  AudioPlayer? _player;

  Future<void> play(WordBuilderSound sound, {required bool enabled}) async {
    if (!enabled) return;
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      final path = _paths[sound]!;
      await player.stop();
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_volumes[sound]!);
      await player.setAudioSource(
        AudioSource.asset(path),
        preload: true,
      );
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderSoundService: skipped $sound ($e)\n$st');
    }
  }

  Future<void> dispose() async {
    final p = _player;
    _player = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }
}

final wordBuilderSoundServiceProvider = Provider<WordBuilderSoundService>((ref) {
  final service = WordBuilderSoundService();
  ref.onDispose(service.dispose);
  return service;
});

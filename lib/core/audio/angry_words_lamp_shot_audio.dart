import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

class _LampShotVoice {
  _LampShotVoice(this.assetPath);

  final String assetPath;
  AudioPlayer? player;
  bool ready = false;
  bool busy = false;
}

/// Stage-6 oil-lamp hit — one of the glass-break samples in [assetPaths]
/// picked at random per shot ([WbPropArchetype.oilLamp]) so repeated hits
/// don't repeat.
class AngryWordsLampShotAudio {
  AngryWordsLampShotAudio({math.Random? random}) : _rng = random ?? math.Random();

  static const assetPaths = [
    'assets/audio/lampshot1.WAV',
    'assets/audio/lampshot3.WAV',
  ];

  final math.Random _rng;
  final List<_LampShotVoice> _voices = [
    for (final path in assetPaths) _LampShotVoice(path),
  ];
  DateTime? _lastPlayAt;

  Future<void> ensureLoaded() async {
    await configureAppAudioSession();
    for (final voice in _voices) {
      if (voice.ready) continue;
      if (!await audioAssetExists(voice.assetPath)) {
        debugPrint('AngryWordsLampShotAudio: missing ${voice.assetPath}');
        continue;
      }
      try {
        final player = voice.player ??= AudioPlayer();
        await player.setLoopMode(LoopMode.off);
        await player.setVolume(0.95);
        await player.setAudioSource(
          AudioSource.asset(voice.assetPath),
          preload: true,
        );
        voice.ready = true;
      } catch (e, st) {
        debugPrint(
          'AngryWordsLampShotAudio: load failed (${voice.assetPath}) ($e)\n$st',
        );
      }
    }
  }

  void play({required bool enabled}) {
    if (!enabled) return;
    final minGapMs = WordBuilderSoundService.isFragileDesktopAudio ? 140 : 80;
    final now = DateTime.now();
    if (_lastPlayAt != null &&
        now.difference(_lastPlayAt!).inMilliseconds < minGapMs) {
      return;
    }
    final idle = _voices.where((v) => v.ready && !v.busy).toList();
    final pool = idle.isNotEmpty ? idle : _voices.where((v) => v.ready).toList();
    if (pool.isEmpty) return;
    _lastPlayAt = now;
    unawaited(_playOnce(pool[_rng.nextInt(pool.length)]));
  }

  Future<void> _playOnce(_LampShotVoice voice) async {
    final player = voice.player;
    if (player == null || !voice.ready) return;
    voice.busy = true;
    try {
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      try {
        await player.seek(Duration.zero);
      } catch (_) {
        voice.ready = false;
        return;
      }
      unawaited(
        player.play().then<void>(
          (_) {},
          onError: (Object e, StackTrace st) {
            debugPrint('AngryWordsLampShotAudio: play error ($e)\n$st');
          },
        ),
      );
    } finally {
      voice.busy = false;
    }
  }

  Future<void> dispose() async {
    for (final voice in _voices) {
      final p = voice.player;
      voice.player = null;
      voice.ready = false;
      if (p == null) continue;
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }
}

final angryWordsLampShotAudioProvider =
    Provider<AngryWordsLampShotAudio>((ref) {
  final audio = AngryWordsLampShotAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

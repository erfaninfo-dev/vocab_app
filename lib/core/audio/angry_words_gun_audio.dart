import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

/// One-shot blaster SFX for Angry Words (`shot2.WAV` = a single shot).
///
/// Preloads once; each bullet only pause→seek→play (no reload thrash).
class AngryWordsGunAudio {
  static const assetPath = 'assets/audio/shot2.WAV';

  AudioPlayer? _player;
  bool _ready = false;
  bool _playBusy = false;
  DateTime? _lastPlayAt;

  bool get isReady => _ready;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    if (!await audioAssetExists(assetPath)) {
      debugPrint('AngryWordsGunAudio: missing $assetPath');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(0.48);
      await player.setAudioSource(
        AudioSource.asset(assetPath),
        preload: true,
      );
      _ready = true;
    } catch (e, st) {
      debugPrint('AngryWordsGunAudio: load failed ($e)\n$st');
      _ready = false;
    }
  }

  /// Play one shot. Safe under rapid fire — gated + never reloads the asset.
  void playShot({required bool enabled}) {
    if (!enabled) return;
    final minGapMs = WordBuilderSoundService.isFragileDesktopAudio ? 70 : 45;
    final now = DateTime.now();
    if (_lastPlayAt != null &&
        now.difference(_lastPlayAt!).inMilliseconds < minGapMs) {
      return;
    }
    if (_playBusy) return;
    _lastPlayAt = now;
    unawaited(_playOnce());
  }

  Future<void> _playOnce() async {
    await ensureLoaded();
    final player = _player;
    if (player == null || !_ready) return;
    _playBusy = true;
    try {
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      try {
        await player.setVolume(0.48);
      } catch (_) {}
      try {
        await player.seek(Duration.zero);
      } catch (_) {
        _ready = false;
        await ensureLoaded();
        final again = _player;
        if (again == null || !_ready) return;
        await again.seek(Duration.zero);
      }
      unawaited(
        player.play().then<void>(
          (_) {},
          onError: (Object e, StackTrace st) {
            debugPrint('AngryWordsGunAudio: play error ($e)\n$st');
          },
        ),
      );
    } catch (e, st) {
      debugPrint('AngryWordsGunAudio: skipped ($e)\n$st');
      _ready = false;
    } finally {
      _playBusy = false;
    }
  }

  Future<void> stop() async {
    final player = _player;
    if (player == null) return;
    try {
      await player.pause();
      await player.seek(Duration.zero);
    } catch (_) {}
  }

  Future<void> dispose() async {
    final p = _player;
    _player = null;
    _ready = false;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {}
  }
}

final angryWordsGunAudioProvider = Provider<AngryWordsGunAudio>((ref) {
  final audio = AngryWordsGunAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

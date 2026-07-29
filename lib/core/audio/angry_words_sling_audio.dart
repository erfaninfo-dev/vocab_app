import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

/// Looping rubber-band stretch SFX while the Angry Words slingshot is pulled.
///
/// Volume and playback speed rise with pull power so tension feels natural.
class AngryWordsSlingAudio {
  static const assetPath = 'assets/audio/sling_stretch.wav';

  AudioPlayer? _player;
  bool _ready = false;
  bool _active = false;
  bool _syncBusy = false;
  double _lastVolume = -1;
  double _lastSpeed = -1;
  DateTime? _lastParamAt;

  bool get isReady => _ready;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    if (!await audioAssetExists(assetPath)) {
      debugPrint('AngryWordsSlingAudio: missing $assetPath');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0.0);
      await player.setSpeed(1.0);
      await player.setAudioSource(
        AudioSource.asset(assetPath),
        preload: true,
      );
      _ready = true;
    } catch (e, st) {
      debugPrint('AngryWordsSlingAudio: load failed ($e)\n$st');
      _ready = false;
    }
  }

  /// Keep stretch audio in sync with aim/pull. Safe to call every frame.
  void sync({
    required bool enabled,
    required bool aiming,
    required double pullDistance,
    required double powerNorm,
    required double minPull,
  }) {
    if (!enabled || !aiming || pullDistance < minPull * 0.55) {
      if (_active) unawaited(stop());
      return;
    }
    unawaited(_syncActive(powerNorm.clamp(0.0, 1.0)));
  }

  Future<void> _syncActive(double power) async {
    if (_syncBusy) return;
    _syncBusy = true;
    try {
      await ensureLoaded();
      final player = _player;
      if (player == null || !_ready) return;

      final volume = (0.12 + power * 0.62).clamp(0.0, 0.78);
      // Slightly faster playback = higher tension pitch.
      final speed = WordBuilderSoundService.isFragileDesktopAudio
          ? 1.0
          : (0.88 + power * 0.42).clamp(0.85, 1.35);

      final now = DateTime.now();
      final throttleMs =
          WordBuilderSoundService.isFragileDesktopAudio ? 90 : 45;
      final allowParams = _lastParamAt == null ||
          now.difference(_lastParamAt!).inMilliseconds >= throttleMs;

      if (!_active) {
        try {
          await player.seek(Duration.zero);
        } catch (_) {
          _ready = false;
          await ensureLoaded();
        }
        final again = _player;
        if (again == null || !_ready) return;
        try {
          await again.setVolume(volume);
          if (!WordBuilderSoundService.isFragileDesktopAudio) {
            await again.setSpeed(speed);
          }
        } catch (_) {}
        _lastVolume = volume;
        _lastSpeed = speed;
        _lastParamAt = now;
        _active = true;
        unawaited(
          again.play().then<void>(
            (_) {},
            onError: (Object e, StackTrace st) {
              debugPrint('AngryWordsSlingAudio: play error ($e)\n$st');
              _active = false;
            },
          ),
        );
        return;
      }

      if (!allowParams) return;
      _lastParamAt = now;
      if ((volume - _lastVolume).abs() > 0.03) {
        try {
          await player.setVolume(volume);
          _lastVolume = volume;
        } catch (_) {}
      }
      if (!WordBuilderSoundService.isFragileDesktopAudio &&
          (speed - _lastSpeed).abs() > 0.04) {
        try {
          await player.setSpeed(speed);
          _lastSpeed = speed;
        } catch (_) {}
      }
      if (!player.playing) {
        unawaited(
          player.play().then<void>(
            (_) {},
            onError: (Object e, StackTrace st) {
              debugPrint('AngryWordsSlingAudio: resume error ($e)\n$st');
              _active = false;
            },
          ),
        );
      }
    } catch (e, st) {
      debugPrint('AngryWordsSlingAudio: sync skipped ($e)\n$st');
      _ready = false;
      _active = false;
    } finally {
      _syncBusy = false;
    }
  }

  Future<void> stop() async {
    _active = false;
    _lastVolume = -1;
    _lastSpeed = -1;
    final player = _player;
    if (player == null) return;
    try {
      if (player.playing) await player.pause();
      await player.setVolume(0);
      if (!WordBuilderSoundService.isFragileDesktopAudio) {
        await player.setSpeed(1.0);
      }
      await player.seek(Duration.zero);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _active = false;
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

final angryWordsSlingAudioProvider = Provider<AngryWordsSlingAudio>((ref) {
  final audio = AngryWordsSlingAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

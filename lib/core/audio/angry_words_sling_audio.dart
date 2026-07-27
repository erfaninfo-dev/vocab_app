import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

/// Angry Words slingshot Foley:
/// stretch loop (pitch/volume follow tension) → snap on release → optional whoosh.
class AngryWordsSlingAudio {
  static const stretchAsset = 'assets/audio/sling_stretch.wav';
  static const snapAsset = 'assets/audio/sling_snap.wav';
  static const whooshAsset = 'assets/audio/sling_whoosh.wav';

  AudioPlayer? _stretch;
  AudioPlayer? _snap;
  AudioPlayer? _whoosh;
  bool _stretchReady = false;
  bool _snapReady = false;
  bool _whooshReady = false;
  bool _active = false;
  bool _syncBusy = false;
  double _lastVolume = -1;
  double _lastSpeed = -1;
  DateTime? _lastParamAt;

  Future<void> ensureLoaded() async {
    await Future.wait([
      _ensureStretch(),
      _ensureOneShot(
        asset: snapAsset,
        getPlayer: () => _snap,
        setPlayer: (p) => _snap = p,
        isReady: () => _snapReady,
        setReady: (v) => _snapReady = v,
        label: 'snap',
      ),
      _ensureOneShot(
        asset: whooshAsset,
        getPlayer: () => _whoosh,
        setPlayer: (p) => _whoosh = p,
        isReady: () => _whooshReady,
        setReady: (v) => _whooshReady = v,
        label: 'whoosh',
      ),
    ]);
  }

  Future<void> _ensureStretch() async {
    if (_stretchReady) return;
    if (!await audioAssetExists(stretchAsset)) {
      debugPrint('AngryWordsSlingAudio: missing $stretchAsset');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = _stretch ??= AudioPlayer();
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0.0);
      await player.setSpeed(1.0);
      await player.setAudioSource(
        AudioSource.asset(stretchAsset),
        preload: true,
      );
      _stretchReady = true;
    } catch (e, st) {
      debugPrint('AngryWordsSlingAudio: stretch load failed ($e)\n$st');
      _stretchReady = false;
    }
  }

  Future<void> _ensureOneShot({
    required String asset,
    required AudioPlayer? Function() getPlayer,
    required void Function(AudioPlayer) setPlayer,
    required bool Function() isReady,
    required void Function(bool) setReady,
    required String label,
  }) async {
    if (isReady()) return;
    if (!await audioAssetExists(asset)) {
      debugPrint('AngryWordsSlingAudio: missing $asset');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = getPlayer() ?? AudioPlayer();
      setPlayer(player);
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(0.92);
      await player.setAudioSource(AudioSource.asset(asset), preload: true);
      setReady(true);
    } catch (e, st) {
      debugPrint('AngryWordsSlingAudio: $label load failed ($e)\n$st');
      setReady(false);
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
      if (_active) unawaited(stopStretch());
      return;
    }
    unawaited(_syncActive(powerNorm.clamp(0.0, 1.0)));
  }

  /// Volume 0.15→1.0 and pitch/speed 0.85→1.25 from tension.
  static double volumeForTension(double tension) =>
      (0.15 + tension.clamp(0.0, 1.0) * 0.85).clamp(0.15, 1.0);

  static double speedForTension(double tension) =>
      (0.85 + tension.clamp(0.0, 1.0) * 0.4).clamp(0.85, 1.25);

  Future<void> _syncActive(double tension) async {
    if (_syncBusy) return;
    _syncBusy = true;
    try {
      await _ensureStretch();
      final player = _stretch;
      if (player == null || !_stretchReady) return;

      // Soft-cap loudness on fragile Windows just_audio, keep curve shape.
      final fragile = WordBuilderSoundService.isFragileDesktopAudio;
      final volume = fragile
          ? (volumeForTension(tension) * 0.72).clamp(0.1, 0.78)
          : volumeForTension(tension);
      final speed = fragile ? 1.0 : speedForTension(tension);

      final now = DateTime.now();
      final throttleMs = fragile ? 90 : 40;
      final allowParams = _lastParamAt == null ||
          now.difference(_lastParamAt!).inMilliseconds >= throttleMs;

      if (!_active) {
        try {
          await player.seek(Duration.zero);
        } catch (_) {
          _stretchReady = false;
          await _ensureStretch();
        }
        final again = _stretch;
        if (again == null || !_stretchReady) return;
        try {
          await again.setVolume(volume);
          if (!fragile) await again.setSpeed(speed);
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
      if ((volume - _lastVolume).abs() > 0.025) {
        try {
          await player.setVolume(volume);
          _lastVolume = volume;
        } catch (_) {}
      }
      if (!fragile && (speed - _lastSpeed).abs() > 0.03) {
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
      _stretchReady = false;
      _active = false;
    } finally {
      _syncBusy = false;
    }
  }

  /// Stop stretch loop; if [launched], play snap (+ whoosh when charged).
  Future<void> onRelease({
    required bool enabled,
    required double powerNorm,
    required bool launched,
  }) async {
    await stopStretch();
    if (!enabled || !launched) return;
    await _playOneShot(_snap, () => _snapReady, 'snap');
    if (powerNorm >= 0.42) {
      // Slight delay so snap reads first, then flight whoosh.
      await Future<void>.delayed(const Duration(milliseconds: 28));
      await _playOneShot(_whoosh, () => _whooshReady, 'whoosh');
    }
  }

  Future<void> _playOneShot(
    AudioPlayer? player,
    bool Function() isReady,
    String label,
  ) async {
    await ensureLoaded();
    final p = player;
    if (p == null || !isReady()) return;
    try {
      try {
        if (p.playing) await p.pause();
      } catch (_) {}
      try {
        await p.seek(Duration.zero);
      } catch (_) {
        return;
      }
      unawaited(
        p.play().then<void>(
          (_) {},
          onError: (Object e, StackTrace st) {
            debugPrint('AngryWordsSlingAudio: $label play error ($e)\n$st');
          },
        ),
      );
    } catch (e, st) {
      debugPrint('AngryWordsSlingAudio: $label skipped ($e)\n$st');
    }
  }

  Future<void> stopStretch() async {
    _active = false;
    _lastVolume = -1;
    _lastSpeed = -1;
    final player = _stretch;
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

  /// Alias used by dispose / cancel paths.
  Future<void> stop() => stopStretch();

  Future<void> dispose() async {
    _active = false;
    final players = <AudioPlayer?>[_stretch, _snap, _whoosh];
    _stretch = null;
    _snap = null;
    _whoosh = null;
    _stretchReady = false;
    _snapReady = false;
    _whooshReady = false;
    for (final p in players) {
      if (p == null) continue;
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }
}

final angryWordsSlingAudioProvider = Provider<AngryWordsSlingAudio>((ref) {
  final audio = AngryWordsSlingAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

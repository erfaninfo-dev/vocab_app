import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

/// One-shot blaster SFX for Angry Words.
///
/// Alternates randomly between [assetPathPrimary] and [assetPathVariant]
/// (50/50) so rapid fire does not sound identical. Each clip has its own
/// preloaded [AudioPlayer].
class AngryWordsGunAudio {
  static const assetPathPrimary = 'assets/audio/shot2.wav';
  static const assetPathVariant = 'assets/audio/shot.wav';

  /// Declared paths for the asset-existence test.
  static const declaredAssetPaths = [assetPathPrimary, assetPathVariant];

  final _rng = math.Random();
  AudioPlayer? _primary;
  AudioPlayer? _variant;
  bool _primaryReady = false;
  bool _variantReady = false;
  bool _playBusy = false;
  DateTime? _lastPlayAt;

  bool get isReady => _primaryReady || _variantReady;

  Future<void> ensureLoaded() async {
    await Future.wait([_ensureOne(true), _ensureOne(false)]);
  }

  Future<void> _ensureOne(bool primary) async {
    if (primary ? _primaryReady : _variantReady) return;
    final path = primary ? assetPathPrimary : assetPathVariant;
    if (!await audioAssetExists(path)) {
      debugPrint('AngryWordsGunAudio: missing $path');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = primary ? (_primary ??= AudioPlayer()) : (_variant ??= AudioPlayer());
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(0.48);
      await player.setAudioSource(AudioSource.asset(path), preload: true);
      if (primary) {
        _primaryReady = true;
      } else {
        _variantReady = true;
      }
    } catch (e, st) {
      debugPrint('AngryWordsGunAudio: load failed $path ($e)\n$st');
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
    final useVariant = _variantReady && (!_primaryReady || _rng.nextBool());
    final player = useVariant ? _variant : _primary;
    final ready = useVariant ? _variantReady : _primaryReady;
    if (player == null || !ready) return;
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
        if (useVariant) {
          _variantReady = false;
        } else {
          _primaryReady = false;
        }
        await ensureLoaded();
        final again = useVariant ? _variant : _primary;
        final againReady = useVariant ? _variantReady : _primaryReady;
        if (again == null || !againReady) return;
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
    } finally {
      _playBusy = false;
    }
  }

  Future<void> stop() async {
    for (final player in [_primary, _variant]) {
      if (player == null) continue;
      try {
        await player.pause();
        await player.seek(Duration.zero);
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    final players = [_primary, _variant];
    _primary = null;
    _variant = null;
    _primaryReady = false;
    _variantReady = false;
    for (final p in players) {
      if (p == null) continue;
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }
}

final angryWordsGunAudioProvider = Provider<AngryWordsGunAudio>((ref) {
  final audio = AngryWordsGunAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

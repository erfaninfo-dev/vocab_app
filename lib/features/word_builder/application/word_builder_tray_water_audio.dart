import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/app_audio_session.dart';
import '../../../core/audio/audio_asset_probe.dart';

enum _TrayWaterLoopTier { stage2, stage3 }

class WordBuilderTrayWaterAudio {
  static const _pillPath = 'assets/audio/water_pill.mp3';
  static const _drown2Path = 'assets/audio/drown2.mp3';
  static const _drown3Path = 'assets/audio/drown3.mp3';

  static const _pillVolume = 0.72;
  static const _loopVolume = 0.62;

  AudioPlayer? _pillPlayer;
  AudioPlayer? _loopPlayer;
  StreamSubscription<ProcessingState>? _loopStateSub;
  _TrayWaterLoopTier? _activeLoopTier;

  _TrayWaterLoopTier? _loopTierForWrongCount(int wrongCount) {
    if (wrongCount >= 3) return _TrayWaterLoopTier.stage3;
    if (wrongCount >= 2) return _TrayWaterLoopTier.stage2;
    return null;
  }

  String _pathForTier(_TrayWaterLoopTier tier) => switch (tier) {
        _TrayWaterLoopTier.stage2 => _drown2Path,
        _TrayWaterLoopTier.stage3 => _drown3Path,
      };

  Future<void> onWrongAnswer(int wrongCount, {required bool enabled}) async {
    if (!enabled) {
      await stopAll();
      return;
    }
    unawaited(_playPill());
    await syncWaterStage(wrongCount, enabled: enabled);
  }

  Future<void> playPillOnly({required bool enabled}) async {
    if (!enabled) return;
    await _playPill();
  }

  Future<void> syncWaterStage(int wrongCount, {required bool enabled}) async {
    if (!enabled) {
      await stopLoops();
      return;
    }
    await _syncLoopTier(_loopTierForWrongCount(wrongCount));
  }

  Future<void> stopLoops() async {
    _activeLoopTier = null;
    _loopStateSub?.cancel();
    _loopStateSub = null;
    final player = _loopPlayer;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> stopAll() async {
    await stopLoops();
    final pill = _pillPlayer;
    if (pill != null) {
      try {
        await pill.stop();
      } catch (_) {}
    }
  }

  Future<void> _playPill() async {
    final player = _pillPlayer ??= AudioPlayer();
    await _playAsset(
      player: player,
      assetPath: _pillPath,
      volume: _pillVolume,
    );
  }

  Future<void> _playAsset({
    required AudioPlayer player,
    required String assetPath,
    required double volume,
  }) async {
    if (!await audioAssetExists(assetPath)) return;
    try {
      await configureAppAudioSession();
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(volume);
      await player.setAudioSource(
        AudioSource.asset(assetPath),
        preload: true,
      );
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderTrayWaterAudio: failed $assetPath ($e)\n$st');
    }
  }

  Future<void> _syncLoopTier(_TrayWaterLoopTier? tier) async {
    if (tier == null) {
      await stopLoops();
      return;
    }
    final path = _pathForTier(tier);
    if (!await audioAssetExists(path)) {
      _activeLoopTier = null;
      return;
    }
    if (_activeLoopTier == tier) {
      final player = _loopPlayer;
      if (player != null && player.playing) return;
    }

    _activeLoopTier = tier;
    _loopStateSub?.cancel();
    _loopStateSub = null;

    try {
      final player = _loopPlayer ??= AudioPlayer();
      await configureAppAudioSession();
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_loopVolume);
      await player.setAudioSource(
        AudioSource.asset(path),
        preload: true,
      );
      _attachLoopRestart(player, tier);
      await player.play();
    } catch (e, st) {
      _activeLoopTier = null;
      debugPrint(
        'WordBuilderTrayWaterAudio: loop skipped $path ($e)\n$st',
      );
    }
  }

  void _attachLoopRestart(AudioPlayer player, _TrayWaterLoopTier tier) {
    _loopStateSub = player.processingStateStream.listen((state) {
      if (state != ProcessingState.completed) return;
      if (_activeLoopTier != tier) return;
      unawaited(_restartLoopIfStillActive(tier));
    });
  }

  Future<void> _restartLoopIfStillActive(_TrayWaterLoopTier tier) async {
    if (_activeLoopTier != tier) return;
    final player = _loopPlayer;
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      if (_activeLoopTier == tier) await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderTrayWaterAudio: loop restart ($e)\n$st');
    }
  }

  Future<void> dispose() async {
    await stopAll();
    _loopStateSub?.cancel();
    _loopStateSub = null;
    final pill = _pillPlayer;
    _pillPlayer = null;
    final loop = _loopPlayer;
    _loopPlayer = null;
    if (pill != null) {
      try {
        await pill.dispose();
      } catch (_) {}
    }
    if (loop != null) {
      try {
        await loop.dispose();
      } catch (_) {}
    }
  }
}

final wordBuilderTrayWaterAudioProvider =
    Provider.autoDispose.family<WordBuilderTrayWaterAudio, int>((ref, bookKey) {
  final service = WordBuilderTrayWaterAudio();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

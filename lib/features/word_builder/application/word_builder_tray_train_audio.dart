import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/app_audio_session.dart';
import '../../../core/audio/audio_asset_probe.dart';

/// SFX for the train-escape tray scenario.
///
/// Mirrors [WordBuilderTrayWaterAudio]: one-shot player for horn / rope /
/// brake / pass, plus a looping "approaching train" rumble whose intensity
/// follows the wrong-answer count. Missing assets are skipped silently.
class WordBuilderTrayTrainAudio {
  static const _hornPath = 'assets/audio/train_horn.mp3';
  static const _ropeSnapPath = 'assets/audio/rope_snap.mp3';
  static const _brakePath = 'assets/audio/train_brake.mp3';
  static const _trainPassPath = 'assets/audio/train_pass.mp3';
  static const _approachLoopPath = 'assets/audio/train_approach.mp3';

  static const _oneShotVolume = 0.78;
  static const _ropeVolume = 0.7;
  static const _loopBaseVolume = 0.34;
  static const _loopMaxVolume = 0.7;

  AudioPlayer? _oneShotPlayer;
  AudioPlayer? _loopPlayer;
  StreamSubscription<ProcessingState>? _loopStateSub;
  int _activeLoopStage = 0;

  double _loopVolumeForStage(int stage) {
    final t = ((stage - 2) / 3).clamp(0.0, 1.0);
    return _loopBaseVolume + (_loopMaxVolume - _loopBaseVolume) * t;
  }

  /// Horn blast + louder approach rumble on every wrong answer.
  Future<void> onWrongAnswer(int wrongCount, {required bool enabled}) async {
    if (!enabled) {
      await stopAll();
      return;
    }
    unawaited(_playOneShot(_hornPath, volume: _oneShotVolume));
    await syncTensionStage(wrongCount, enabled: enabled);
  }

  Future<void> onRopeBreak({required bool enabled}) async {
    if (!enabled) return;
    await _playOneShot(_ropeSnapPath, volume: _ropeVolume);
  }

  Future<void> onTrainPass({required bool enabled}) async {
    if (!enabled) return;
    await _playOneShot(_trainPassPath, volume: _oneShotVolume);
  }

  Future<void> onGameOverBrake({required bool enabled}) async {
    await stopLoops();
    if (!enabled) return;
    await _playOneShot(_brakePath, volume: 0.9);
  }

  /// Keeps the approach rumble in sync with the wrong-answer count:
  /// silent below 2 wrongs, then progressively louder.
  Future<void> syncTensionStage(int wrongCount, {required bool enabled}) async {
    if (!enabled || wrongCount < 2) {
      await stopLoops();
      return;
    }
    await _syncLoop(wrongCount);
  }

  Future<void> stopLoops() async {
    _activeLoopStage = 0;
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
    final oneShot = _oneShotPlayer;
    if (oneShot != null) {
      try {
        await oneShot.stop();
      } catch (_) {}
    }
  }

  Future<void> _playOneShot(String assetPath, {required double volume}) async {
    if (!await audioAssetExists(assetPath)) return;
    final player = _oneShotPlayer ??= AudioPlayer();
    try {
      await configureAppAudioSession();
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(volume);
      await player.setAudioSource(AudioSource.asset(assetPath), preload: true);
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderTrayTrainAudio: skipped $assetPath ($e)\n$st');
    }
  }

  Future<void> _syncLoop(int stage) async {
    if (!await audioAssetExists(_approachLoopPath)) {
      _activeLoopStage = 0;
      return;
    }
    if (_activeLoopStage == stage) {
      final player = _loopPlayer;
      if (player != null && player.playing) return;
    }
    final wasPlaying = _activeLoopStage >= 2;
    _activeLoopStage = stage;

    try {
      final player = _loopPlayer ??= AudioPlayer();
      await configureAppAudioSession();
      if (wasPlaying && player.playing) {
        // Same asset keeps looping; only the volume ramps up.
        await player.setVolume(_loopVolumeForStage(stage));
        return;
      }
      _loopStateSub?.cancel();
      _loopStateSub = null;
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_loopVolumeForStage(stage));
      await player.setAudioSource(
        AudioSource.asset(_approachLoopPath),
        preload: true,
      );
      _attachLoopRestart(player);
      await player.play();
    } catch (e, st) {
      _activeLoopStage = 0;
      debugPrint(
        'WordBuilderTrayTrainAudio: loop skipped $_approachLoopPath ($e)\n$st',
      );
    }
  }

  void _attachLoopRestart(AudioPlayer player) {
    _loopStateSub = player.processingStateStream.listen((state) {
      if (state != ProcessingState.completed) return;
      if (_activeLoopStage < 2) return;
      unawaited(_restartLoopIfStillActive());
    });
  }

  Future<void> _restartLoopIfStillActive() async {
    if (_activeLoopStage < 2) return;
    final player = _loopPlayer;
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      if (_activeLoopStage >= 2) await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderTrayTrainAudio: loop restart ($e)\n$st');
    }
  }

  Future<void> dispose() async {
    await stopAll();
    _loopStateSub?.cancel();
    _loopStateSub = null;
    final oneShot = _oneShotPlayer;
    _oneShotPlayer = null;
    final loop = _loopPlayer;
    _loopPlayer = null;
    if (oneShot != null) {
      try {
        await oneShot.dispose();
      } catch (_) {}
    }
    if (loop != null) {
      try {
        await loop.dispose();
      } catch (_) {}
    }
  }
}

final wordBuilderTrayTrainAudioProvider =
    Provider.autoDispose.family<WordBuilderTrayTrainAudio, int>((ref, bookKey) {
  final service = WordBuilderTrayTrainAudio();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

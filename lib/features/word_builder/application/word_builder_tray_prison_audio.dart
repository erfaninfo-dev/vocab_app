import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/app_audio_session.dart';
import '../../../core/audio/audio_asset_probe.dart';
import '../../../core/audio/word_builder_sound_service.dart';

/// SFX for the prison-escape tray scenario.
///
/// Mirrors [WordBuilderTrayTrainAudio]: a one-shot player for guard stirs /
/// key jingles / door unlock / guard waking, plus a looping heartbeat whose
/// volume ramps with the wrong-answer count. Missing assets are skipped
/// silently so the game never crashes without them.
class WordBuilderTrayPrisonAudio {
  static const _stirPath = 'assets/audio/guard_stir.mp3';
  static const _keyJinglePath = 'assets/audio/key_jingle.mp3';
  static const _doorUnlockPath = 'assets/audio/door_unlock.mp3';
  static const _wakePath = 'assets/audio/guard_wake.mp3';
  static const _heartbeatLoopPath = 'assets/audio/heartbeat.mp3';

  static const _oneShotVolume = 0.72;
  static const _keyVolume = 0.66;
  static const _loopBaseVolume = 0.3;
  static const _loopMaxVolume = 0.68;

  AudioPlayer? _oneShotPlayer;
  AudioPlayer? _loopPlayer;
  StreamSubscription<ProcessingState>? _loopStateSub;
  int _activeLoopStage = 0;

  double _loopVolumeForStage(int stage) {
    final t = ((stage - 2) / 3).clamp(0.0, 1.0);
    return _loopBaseVolume + (_loopMaxVolume - _loopBaseVolume) * t;
  }

  /// Guard stir + louder heartbeat on every wrong answer.
  Future<void> onWrongAnswer(int wrongCount, {required bool enabled}) async {
    if (!enabled) {
      await stopAll();
      return;
    }
    unawaited(_playOneShot(_stirPath, volume: _oneShotVolume));
    await syncTensionStage(wrongCount, enabled: enabled);
  }

  Future<void> onKeyJingle({required bool enabled}) async {
    if (!enabled) return;
    await _playOneShot(_keyJinglePath, volume: _keyVolume);
  }

  Future<void> onDoorUnlock({required bool enabled}) async {
    if (!enabled) return;
    await _playOneShot(_doorUnlockPath, volume: _oneShotVolume);
  }

  Future<void> onGameOverWake({required bool enabled}) async {
    await stopLoops();
    if (!enabled) return;
    await _playOneShot(_wakePath, volume: 0.85);
  }

  /// Heartbeat loop kicks in from 2 wrongs and gets louder toward danger.
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
      await player.pause();
    } catch (_) {}
  }

  Future<void> stopAll() async {
    await stopLoops();
    final oneShot = _oneShotPlayer;
    if (oneShot != null) {
      try {
        await oneShot.pause();
      } catch (_) {}
    }
  }

  Future<void> _playOneShot(String assetPath, {required double volume}) async {
    if (!await audioAssetExists(assetPath)) return;

    try {
      await configureAppAudioSession();
      final player = _oneShotPlayer ??= AudioPlayer();
      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(volume);
      await player.setAudioSource(AudioSource.asset(assetPath), preload: true);
      await player.play();
    } catch (e, st) {
      debugPrint('WordBuilderTrayPrisonAudio: skipped $assetPath ($e)\n$st');
      await _recreateOneShot();
    }
  }

  Future<void> _recreateOneShot() async {
    final old = _oneShotPlayer;
    _oneShotPlayer = null;
    if (old == null) return;
    try {
      await old.dispose();
    } catch (_) {}
    if (WordBuilderSoundService.isFragileDesktopAudio) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _syncLoop(int stage) async {
    if (!await audioAssetExists(_heartbeatLoopPath)) {
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
        AudioSource.asset(_heartbeatLoopPath),
        preload: true,
      );
      _attachLoopRestart(player);
      await player.play();
    } catch (e, st) {
      _activeLoopStage = 0;
      debugPrint(
        'WordBuilderTrayPrisonAudio: loop skipped $_heartbeatLoopPath ($e)\n$st',
      );
      await _recreateLoop();
    }
  }

  Future<void> _recreateLoop() async {
    _loopStateSub?.cancel();
    _loopStateSub = null;
    final old = _loopPlayer;
    _loopPlayer = null;
    if (old == null) return;
    try {
      await old.dispose();
    } catch (_) {}
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
      debugPrint('WordBuilderTrayPrisonAudio: loop restart ($e)\n$st');
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

final wordBuilderTrayPrisonAudioProvider = Provider.autoDispose
    .family<WordBuilderTrayPrisonAudio, int>((ref, bookKey) {
  final service = WordBuilderTrayPrisonAudio();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

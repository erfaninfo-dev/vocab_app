import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

/// One-shot rubber snap when the Angry Words slingshot is released.
class AngryWordsSlingSnapAudio {
  static const assetPath = 'assets/audio/sling_snap.wav';

  AudioPlayer? _player;
  bool _ready = false;
  bool _playBusy = false;
  DateTime? _lastPlayAt;

  Future<void> ensureLoaded() async {
    if (_ready) return;
    if (!await audioAssetExists(assetPath)) {
      debugPrint('AngryWordsSlingSnapAudio: missing $assetPath');
      return;
    }
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(0.72);
      await player.setAudioSource(AudioSource.asset(assetPath), preload: true);
      _ready = true;
    } catch (e, st) {
      debugPrint('AngryWordsSlingSnapAudio: load failed ($e)\n$st');
      _ready = false;
    }
  }

  void play({required bool enabled}) {
    if (!enabled) return;
    final minGapMs = WordBuilderSoundService.isFragileDesktopAudio ? 120 : 80;
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
            debugPrint('AngryWordsSlingSnapAudio: play error ($e)\n$st');
          },
        ),
      );
    } catch (e, st) {
      debugPrint('AngryWordsSlingSnapAudio: skipped ($e)\n$st');
      _ready = false;
    } finally {
      _playBusy = false;
    }
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

final angryWordsSlingSnapAudioProvider = Provider<AngryWordsSlingSnapAudio>((
  ref,
) {
  final audio = AngryWordsSlingSnapAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

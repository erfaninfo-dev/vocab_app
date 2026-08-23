import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import '../../features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart';
import 'app_audio_session.dart';
import 'audio_asset_probe.dart';
import 'word_builder_sound_service.dart';

class _BreakVoice {
  AudioPlayer? player;
  String? loadedPath;
  bool busy = false;
  bool ready = false;
  /// Lower = nearer to impact (higher priority).
  double priority = double.infinity;
  DateTime startedAt = DateTime.fromMillisecondsSinceEpoch(0);
}

/// Concurrent prop-break SFX: 8 families → existing assets + pitch.
///
/// Caps simultaneous voices (6 mobile / 3 Windows). Excess is **dropped**,
/// never delayed. Near-impact sounds can steal the farthest busy voice.
class AngryWordsPropBreakAudio {
  AngryWordsPropBreakAudio({math.Random? random})
      : _rng = random ?? math.Random() {
    final n = WordBuilderSoundService.isFragileDesktopAudio
        ? kMaxVoicesWindows
        : kMaxVoicesMobile;
    _voices = List<_BreakVoice>.generate(n, (_) => _BreakVoice());
  }

  static const kMaxVoicesMobile = 6;
  static const kMaxVoicesWindows = 3;

  final math.Random _rng;
  late final List<_BreakVoice> _voices;
  bool _sessionReady = false;

  int get voiceCount => _voices.length;

  Future<void> ensureLoaded() async {
    if (_sessionReady) return;
    await configureAppAudioSession();
    _sessionReady = true;
  }

  /// Play a break for [spec]. [applyJitter] false for bronze-bell HP pitches.
  ///
  /// [priority] — distance to last hit in px (0 = at impact). Lower wins.
  void play({
    required WbPropSoundFamily family,
    required double basePitch,
    required bool enabled,
    bool applyJitter = true,
    double priority = 0,
  }) {
    if (!enabled) return;
    final pitch = applyJitter
        ? (basePitch * (0.94 + _rng.nextDouble() * 0.12)).clamp(0.5, 1.5)
        : basePitch.clamp(0.5, 1.5);

    final voice = _pickVoice(priority);
    if (voice == null) return; // drop
    voice.priority = priority;
    voice.startedAt = DateTime.now();
    unawaited(_playOnVoice(voice, family, pitch));
  }

  void playFromSpec({
    required WbArchetypeSpec spec,
    required bool enabled,
    bool applyJitter = true,
    double priority = 0,
  }) {
    play(
      family: spec.soundFamily,
      basePitch: spec.soundPitch,
      enabled: enabled,
      applyJitter: applyJitter,
      priority: priority,
    );
  }

  /// Bronze bell HP cue — no random jitter.
  void playBellHp({
    required int hp,
    required bool enabled,
    double priority = 0,
  }) {
    final pitch = switch (hp) {
      >= 3 => 1.20,
      2 => 1.00,
      _ => 0.80,
    };
    play(
      family: WbPropSoundFamily.clangMetal,
      basePitch: pitch,
      enabled: enabled,
      applyJitter: false,
      priority: priority,
    );
  }

  _BreakVoice? _pickVoice(double priority) {
    for (final v in _voices) {
      if (!v.busy) return v;
    }
    // All busy: steal farthest (highest priority value) if new is nearer.
    _BreakVoice? farthest;
    for (final v in _voices) {
      if (farthest == null || v.priority > farthest.priority) {
        farthest = v;
      }
    }
    if (farthest == null) return null;
    if (priority < farthest.priority) return farthest;
    return null; // drop — new sound is farther than everything playing
  }

  Future<void> _playOnVoice(
    _BreakVoice voice,
    WbPropSoundFamily family,
    double pitch,
  ) async {
    voice.busy = true;
    try {
      await ensureLoaded();
      var path = family.assetPath;
      if (!await audioAssetExists(path)) {
        path = family.fallbackAssetPath;
        if (!await audioAssetExists(path)) return;
      }

      final player = voice.player ??= AudioPlayer();
      if (voice.loadedPath != path || !voice.ready) {
        try {
          await player.setLoopMode(LoopMode.off);
          await player.setVolume(0.88);
          await player.setAudioSource(AudioSource.asset(path), preload: true);
          voice.loadedPath = path;
          voice.ready = true;
        } catch (e, st) {
          debugPrint('AngryWordsPropBreakAudio: load failed ($e)\n$st');
          voice.ready = false;
          return;
        }
      }

      try {
        if (player.playing) await player.pause();
      } catch (_) {}
      try {
        await player.setSpeed(pitch);
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
            debugPrint('AngryWordsPropBreakAudio: play error ($e)\n$st');
          },
        ),
      );
      // Short SFX — free the voice after a bounded window so concurrency works.
      await Future<void>.delayed(const Duration(milliseconds: 280));
    } finally {
      voice.busy = false;
      voice.priority = double.infinity;
    }
  }

  Future<void> dispose() async {
    for (final v in _voices) {
      final p = v.player;
      v.player = null;
      v.ready = false;
      if (p == null) continue;
      try {
        await p.stop();
        await p.dispose();
      } catch (_) {}
    }
  }
}

final angryWordsPropBreakAudioProvider =
    Provider<AngryWordsPropBreakAudio>((ref) {
  final audio = AngryWordsPropBreakAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

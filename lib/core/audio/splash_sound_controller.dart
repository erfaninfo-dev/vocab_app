import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted toggle + helper for playing the calming splash chime.
///
/// Behavior:
/// - Default: enabled.
/// - The mp3 lives at `assets/audio/splash_chime.mp3`. If it is missing or
///   playback fails (e.g. silent mode on iOS, no audio device), we swallow
///   the error so the app boot is never blocked.
/// - Audio plays asynchronously; navigation in the splash screen is
///   independent of how long the sound takes.
class SplashSoundController extends Notifier<bool> {
  static const _storageKey = 'splash_sound_enabled';
  // audioplayers' AssetSource expects a path relative to Flutter's assets root.
  // Given pubspec includes `assets/audio/`, this should NOT start with `assets/`.
  static const _assetPath = 'audio/splash_chime.mp3';
  static const double _volume = 0.55;

  AudioPlayer? _player;

  @override
  bool build() {
    _loadFromStorage();
    return true;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_storageKey);
      if (saved != null && saved != state) {
        state = saved;
      }
    } catch (_) {
      // Keep default (enabled) when prefs are unavailable.
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, value);
    } catch (_) {
      // Persistence failure is non-fatal; in-memory state still updates.
    }
    if (!value) {
      await _stopAndDispose();
    }
  }

  /// Plays the splash chime if enabled. Safe to await or fire-and-forget.
  Future<void> playIfEnabled() async {
    if (!state) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      // Mobile-only: set audio context so the OS can respect silent mode.
      // On desktop, setAudioContext may throw / be unsupported.
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
              options: const {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
      }
      await player.setVolume(_volume);
      await player.play(AssetSource(_assetPath));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SplashSoundController: playback skipped ($e)');
      }
    }
  }

  Future<void> _stopAndDispose() async {
    final p = _player;
    _player = null;
    if (p == null) return;
    try {
      await p.stop();
      await p.dispose();
    } catch (_) {
      // Ignore — controller is shutting down playback.
    }
  }
}

final splashSoundProvider =
    NotifierProvider<SplashSoundController, bool>(SplashSoundController.new);

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_audio_session.dart';

class SplashSoundController extends Notifier<bool> {
  static const _storageKey = 'splash_sound_enabled';
  static const _assetPath = 'assets/audio/splash_chime.mp3';
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
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, value);
    } catch (_) {}
    if (!value) {
      await _stopAndDispose();
    }
  }

  Future<void> playIfEnabled() async {
    if (!state) return;
    try {
      await configureAppAudioSession();
      final player = _player ??= AudioPlayer();
      await player.setLoopMode(LoopMode.off);
      await player.setVolume(_volume);
      await player.setAudioSource(
        AudioSource.asset(_assetPath),
        preload: true,
      );
      await player.seek(Duration.zero);
      await player.play();
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
    } catch (_) {}
  }
}

final splashSoundProvider =
    NotifierProvider<SplashSoundController, bool>(SplashSoundController.new);

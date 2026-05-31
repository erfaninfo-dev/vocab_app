import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/app_audio_session.dart';

const _prefsKey = 'sample_book_page_sound_enabled_v1';
const _pageFlipAssetPath = 'assets/audio/page_flip.mp3';

final sampleBookPageSoundEnabledProvider =
    NotifierProvider<SampleBookPageSoundEnabledController, bool>(
      SampleBookPageSoundEnabledController.new,
    );

class SampleBookPageSoundEnabledController extends Notifier<bool> {
  @override
  bool build() {
    _hydrate();
    return true;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsKey)) return;
    state = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, next);
  }
}

class SampleBookPageSoundService {
  AudioPlayer? _player;
  String? _loadedAssetPath;
  static const _minPlayGap = Duration(milliseconds: 380);
  DateTime? _lastPlayedAt;

  Future<void> warmUp() async {
    await _ensurePlayerLoaded(_pageFlipAssetPath);
  }

  Future<void> playPageTurn({
    required bool enabled,
    required bool forward,
    bool Function()? isStillEnabled,
  }) async {
    if (!enabled) return;
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        now.difference(_lastPlayedAt!) < _minPlayGap) {
      return;
    }
    _lastPlayedAt = now;
    try {
      final player = await _ensurePlayerLoaded(_pageFlipAssetPath);
      if (player == null) return;
      if (isStillEnabled != null && !isStillEnabled()) return;
      await player.setVolume(forward ? 0.58 : 0.5);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('SampleBookPageSoundService: skipped page turn ($e)\n$st');
    }
  }

  Future<AudioPlayer?> _ensurePlayerLoaded(String assetPath) async {
    try {
      await configureAppAudioSession();
      if (_player != null && _loadedAssetPath == assetPath) {
        return _player;
      }
      await _disposePlayer();
      final player = AudioPlayer();
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        AudioSource.asset(assetPath),
        preload: true,
      );
      _player = player;
      _loadedAssetPath = assetPath;
      return player;
    } catch (e, st) {
      debugPrint('SampleBookPageSoundService: load failed ($e)\n$st');
      return null;
    }
  }

  Future<void> stop() async {
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    _loadedAssetPath = null;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _lastPlayedAt = null;
    await _disposePlayer();
  }
}

final sampleBookPageSoundServiceProvider = Provider<SampleBookPageSoundService>((
  ref,
) {
  final service = SampleBookPageSoundService();
  ref.onDispose(service.dispose);
  return service;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/arkanoid_ball_speed.dart';

final arkanoidBallSpeedProvider =
    NotifierProvider<ArkanoidBallSpeedNotifier, int>(
      ArkanoidBallSpeedNotifier.new,
    );

class ArkanoidBallSpeedNotifier extends Notifier<int> {
  static const _key = 'word_builder_arkanoid_ball_speed_level_v1';
  static const _legacyKey = 'word_builder_arkanoid_ball_speed_v1';

  @override
  int build() {
    Future.microtask(_load);
    return ArkanoidBallSpeedScale.defaultLevel;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_key);
      final legacy = prefs.getString(_legacyKey);
      final next = ArkanoidBallSpeedScale.fromPrefs(legacy, intRaw: stored);
      if (next != state) state = next;
    } catch (_) {}
  }

  Future<void> setLevel(int level) async {
    final next = ArkanoidBallSpeedScale.clampLevel(level);
    if (state == next) return;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, next);
    } catch (_) {}
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_play_mode.dart';

final wordBuilderPlayModeProvider =
    NotifierProvider<WordBuilderPlayModeNotifier, WordBuilderPlayMode>(
      WordBuilderPlayModeNotifier.new,
    );

class WordBuilderPlayModeNotifier extends Notifier<WordBuilderPlayMode> {
  static const _key = 'word_builder_play_mode_v1';

  @override
  WordBuilderPlayMode build() {
    Future.microtask(_load);
    return WordBuilderPlayMode.classic;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = WordBuilderPlayModeX.fromPrefs(prefs.getString(_key));
      if (next != state) state = next;
    } catch (_) {}
  }

  Future<void> setMode(WordBuilderPlayMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.prefsValue);
    } catch (_) {}
  }

  Future<void> toggle() {
    final next = switch (state) {
      WordBuilderPlayMode.classic => WordBuilderPlayMode.arkanoid,
      WordBuilderPlayMode.arkanoid => WordBuilderPlayMode.angryWords,
      WordBuilderPlayMode.angryWords => WordBuilderPlayMode.puzzle,
      WordBuilderPlayMode.puzzle => WordBuilderPlayMode.classic,
    };
    return setMode(next);
  }
}

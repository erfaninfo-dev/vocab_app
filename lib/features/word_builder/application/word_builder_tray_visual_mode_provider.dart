import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_tray_visual_mode.dart';

final wordBuilderTrayVisualModeProvider =
    NotifierProvider<
      WordBuilderTrayVisualModeNotifier,
      WordBuilderTrayVisualMode
    >(WordBuilderTrayVisualModeNotifier.new);

final wordBuilderGameGlassSfxEnabledProvider =
    NotifierProvider<WordBuilderGameGlassSfxNotifier, bool>(
      WordBuilderGameGlassSfxNotifier.new,
    );

class WordBuilderTrayVisualModeNotifier
    extends Notifier<WordBuilderTrayVisualMode> {
  static const _key = 'word_builder_tray_visual_mode_v1';

  @override
  WordBuilderTrayVisualMode build() {
    Future.microtask(_load);
    return WordBuilderTrayVisualMode.water;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final mode = WordBuilderTrayVisualModeX.fromPrefs(raw);
      if (mode != state) state = mode;
    } catch (_) {}
  }

  Future<void> setMode(WordBuilderTrayVisualMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.prefsValue);
    } catch (_) {}
  }
}

class WordBuilderGameGlassSfxNotifier extends Notifier<bool> {
  static const _key = 'word_builder_session_glass_sfx_v1';

  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_key) ?? true;
      if (v != state) state = v;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (state == value) return;
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_play_mode.dart';
import '../presentation/widgets/angry_words/angry_words_loadout.dart';

final wordBuilderPlayModeProvider =
    NotifierProvider<WordBuilderPlayModeNotifier, WordBuilderPlayMode>(
      WordBuilderPlayModeNotifier.new,
    );

final stage14WeaponProvider = StateProvider<AngryWordsGunKind?>((ref) => null);

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
      final raw = prefs.getString(_key);
      final next = WordBuilderPlayModeX.fromPrefs(raw);
      if (next != state) state = next;
      if (raw != null && raw != next.prefsValue) {
        await prefs.setString(_key, next.prefsValue);
      }
    } catch (_) {}
  }

  Future<void> setMode(WordBuilderPlayMode mode) async {
    final next = WordBuilderPlayModeX.normalizeForPicker(mode);
    if (state == next) return;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, next.prefsValue);
    } catch (_) {}
  }

  Future<void> toggle() {
    final visible = kWordBuilderPlayModesInPicker;
    final index = visible.indexOf(state);
    final next = index < 0 || index >= visible.length - 1
        ? visible.first
        : visible[index + 1];
    return setMode(next);
  }
}

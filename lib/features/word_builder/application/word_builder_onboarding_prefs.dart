import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_play_mode.dart';

/// First-run coach flags per Word Builder play mode (Phase 6).
abstract final class WordBuilderOnboardingPrefs {
  static const angryWordsKey = 'onboarding_angry_words_v1';
  static const arkanoidKey = 'onboarding_arkanoid_v1';
  static const puzzleKey = 'onboarding_puzzle_v1';

  static String keyFor(WordBuilderPlayMode mode) => switch (mode) {
        WordBuilderPlayMode.angryWords => angryWordsKey,
        WordBuilderPlayMode.arkanoid => arkanoidKey,
        WordBuilderPlayMode.puzzle => puzzleKey,
        WordBuilderPlayMode.classic => '',
      };
}

class WordBuilderOnboardingNotifier extends AsyncNotifier<bool> {
  WordBuilderOnboardingNotifier(this.prefsKey);

  final String prefsKey;

  @override
  Future<bool> build() async {
    if (prefsKey.isEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  Future<void> markComplete() async {
    if (prefsKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
    state = const AsyncData(true);
  }

  Future<void> reset() async {
    if (prefsKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, false);
    state = const AsyncData(false);
  }
}

final wordBuilderAngryWordsOnboardingProvider =
    AsyncNotifierProvider<WordBuilderOnboardingNotifier, bool>(
  () => WordBuilderOnboardingNotifier(WordBuilderOnboardingPrefs.angryWordsKey),
);

final wordBuilderArkanoidOnboardingProvider =
    AsyncNotifierProvider<WordBuilderOnboardingNotifier, bool>(
  () => WordBuilderOnboardingNotifier(WordBuilderOnboardingPrefs.arkanoidKey),
);

final wordBuilderPuzzleOnboardingProvider =
    AsyncNotifierProvider<WordBuilderOnboardingNotifier, bool>(
  () => WordBuilderOnboardingNotifier(WordBuilderOnboardingPrefs.puzzleKey),
);

Future<void> resetAllWordBuilderOnboarding(WidgetRef ref) async {
  await ref.read(wordBuilderAngryWordsOnboardingProvider.notifier).reset();
  await ref.read(wordBuilderArkanoidOnboardingProvider.notifier).reset();
  await ref.read(wordBuilderPuzzleOnboardingProvider.notifier).reset();
}

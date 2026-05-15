import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_game_notifier.dart';

class WordBuilderHintRevealButton extends ConsumerWidget {
  const WordBuilderHintRevealButton({super.key, required this.bookKey});

  final int bookKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(wordBuilderGameProvider(bookKey).notifier);
    return IconButton.filledTonal(
      tooltip: l10n.wordBuilderHintReveal,
      onPressed: () => notifier.hintRevealLetter(),
      icon: const Icon(Icons.lightbulb_outline_rounded),
    );
  }
}

class WordBuilderTranslationButton extends ConsumerWidget {
  const WordBuilderTranslationButton({super.key, required this.bookKey});

  final int bookKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(langProvider);
    final preferKur = lang == TranslationLang.kur;
    final notifier = ref.read(wordBuilderGameProvider(bookKey).notifier);
    return IconButton.filledTonal(
      tooltip: l10n.wordBuilderTranslation,
      onPressed: () => notifier.hintMeaning(preferKur: preferKur),
      icon: const Icon(Icons.translate_rounded),
    );
  }
}

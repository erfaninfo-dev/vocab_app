import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/tts/tts_service.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../domain/api_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../important_words_controller.dart';
import '../word_preferences_controller.dart';

class WordCard extends ConsumerWidget {
  const WordCard({
    super.key,
    required this.entry,
    this.showUnitBadge = true,
    this.number,
    this.translationLang,
  });

  final VocabEntry entry;
  final bool showUnitBadge;
  final int? number;

  /// When set (e.g. unit sample Text/Book tab), overrides [langProvider].
  final TranslationLang? translationLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(wordPreferencesProvider);
    final important = ref.watch(importantWordsProvider);
    final prefsNotifier = ref.read(wordPreferencesProvider.notifier);
    final importantNotifier = ref.read(importantWordsProvider.notifier);
    final api = ref.read(apiServiceProvider);
    final overrideLang = translationLang;
    final TranslationLang resolvedLang =
        overrideLang ?? ref.watch(langProvider);
    final isFav = prefs.isFavorite(entry);
    final isImp = important.isMarked(entry);
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(entry.section);
    final cardNumber = number;
    const localMeaningColor = Colors.blue;

    final localMeaning = entry.meaningFor(resolvedLang);
    final localExample = entry.exampleLocalFor(resolvedLang);

    final booksAsync = ref.watch(apiBooksProvider);
    final bookTitle = booksAsync.maybeWhen(
      data: (List<Book> books) {
        final id = int.tryParse(entry.bookId);
        if (id == null) return null;
        for (final b in books) {
          if (b.id == id) {
            final t = b.title.trim();
            return t.isEmpty ? null : t;
          }
        }
        return null;
      },
      orElse: () => null,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: scheme.surface.withValues(alpha: 0.92),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookTitle != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (cardNumber != null && cardNumber > 0) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        '$cardNumber',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.word,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (entry.type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        entry.type,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (entry.meaningEn.isNotEmpty)
                Text(
                  entry.meaningEn,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (localMeaning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        localMeaning,
                        textAlign: TextAlign.right,
                        strutStyle: const StrutStyle(forceStrutHeight: true),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: localMeaningColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (entry.exampleEn.isNotEmpty || localExample.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (entry.exampleEn.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.exampleEn,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                        ),
                      ],
                      if (localExample.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                localExample,
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: localMeaningColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Favorite',
                    onPressed: entry.rowId <= 0
                        ? null
                        : () => prefsNotifier.toggleFavorite(
                            entry,
                            api.authToken != null ? api : null,
                          ),
                    icon: Icon(
                      isFav
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Important',
                    onPressed: entry.rowId <= 0
                        ? null
                        : () => importantNotifier.setImportant(
                            entry,
                            !isImp,
                            api.authToken != null ? api : null,
                          ),
                    style: isImp
                        ? IconButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(
                              alpha: 0.22,
                            ),
                            foregroundColor: Colors.deepOrange.shade700,
                          )
                        : null,
                    icon: Icon(
                      isImp
                          ? Icons.local_fire_department_rounded
                          : Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _SpeakButton(word: entry.word, example: entry.exampleEn),
                  if (showUnitBadge) ...[
                    const Spacer(),
                    Text(
                      entry.section == null || entry.section == 0
                          ? 'U${entry.unit}'
                          : 'U${entry.unit}  S${entry.section}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _accent(int? section) {
  switch (section) {
    case 1:
      return const Color(0xFF5B6CFF);
    case 2:
      return const Color(0xFF7A5FFF);
    default:
      return const Color(0xFF4D8DFF);
  }
}

class _SpeakButton extends ConsumerWidget {
  const _SpeakButton({required this.word, required this.example});

  final String word;
  final String example;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);
    final isSpeakingWord = tts.isSpeakingText(word);
    final isSpeakingExample = example.isNotEmpty && tts.isSpeakingText(example);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: AppLocalizations.of(context)!.pronounceWord,
          onPressed: () => notifier.speak(word, showMiniPlayer: false),
          style: isSpeakingWord
              ? IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                )
              : null,
          icon: Icon(
            isSpeakingWord ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          ),
        ),
        if (example.isNotEmpty) ...[
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: AppLocalizations.of(context)!.pronounceExample,
            onPressed: () => notifier.speak(example, showMiniPlayer: false),
            style: isSpeakingExample
                ? IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                  )
                : null,
            icon: Icon(
              isSpeakingExample
                  ? Icons.record_voice_over_rounded
                  : Icons.record_voice_over_outlined,
            ),
          ),
        ],
      ],
    );
  }
}

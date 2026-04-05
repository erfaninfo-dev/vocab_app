import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/tts/tts_service.dart';
import '../../../data/models/vocab_entry.dart';
import '../word_preferences_controller.dart';

class WordCard extends ConsumerWidget {
  const WordCard({super.key, required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(wordPreferencesProvider);
    final controller = ref.read(wordPreferencesProvider.notifier);
    final lang       = ref.watch(langProvider);
    final isFav      = state.favoriteIds.contains(entry.id);
    final isHard     = state.difficultIds.contains(entry.id);
    final scheme     = Theme.of(context).colorScheme;
    final accent     = _accent(entry.section);

    final localMeaning = entry.meaningFor(lang);
    final localExample = entry.exampleLocalFor(lang);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: scheme.surface.withOpacity(0.92),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Word + type ───────────────────────────────────────────────────
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
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      entry.type,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── English meaning ───────────────────────────────────────────────
            if (entry.meaningEn.isNotEmpty)
              Text(
                entry.meaningEn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // ── Local meaning (fa or kur) ─────────────────────────────────────
            if (localMeaning.isNotEmpty) ...[
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      localMeaning,
                      textAlign: TextAlign.right,
                      strutStyle: const StrutStyle(forceStrutHeight: true),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── Example box ───────────────────────────────────────────────────
            if (entry.exampleEn.isNotEmpty || localExample.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.5),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                  ?.copyWith(color: Colors.black87),
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

            // ── Action buttons ────────────────────────────────────────────────
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Favorite',
                  onPressed: () => controller.toggleFavorite(entry.id),
                  icon: Icon(
                    isFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Difficult',
                  onPressed: () => controller.toggleDifficult(entry.id),
                  icon: Icon(
                    isHard
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 4),
                _SpeakButton(word: entry.word, example: entry.exampleEn),
                const Spacer(),
                Text(
                  'U${entry.unit}  S${entry.section}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
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

// ─── Speak Button ─────────────────────────────────────────────────────────────

class _SpeakButton extends ConsumerWidget {
  const _SpeakButton({required this.word, required this.example});

  final String word;
  final String example;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);
    final isSpeakingWord = tts.isSpeakingText(word);
    final isSpeakingExample =
        example.isNotEmpty && tts.isSpeakingText(example);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'Pronounce word',
          onPressed: () => notifier.speak(word),
          style: isSpeakingWord
              ? IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                )
              : null,
          icon: Icon(
            isSpeakingWord
                ? Icons.volume_up_rounded
                : Icons.volume_up_outlined,
          ),
        ),
        if (example.isNotEmpty) ...[
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Pronounce example',
            onPressed: () => notifier.speak(example),
            style: isSpeakingExample
                ? IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
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

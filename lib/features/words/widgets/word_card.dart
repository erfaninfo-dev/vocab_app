import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vocab_entry.dart';
import '../word_preferences_controller.dart';

class WordCard extends ConsumerWidget {
  const WordCard({super.key, required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wordPreferencesProvider);
    final controller = ref.read(wordPreferencesProvider.notifier);
    final isFav = state.favoriteIds.contains(entry.id);
    final isHard = state.difficultIds.contains(entry.id);
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(entry.section);

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
            if (entry.meaningEn.isNotEmpty)
              Text(
                entry.meaningEn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (entry.meaningFa.isNotEmpty) ...[
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  entry.meaningFa,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (entry.exampleEn.isNotEmpty || entry.exampleFa.isNotEmpty) ...[
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
                        ),
                      ),
                    ],
                    if (entry.exampleFa.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          entry.exampleFa,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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

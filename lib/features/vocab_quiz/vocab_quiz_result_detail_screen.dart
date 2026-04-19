import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/vocab_quiz_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class VocabQuizResultDetailScreen extends ConsumerWidget {
  const VocabQuizResultDetailScreen({
    super.key,
    required this.resultId,
    this.mistakesOnly = false,
  });

  final int resultId;
  final bool mistakesOnly;

  static String _unitsCsv(List<int> units) {
    if (units.isEmpty) return '—';
    return units.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(vocabQuizResultDetailProvider(resultId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          mistakesOnly ? l10n.vocabQuizMistakesTitle : l10n.vocabQuizResultDetailTitle,
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userFriendlyErrorMessage(err, l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(
                    vocabQuizResultDetailProvider(resultId),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (VocabQuizResultDetail r) {
          final bookTitle = (r.bookTitle != null && r.bookTitle!.trim().isNotEmpty)
              ? r.bookTitle!.trim()
              : 'Book #${r.bookId}';
          final quizTitle =
              r.quizNameFromMeta ?? l10n.vocabularyQuizTitle;
          final unitsMeta = r.unitsFromMeta;
          final unitsLabel = unitsMeta.isNotEmpty
              ? unitsMeta
              : {
                  for (final it in r.items) it.unit,
                }.toList()
                ..sort();

          final wrongItems = r.items.where((e) => !e.correct).toList();
          final displayItems = mistakesOnly ? wrongItems : r.items;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!mistakesOnly) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quizTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bookTitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.vocabQuizHistoryUnitsLine(_unitsCsv(unitsLabel)),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.vocabQuizCorrectWrongLine(
                            r.score,
                            r.totalQuestions - r.score,
                          ),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(
                  quizTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  bookTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.vocabQuizHistoryUnitsLine(_unitsCsv(unitsLabel)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.vocabQuizCorrectWrongLine(
                    r.score,
                    r.totalQuestions - r.score,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              if (displayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      l10n.vocabQuizMistakesEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                ...List.generate(displayItems.length, (i) {
                  final it = displayItems[i];
                  final ok = it.correct;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              it.word,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    ok
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: ok
                                        ? Colors.green.shade700
                                        : Colors.red.shade600,
                                    size: ok ? 22 : 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ok
                                        ? l10n.vocabQuizResultCorrect
                                        : l10n.vocabQuizResultIncorrect,
                                    style: ok
                                        ? TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green.shade800,
                                          )
                                        : Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade800,
                                              fontSize: 12.5,
                                            ),
                                  ),
                                ],
                              ),
                            ),
                            if (!ok && it.given.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${l10n.vocabQuizResultYourAnswer}: ${it.given}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

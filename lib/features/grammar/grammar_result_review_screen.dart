import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/grammar_session_item.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

const _optKeys = ['option1', 'option2', 'option3', 'option4'];

/// Saved grammar attempt: question-by-question review (requires server session_json).
class GrammarResultReviewScreen extends ConsumerWidget {
  const GrammarResultReviewScreen({super.key, required this.resultId});

  final int resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(grammarResultDetailProvider(resultId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.reviewSessionTitle),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.couldNotLoadResult),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(grammarResultDetailProvider(resultId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final r = detail.result;
          final items = detail.items;
          final pct = (r.score != null &&
                  r.totalQuestions != null &&
                  r.totalQuestions! > 0)
              ? ((r.score! / r.totalQuestions!) * 100).round()
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.quizName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${r.score ?? '—'} / ${r.totalQuestions ?? '—'}'
                        '${pct != null ? ' · $pct%' : ''}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Questions',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No per-question data was stored for this attempt '
                    '(older results or server not migrated).',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ...List.generate(items.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuestionReviewCard(
                      index: i + 1,
                      item: items[i],
                      scheme: scheme,
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

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.index,
    required this.item,
    required this.scheme,
  });

  final int index;
  final GrammarSessionItem item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: CircleAvatar(
          backgroundColor: item.isCorrect
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          foregroundColor: item.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
          child: Icon(
            item.isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 20,
          ),
        ),
        title: Text(
          'Q$index · ${item.topic}',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.isCorrect ? 'Correct' : 'Incorrect',
          style: tt.labelMedium?.copyWith(
            color: item.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            item.questionText ?? '—',
            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._optKeys.map((k) {
            final label = item.optionLabel(k) ?? '';
            if (label.isEmpty) return const SizedBox.shrink();
            final sel = (item.selectedAnswer ?? '').trim().toLowerCase();
            final cor = (item.correctAnswer ?? '').trim().toLowerCase();
            final kk = k.toLowerCase();
            final isCorrectOpt = kk == cor;
            final isChosen = kk == sel;
            Color? bg;
            if (isCorrectOpt) {
              bg = Colors.green.withValues(alpha: 0.15);
            } else if (isChosen && !item.isCorrect) {
              bg = Colors.red.withValues(alpha: 0.12);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bg ?? scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: tt.bodyMedium,
                      ),
                    ),
                    if (isCorrectOpt)
                      Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade700),
                    if (isChosen && !isCorrectOpt)
                      Icon(Icons.radio_button_checked_rounded, size: 18, color: scheme.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

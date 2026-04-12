import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/vocab_quiz_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class VocabQuizResultDetailScreen extends ConsumerWidget {
  const VocabQuizResultDetailScreen({super.key, required this.resultId});

  final int resultId;

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
        title: Text(l10n.vocabQuizResultDetailTitle),
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
          final title = (r.bookTitle != null && r.bookTitle!.trim().isNotEmpty)
              ? r.bookTitle!
              : 'Book #${r.bookId}';
          final dateStr = _formatDate(r.createdAt);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.vocabQuizResultScoreLine(r.score, r.totalQuestions),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.vocabQuizResultQuestion,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...List.generate(r.items.length, (i) {
                final it = r.items[i];
                final ok = it.correct;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.word,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Icon(
                                ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: ok ? Colors.green.shade700 : Colors.red.shade600,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ok ? l10n.vocabQuizResultCorrect : l10n.vocabQuizResultIncorrect,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ok ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _modeLabel(it.mode, l10n),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          if (!ok && it.given.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${l10n.vocabQuizResultYourAnswer}: ${it.given}',
                              style: Theme.of(context).textTheme.bodySmall,
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

  static String _formatDate(String raw) {
    try {
      final d = DateTime.tryParse(raw);
      if (d == null) return raw;
      return DateFormat.yMMMd().add_Hm().format(d.toLocal());
    } catch (_) {
      return raw;
    }
  }

  static String _modeLabel(String name, AppLocalizations l10n) {
    switch (name) {
      case 'mcqWordToMeaning':
        return l10n.quizMcqWordToMeaning;
      case 'mcqMeaningToWord':
        return l10n.quizMcqMeaningToWord;
      case 'writtenMeaningToWord':
        return l10n.quizWrittenMeaningToWord;
      case 'spellingListenAndType':
        return l10n.quizSpellingListenAndType;
      default:
        return name;
    }
  }
}

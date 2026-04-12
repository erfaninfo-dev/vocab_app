import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../data/models/vocab_quiz_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class VocabQuizHistoryScreen extends ConsumerWidget {
  const VocabQuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider).valueOrNull;

    if (auth == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.vocabQuizHistoryTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.vocabQuizHistorySignIn,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final async = ref.watch(myVocabQuizResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.vocabQuizHistoryTitle),
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
                  onPressed: () async {
                    await ref
                        .read(apiServiceProvider)
                        .bustVocabQuizResultsMyCache();
                    ref.invalidate(myVocabQuizResultsProvider);
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (List<VocabQuizResultSummary> rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.vocabQuizHistoryEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(apiServiceProvider)
                  .bustVocabQuizResultsMyCache();
              ref.invalidate(myVocabQuizResultsProvider);
              await ref.read(myVocabQuizResultsProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = rows[i];
                final title =
                    (r.bookTitle != null && r.bookTitle!.trim().isNotEmpty)
                        ? r.bookTitle!
                        : 'Book #${r.bookId}';
                final dateStr = _formatDate(r.createdAt);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.quiz_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${l10n.vocabQuizResultScoreLine(r.score, r.totalQuestions)} · $dateStr',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        context.push('/vocab-quiz/result/${r.id}'),
                  ),
                );
              },
            ),
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
}

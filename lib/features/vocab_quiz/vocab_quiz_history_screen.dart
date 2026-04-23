import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../data/models/vocab_quiz_result.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class VocabQuizHistoryScreen extends ConsumerWidget {
  const VocabQuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.vocabQuizHistoryTitle),
      ),
      body: const VocabQuizHistoryBody(),
    );
  }
}

String _unitsCsv(List<int> units) {
  if (units.isEmpty) return '—';
  return units.join(', ');
}

String _formatSessionDate(BuildContext context, String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final t = raw.trim();
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized);
  if (dt == null) return raw;
  final loc = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(loc).add_Hm().format(dt.toLocal());
}

bool _omitVocabQuizTypeLine(String? rawQuizName, AppLocalizations l10n) {
  final n = rawQuizName?.trim();
  if (n == null || n.isEmpty) return true;
  if (n == l10n.vocabularyQuizTitle) return true;
  if (n == 'Vocabulary quiz') return true;
  return false;
}

/// List of saved vocab quiz sessions — used on [VocabQuizHistoryScreen] and Stats → Vocab tab.
class VocabQuizHistoryBody extends ConsumerWidget {
  const VocabQuizHistoryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider).valueOrNull;

    if (auth == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.vocabQuizHistorySignIn,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final async = ref.watch(myVocabQuizResultsProvider);

    return async.when(
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
                  await refreshAllRemoteApiData(ref);
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
            await refreshAllRemoteApiData(ref);
            await ref.read(myVocabQuizResultsProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = rows[i];
              final bookTitle =
                  (r.bookTitle != null && r.bookTitle!.trim().isNotEmpty)
                      ? r.bookTitle!.trim()
                      : 'Book #${r.bookId}';
              final omitQuizType = _omitVocabQuizTypeLine(r.quizName, l10n);

              void openDetail() {
                final path = r.wrong > 0
                    ? '/vocab-quiz/result/${r.id}?mistakes=1'
                    : '/vocab-quiz/result/${r.id}';
                context.push(path);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: openDetail,
                  borderRadius: BorderRadius.circular(14),
                  child: Card(
                    elevation: 0,
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!omitQuizType) ...[
                            Text(
                              r.quizName!.trim(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            bookTitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.vocabQuizHistoryUnitsLine(
                              _unitsCsv(r.units),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.vocabQuizCorrectWrongLine(r.correct, r.wrong),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatSessionDate(context, r.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

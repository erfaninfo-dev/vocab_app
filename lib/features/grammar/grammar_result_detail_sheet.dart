import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/profile_avatar.dart';
import '../../data/models/grammar_result.dart';
import '../../data/models/grammar_result_reaction.dart';
import '../../l10n/app_localizations.dart';
import 'grammar_practice_result_card.dart';
import 'grammar_result_reactions_bar.dart';

Future<void> showGrammarResultDetailSheet({
  required BuildContext context,
  required GrammarResult result,
  GrammarResultReactionSummary? reactionSummary,
  String? practiceTotalsLabel,
  VoidCallback? onOpenReview,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => GrammarResultDetailSheet(
      result: result,
      reactionSummary: reactionSummary,
      practiceTotalsLabel: practiceTotalsLabel,
      onOpenReview: onOpenReview,
    ),
  );
}

class GrammarResultDetailSheet extends ConsumerWidget {
  const GrammarResultDetailSheet({
    super.key,
    required this.result,
    this.reactionSummary,
    this.practiceTotalsLabel,
    this.onOpenReview,
  });

  final GrammarResult result;
  final GrammarResultReactionSummary? reactionSummary;
  final String? practiceTotalsLabel;
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final topics = GrammarPracticeResultCard.topicLabelsForResult(result);
    final displayName = (result.userName ?? '').trim().isEmpty
        ? l10n.guestUser
        : result.userName!.trim();
    final score = result.score;
    final total = result.totalQuestions;
    final hasScore = score != null && total != null && total > 0;
    final ratio = hasScore ? score / total : 0.0;
    final avatarId = (result.avatar ?? '').trim().isEmpty
        ? 'm1'
        : result.avatar!.trim();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  avatarId: avatarId,
                  userId: result.userId,
                  size: 56,
                  showBorder: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (practiceTotalsLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          practiceTotalsLabel!,
                          style: tt.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        GrammarPracticeResultCard.formatCreatedAt(result.createdAt),
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasScore)
                  _DetailScoreBadge(
                    score: score,
                    total: total,
                    percent: (ratio * 100).round(),
                    scheme: scheme,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l10n.grammarResultDetailTopicsTitle,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (topics.isEmpty)
              Text(
                l10n.grammarResultDetailTopicsEmpty,
                style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              GrammarTopicChipsDisplay(
                labels: topics,
                scheme: scheme,
                expanded: true,
              ),
            const SizedBox(height: 18),
            Text(
              l10n.grammarResultDetailReactionsTitle,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            GrammarResultReactionsBar(
              resultId: result.id,
              summary: reactionSummary,
            ),
            if (onOpenReview != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenReview!();
                },
                icon: const Icon(Icons.fact_check_rounded),
                label: Text(l10n.grammarResultDetailOpenReview),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailScoreBadge extends StatelessWidget {
  const _DetailScoreBadge({
    required this.score,
    required this.total,
    required this.percent,
    required this.scheme,
  });

  final int score;
  final int total;
  final int percent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score/$total',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            '$percent%',
            style: tt.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/srs/srs_model.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'flashcard_progress.dart';

class FlashcardRatingBar extends ConsumerWidget {
  const FlashcardRatingBar({
    super.key,
    required this.wordId,
    required this.onRate,
    this.showInterval = true,
  });

  final String wordId;
  final void Function(SrsRating rating) onRate;
  final bool showInterval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final card = ref.watch(
      srsProvider.select((s) => s.cards[wordId] ?? SrsCard(wordId: wordId)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.howWellKnew,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: SrsRating.values.map((rating) {
              final interval = showInterval
                  ? Sm2.rate(card, rating).interval
                  : null;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _RatingButton(
                    rating: rating,
                    nextInterval: interval,
                    onTap: () => onRate(rating),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.nextInterval,
    required this.onTap,
  });

  final SrsRating rating;
  final int? nextInterval;
  final VoidCallback onTap;

  Color get _accent => switch (rating) {
        SrsRating.again => FlashcardTokens.againColor,
        SrsRating.hard => FlashcardTokens.hardColor,
        SrsRating.good => FlashcardTokens.goodColor,
        SrsRating.easy => FlashcardTokens.easyColor,
      };

  IconData get _icon => switch (rating) {
        SrsRating.again => Icons.refresh_rounded,
        SrsRating.hard => Icons.local_fire_department_rounded,
        SrsRating.good => Icons.check_rounded,
        SrsRating.easy => Icons.bolt_rounded,
      };

  String _label(AppLocalizations l10n) => switch (rating) {
        SrsRating.again => l10n.flashcardRatingAgain,
        SrsRating.hard => l10n.flashcardRatingHard,
        SrsRating.good => l10n.flashcardRatingGood,
        SrsRating.easy => l10n.flashcardRatingEasy,
      };

  String _intervalLabel(int v) => v <= 1 ? '<1d' : '${v}d';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intervalLabel =
        nextInterval == null ? null : _intervalLabel(nextInterval!);
    final accent = _accent;

    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.25),
        highlightColor: accent.withValues(alpha: 0.14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, size: 15, color: accent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _label(l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (intervalLabel != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        intervalLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ),
    );
  }
}

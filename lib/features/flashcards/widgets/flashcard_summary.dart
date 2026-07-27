import 'package:flutter/material.dart';

import '../../../core/srs/srs_model.dart';
import '../../../core/widgets/app_jelly_style.dart';
import '../../../l10n/app_localizations.dart';
import 'flashcard_progress.dart';

class FlashcardSummary extends StatelessWidget {
  const FlashcardSummary({
    super.key,
    required this.total,
    required this.counts,
    required this.weakCount,
    required this.duration,
    required this.onReviewAgain,
    required this.onRestart,
    required this.onBackToWords,
  });

  final int total;
  final Map<SrsRating, int> counts;
  final int weakCount;
  final Duration duration;
  final VoidCallback onReviewAgain;
  final VoidCallback onRestart;
  final VoidCallback onBackToWords;

  int _count(SrsRating r) => counts[r] ?? 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final reviewed = total;
    final weak = weakCount;
    final mastered = _count(SrsRating.good) + _count(SrsRating.easy);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CelebrationHalo(scheme: scheme),
            const SizedBox(height: 16),
            Text(
              l10n.flashcardSessionComplete,
              textAlign: TextAlign.center,
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.flashcardSessionCardsReviewed(reviewed),
              style: tt.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (duration.inSeconds > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.flashcardSessionDuration(minutes, seconds),
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                _SummaryStat(
                  value: reviewed,
                  label: l10n.flashcardSummaryReviewed,
                  icon: Icons.style_rounded,
                  color: scheme.primary,
                ),
                _SummaryStat(
                  value: mastered,
                  label: l10n.flashcardSummaryMastered,
                  icon: Icons.workspace_premium_rounded,
                  color: FlashcardTokens.goodColor,
                ),
                _SummaryStat(
                  value: weak,
                  label: l10n.flashcardSummaryToReview,
                  icon: Icons.replay_rounded,
                  color: FlashcardTokens.hardColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _RatingTally(
                  color: FlashcardTokens.againColor,
                  value: _count(SrsRating.again),
                ),
                _RatingTally(
                  color: FlashcardTokens.hardColor,
                  value: _count(SrsRating.hard),
                ),
                _RatingTally(
                  color: FlashcardTokens.goodColor,
                  value: _count(SrsRating.good),
                ),
                _RatingTally(
                  color: FlashcardTokens.easyColor,
                  value: _count(SrsRating.easy),
                ),
              ],
            ),
            const SizedBox(height: 26),
            if (weakCount > 0) ...[
              _PrimaryAction(
                onPressed: onReviewAgain,
                icon: Icons.replay_rounded,
                label: l10n.flashcardSessionReviewAgain(weakCount),
                gradient: [FlashcardTokens.hardColor, FlashcardTokens.againColor],
              ),
              const SizedBox(height: 10),
            ],
            _PrimaryAction(
              onPressed: onRestart,
              icon: Icons.refresh_rounded,
              label: l10n.flashcardSessionRestart,
              gradient: [scheme.primary, scheme.tertiary],
              outlined: true,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onBackToWords,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.flashcardSessionBackToWords),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationHalo extends StatelessWidget {
  const _CelebrationHalo({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.30),
                scheme.tertiary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: appJellyInsetDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingTally extends StatelessWidget {
  const _RatingTally({required this.color, required this.value});
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value == 0 ? 0.04 : null,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.16),
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.outlined = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, color: scheme.primary),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradient),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

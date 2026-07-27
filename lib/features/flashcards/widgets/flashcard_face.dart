import 'package:flutter/material.dart';

import '../../../core/language/language_provider.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../l10n/app_localizations.dart';
import '../models/flashcard_direction.dart';
import 'flashcard_progress.dart';

/// A single face of a flashcard. The caller decides which side is visible via
/// [isFront]; what is shown depends on [direction] (word-first vs meaning-first).
class FlashcardFace extends StatelessWidget {
  const FlashcardFace({
    super.key,
    required this.entry,
    required this.lang,
    required this.isFront,
    required this.direction,
    required this.isImportant,
    required this.isFavorite,
  });

  final VocabEntry entry;
  final TranslationLang lang;
  final bool isFront;
  final FlashcardDirection direction;
  final bool isImportant;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wordOnFront = direction == FlashcardDirection.wordToMeaning;
    final showWord = wordOnFront == isFront;

    final localMeaning = entry.meaningFor(lang);
    final meaningLine = localMeaning.isNotEmpty
        ? localMeaning
        : (entry.meaningEn.isNotEmpty ? entry.meaningEn : '-');

    final gradient = isFront
        ? FlashcardTokens.frontGradient
        : (isDark
            ? FlashcardTokens.backGradient
            : const [Color(0xFFECEAFF), Color(0xFFF3EAFF)]);

    final onCard = isFront
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF2A2150));
    final onCardMuted = onCard.withValues(alpha: 0.72);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FlashcardTokens.cardRadius),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: FlashcardShadow.soft(scheme),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlashcardTokens.cardRadius),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -60,
              child: _GlowOrb(
                color: Colors.white.withValues(alpha: isFront ? 0.18 : 0.10),
                size: 180,
              ),
            ),
            Positioned(
              left: -40,
              bottom: -50,
              child: _GlowOrb(
                color: Colors.white.withValues(alpha: isFront ? 0.10 : 0.06),
                size: 130,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: _TopRow(
                      label: isFront
                          ? l10n.flashcardWordLabel
                          : l10n.flashcardMeaningLabel,
                      isImportant: isImportant,
                      isFavorite: isFavorite,
                      onCard: onCard,
                      onCardMuted: onCardMuted,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: showWord
                        ? Center(
                            child: _WordBlock(
                              entry: entry,
                              onCard: onCard,
                              onCardMuted: onCardMuted,
                              tt: tt,
                            ),
                          )
                        : _MeaningBlock(
                            meaningEn: entry.meaningEn,
                            meaningLocal: meaningLine,
                            exampleEn: entry.exampleEn,
                            onCard: onCard,
                            onCardMuted: onCardMuted,
                            tt: tt,
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: _FlipHint(
                        onCardMuted: onCardMuted,
                        tt: tt,
                        l10n: l10n,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.label,
    required this.isImportant,
    required this.isFavorite,
    required this.onCard,
    required this.onCardMuted,
    required this.l10n,
  });

  final String label;
  final bool isImportant;
  final bool isFavorite;
  final Color onCard;
  final Color onCardMuted;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: onCard.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(FlashcardTokens.pillRadius),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              color: onCard.withValues(alpha: 0.92),
            ),
          ),
        ),
        const Spacer(),
        if (isFavorite)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _GlassDot(
              icon: Icons.star_rounded,
              onCard: onCard,
              tooltip: l10n.flashcardBadgeFavorite,
            ),
          ),
        if (isImportant)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _GlassDot(
              icon: Icons.priority_high_rounded,
              onCard: onCard,
              tooltip: l10n.flashcardBadgeImportant,
            ),
          ),
      ],
    );
  }
}

class _GlassDot extends StatelessWidget {
  const _GlassDot({required this.icon, required this.onCard, required this.tooltip});

  final IconData icon;
  final Color onCard;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: onCard.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: onCard),
      ),
    );
  }
}

class _WordBlock extends StatelessWidget {
  const _WordBlock({
    required this.entry,
    required this.onCard,
    required this.onCardMuted,
    required this.tt,
  });

  final VocabEntry entry;
  final Color onCard;
  final Color onCardMuted;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            entry.word,
            textAlign: TextAlign.center,
            style: tt.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: onCard,
              letterSpacing: -0.5,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        if (entry.type.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: onCard.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(FlashcardTokens.pillRadius),
            ),
            child: Text(
              entry.type,
              style: tt.titleSmall?.copyWith(
                color: onCardMuted,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MeaningBlock extends StatelessWidget {
  const _MeaningBlock({
    required this.meaningEn,
    required this.meaningLocal,
    required this.exampleEn,
    required this.onCard,
    required this.onCardMuted,
    required this.tt,
  });

  final String meaningEn;
  final String meaningLocal;
  final String exampleEn;
  final Color onCard;
  final Color onCardMuted;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final boxColor = onCard.withValues(alpha: 0.09);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meaningEn.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      meaningEn,
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onCard,
                        height: 1.35,
                      ),
                    ),
                  ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: _InfoBox(
                    color: boxColor,
                    child: Text(
                      meaningLocal,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        height: 1.45,
                        color: onCard.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (exampleEn.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoBox(
                    color: boxColor,
                    child: Text(
                      exampleEn,
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: onCardMuted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FlashcardTokens.chipRadius),
      ),
      child: child,
    );
  }
}

class _FlipHint extends StatelessWidget {
  const _FlipHint({required this.onCardMuted, required this.tt, required this.l10n});

  final Color onCardMuted;
  final TextTheme tt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 13,
          color: onCardMuted,
        ),
        const SizedBox(width: 6),
        Text(
          l10n.tapToFlip,
          style: tt.labelSmall?.copyWith(
            color: onCardMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

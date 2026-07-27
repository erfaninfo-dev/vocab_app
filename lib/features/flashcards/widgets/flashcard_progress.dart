import 'package:flutter/material.dart';

/// Shared visual tokens for the flashcards feature. Kept in one place so the
/// card, rating bar and summary stay visually consistent.
class FlashcardTokens {
  const FlashcardTokens._();

  static const double cardRadius = 28;
  static const double chipRadius = 16;
  static const double pillRadius = 999;

  // Rating palette (works on light + dark surfaces).
  static const Color againColor = Color(0xFFE53935);
  static const Color hardColor = Color(0xFFFB8C00);
  static const Color goodColor = Color(0xFF2E9E4B);
  static const Color easyColor = Color(0xFF5B6CFF);

  static const List<Color> frontGradient = [
    Color(0xFF6D7BFF),
    Color(0xFF8A5BF5),
  ];
  static const List<Color> backGradient = [
    Color(0xFF1F2444),
    Color(0xFF2E2150),
  ];
}

/// A soft, layered shadow used under the flashcard so the 3D flip reads as a
/// physical object floating above the scaffold.
class FlashcardShadow {
  const FlashcardShadow._();

  static List<BoxShadow> soft(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.18),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}

/// A gradient progress bar with a glowing head, used at the top of the session.
class FlashcardProgress extends StatelessWidget {
  const FlashcardProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ratio = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(FlashcardTokens.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.style_rounded,
                    size: 13,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$current / $total',
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: tt.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(FlashcardTokens.pillRadius),
          child: SizedBox(
            height: 9,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(FlashcardTokens.pillRadius),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          scheme.tertiary,
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(FlashcardTokens.pillRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

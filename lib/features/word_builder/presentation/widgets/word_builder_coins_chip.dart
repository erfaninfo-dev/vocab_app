import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Coin balance pill — same styling as the Word Builder session AppBar.
class WordBuilderCoinsChip extends StatelessWidget {
  const WordBuilderCoinsChip({
    super.key,
    required this.balanceLabel,
    required this.isDark,
    required this.scheme,
  });

  final String balanceLabel;
  final bool isDark;
  final ColorScheme scheme;

  static const double coinIconSize = 30;
  static const double balanceFontSize = 22;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 9,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  scheme.surfaceContainerHigh.withValues(alpha: 0.85),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                ]
              : const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.55 : 0.9),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFF9800,
            ).withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: chipPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              size: coinIconSize,
              color: isDark ? const Color(0xFFFFCA28) : const Color(0xFFFFA000),
              shadows: [
                Shadow(
                  color: Colors.orange.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              balanceLabel,
              style: GoogleFonts.fredoka(
                fontSize: balanceFontSize,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0.5,
                color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordBuilderCoinsChipLoading extends StatelessWidget {
  const WordBuilderCoinsChipLoading({super.key, required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CircularProgressIndicator(
          strokeWidth: 2.8,
          color: scheme.primary,
        ),
      ),
    );
  }
}

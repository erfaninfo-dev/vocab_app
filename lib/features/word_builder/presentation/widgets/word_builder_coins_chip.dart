import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Coin balance pill — same styling as the Word Builder session AppBar.
class WordBuilderCoinsChip extends StatelessWidget {
  const WordBuilderCoinsChip({
    super.key,
    required this.balanceLabel,
    required this.isDark,
    required this.scheme,
    this.compact = false,
  });

  final String balanceLabel;
  final bool isDark;
  final ColorScheme scheme;
  final bool compact;

  static const double coinIconSize = 30;
  static const double balanceFontSize = 22;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 9,
  );

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 22.0 : coinIconSize;
    final fontSize = compact ? 16.0 : balanceFontSize;
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : chipPadding;

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
          width: compact ? 1.6 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFF9800,
            ).withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: compact ? 8 : 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: pad,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              size: iconSize,
              color: isDark ? const Color(0xFFFFCA28) : const Color(0xFFFFA000),
              shadows: [
                Shadow(
                  color: Colors.orange.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
            SizedBox(width: compact ? 5 : 8),
            Text(
              balanceLabel,
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
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

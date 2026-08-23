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
    this.chromeSurface,
    this.chromeOnSurface,
    this.accent,
  });

  final String balanceLabel;
  final bool isDark;
  final ColorScheme scheme;
  final bool compact;
  final Color? chromeSurface;
  final Color? chromeOnSurface;
  final Color? accent;

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
    final surfaceA = chromeSurface ??
        (isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.85)
            : const Color(0xFFFFF8E1));
    final surfaceB = chromeSurface != null
        ? Color.lerp(chromeSurface!, Colors.white, isDark ? 0.08 : 0.18)!
        : (isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.9)
              : const Color(0xFFFFECB3));
    final on = chromeOnSurface ??
        (isDark ? scheme.onSurface : const Color(0xFF5D4037));
    final border = (accent ?? const Color(0xFFFFB300))
        .withValues(alpha: isDark ? 0.55 : 0.9);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [surfaceA, surfaceB]),
        border: Border.all(
          color: border,
          width: compact ? 1.6 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (accent ?? const Color(0xFFFF9800)).withValues(
              alpha: isDark ? 0.35 : 0.28,
            ),
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
                color: on,
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

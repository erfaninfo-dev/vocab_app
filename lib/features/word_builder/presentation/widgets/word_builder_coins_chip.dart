import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/word_builder_tokens.dart';

/// Coin balance pill — count-up + pulse when balance changes.
class WordBuilderCoinsChip extends StatefulWidget {
  const WordBuilderCoinsChip({
    super.key,
    required this.balance,
    required this.balanceLabel,
    required this.isDark,
    required this.scheme,
    this.compact = false,
  });

  final int balance;
  final String balanceLabel;
  final bool isDark;
  final ColorScheme scheme;
  final bool compact;

  static const double coinIconSize = 30;
  static const double balanceFontSize = 22;

  @override
  State<WordBuilderCoinsChip> createState() => _WordBuilderCoinsChipState();
}

class _WordBuilderCoinsChipState extends State<WordBuilderCoinsChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _from = widget.balance;
    _to = widget.balance;
    _pulse = AnimationController(vsync: this, duration: WbTokens.dBase)
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant WordBuilderCoinsChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      final t = Curves.easeOutCubic.transform(_pulse.value);
      _from = (_from + (_to - _from) * t).round();
      _to = widget.balance;
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 22.0 : WordBuilderCoinsChip.coinIconSize;
    final fontSize = widget.compact
        ? WbTokens.tMd
        : WordBuilderCoinsChip.balanceFontSize;
    final pad = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 9);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_pulse.value);
        final display = (_from + (_to - _from) * t).round();
        final pulseScale =
            1.0 + 0.06 * (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
        final label = widget.balanceLabel.contains(RegExp(r'\d'))
            ? widget.balanceLabel.replaceFirstMapped(
                RegExp(r'\d+'),
                (_) => '$display',
              )
            : '$display';
        return Transform.scale(
          scale: _pulse.isAnimating ? pulseScale : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WbTokens.rPill),
              gradient: LinearGradient(
                colors: widget.isDark
                    ? [
                        widget.scheme.surfaceContainerHigh.withValues(
                          alpha: 0.85,
                        ),
                        widget.scheme.surfaceContainerHighest.withValues(
                          alpha: 0.9,
                        ),
                      ]
                    : const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
              ),
              border: Border.all(
                color: const Color(
                  0xFFFFB300,
                ).withValues(alpha: widget.isDark ? 0.55 : 0.9),
                width: widget.compact ? 1.6 : 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF9800,
                  ).withValues(alpha: widget.isDark ? 0.35 : 0.28),
                  blurRadius: widget.compact ? 8 : 12,
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
                    color: widget.isDark
                        ? const Color(0xFFFFCA28)
                        : const Color(0xFFFFA000),
                    shadows: [
                      Shadow(
                        color: Colors.orange.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  SizedBox(width: widget.compact ? 5 : 8),
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0.5,
                      color: widget.isDark
                          ? widget.scheme.onSurface
                          : const Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

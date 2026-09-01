import 'package:flutter/material.dart';

/// Resolved colors for [IdiomsWordCard] — light and dark variants.
class IdiomsWordCardColors {
  const IdiomsWordCardColors({
    required this.card,
    required this.primary,
    required this.textPrimary,
    required this.textMuted,
    required this.translation,
    required this.exampleBg,
    required this.badgeBg,
    required this.border,
    required this.actionFill,
    required this.actionIdle,
    required this.shadow,
  });

  final Color card;
  final Color primary;
  final Color textPrimary;
  final Color textMuted;
  final Color translation;
  final Color exampleBg;
  final Color badgeBg;
  final Color border;
  final Color actionFill;
  final Color actionIdle;
  final Color shadow;

  factory IdiomsWordCardColors.of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const light = IdiomsWordCardColors(
    card: Colors.white,
    primary: Color(0xFF7C5CFC),
    textPrimary: Color(0xFF1F2937),
    textMuted: Color(0xFF6B7280),
    translation: Color(0xFF2563EB),
    exampleBg: Color(0xFFF5F3FF),
    badgeBg: Color(0xFFF3F0FF),
    border: Color(0xFFE5E7EB),
    actionFill: Colors.white,
    actionIdle: Color(0xFF6B7280),
    shadow: Color(0xFF7C5CFC),
  );

  static const dark = IdiomsWordCardColors(
    card: Color(0xFF171C2C),
    primary: Color(0xFFA78BFA),
    textPrimary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    translation: Color(0xFF7DD3FC),
    exampleBg: Color(0xFF1F2438),
    badgeBg: Color(0xFF2A2545),
    border: Color(0xFF2E3648),
    actionFill: Color(0xFF222838),
    actionIdle: Color(0xFF8B95A8),
    shadow: Color(0xFF7C5CFC),
  );
}

/// Page backdrop for idioms words list.
BoxDecoration idiomsWordsPageDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF12182A),
          Color(0xFF0D1020),
          Color(0xFF0A0D18),
        ],
      ),
    );
  }
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [scheme.primary.withValues(alpha: 0.07), scheme.surface],
    ),
  );
}

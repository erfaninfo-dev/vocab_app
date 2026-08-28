import 'package:flutter/material.dart';

/// Accent palette for grammar result cards (My results + Users; avatar unchanged).
class GrammarCommunityCardTheme {
  const GrammarCommunityCardTheme({
    required this.accent,
    this.accentEnd,
  });

  final Color accent;
  final Color? accentEnd;

  Color get end => accentEnd ?? accent;
}

const List<GrammarCommunityCardTheme> kGrammarCommunityCardThemes = [
  GrammarCommunityCardTheme(
    accent: Color(0xFF7C3AED),
    accentEnd: Color(0xFF9333EA),
  ),
  GrammarCommunityCardTheme(
    accent: Color(0xFFEA580C),
    accentEnd: Color(0xFFF97316),
  ),
  GrammarCommunityCardTheme(
    accent: Color(0xFF0D9488),
    accentEnd: Color(0xFF14B8A6),
  ),
  GrammarCommunityCardTheme(
    accent: Color(0xFF2563EB),
    accentEnd: Color(0xFF3B82F6),
  ),
  GrammarCommunityCardTheme(
    accent: Color(0xFFDB2777),
    accentEnd: Color(0xFFEC4899),
  ),
  GrammarCommunityCardTheme(
    accent: Color(0xFF4F46E5),
    accentEnd: Color(0xFF6366F1),
  ),
];

GrammarCommunityCardTheme grammarCommunityCardThemeForIndex(int index) {
  if (kGrammarCommunityCardThemes.isEmpty) {
    return const GrammarCommunityCardTheme(accent: Color(0xFF2563EB));
  }
  final i = index % kGrammarCommunityCardThemes.length;
  return kGrammarCommunityCardThemes[i];
}

/// Card accent from answer accuracy (0.0–1.0). Falls back when [hasScore] is false.
GrammarCommunityCardTheme grammarCommunityCardThemeForAccuracy({
  required double ratio,
  required bool hasScore,
  int fallbackIndex = 0,
}) {
  if (!hasScore) {
    return grammarCommunityCardThemeForIndex(fallbackIndex);
  }

  final pct = (ratio.clamp(0.0, 1.0) * 100).round();
  if (pct >= 90) {
    return const GrammarCommunityCardTheme(
      accent: Color(0xFF16A34A),
      accentEnd: Color(0xFF22C55E),
    );
  }
  if (pct >= 75) {
    return const GrammarCommunityCardTheme(
      accent: Color(0xFF0D9488),
      accentEnd: Color(0xFF14B8A6),
    );
  }
  if (pct >= 60) {
    return const GrammarCommunityCardTheme(
      accent: Color(0xFF2563EB),
      accentEnd: Color(0xFF3B82F6),
    );
  }
  if (pct >= 45) {
    return const GrammarCommunityCardTheme(
      accent: Color(0xFFEA580C),
      accentEnd: Color(0xFFF97316),
    );
  }
  return const GrammarCommunityCardTheme(
    accent: Color(0xFFDC2626),
    accentEnd: Color(0xFFE11D48),
  );
}

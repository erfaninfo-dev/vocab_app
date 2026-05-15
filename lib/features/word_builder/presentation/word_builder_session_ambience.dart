import 'package:flutter/material.dart';

const Color kWordBuilderParchment = Color(0xFFFFF8E7);
const Color kWordBuilderParchmentBorder = Color(0xFFC4956A);
const Color kWordBuilderSkyTop = Color(0xFF87CEEB);

class WordBuilderSessionAmbience {
  WordBuilderSessionAmbience._();

  static LinearGradient skyBackground(ColorScheme scheme, {required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(kWordBuilderSkyTop, scheme.surface, isDark ? 0.35 : 0.12) ??
            scheme.primaryContainer,
        scheme.surface,
      ],
    );
  }

  static List<BoxShadow> parchmentShadows(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static BoxDecoration parchmentPanel({
    required ColorScheme scheme,
    required bool isDark,
    double radius = 22,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(kWordBuilderParchment, Colors.white, isDark ? 0.04 : 0.22) ??
              kWordBuilderParchment,
          Color.lerp(
                kWordBuilderParchment,
                scheme.primaryContainer,
                isDark ? 0.12 : 0.08,
              ) ??
              kWordBuilderParchment,
        ],
      ),
      border: Border.all(
        color: kWordBuilderParchmentBorder.withValues(alpha: isDark ? 0.42 : 0.68),
        width: 2,
      ),
      boxShadow: parchmentShadows(scheme),
    );
  }

  static BoxDecoration actionDock({
    required ColorScheme scheme,
    required bool isDark,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(kWordBuilderParchment, scheme.surface, isDark ? 0.55 : 0.18) ??
              kWordBuilderParchment,
          scheme.surfaceContainerLow.withValues(alpha: isDark ? 0.92 : 0.96),
        ],
      ),
      border: Border.all(
        color: kWordBuilderParchmentBorder.withValues(alpha: isDark ? 0.38 : 0.55),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, -2),
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration currentWordChip({
    required ColorScheme scheme,
    required bool isDark,
    required bool wrong,
  }) {
    if (wrong) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.errorContainer.withValues(alpha: 0.92),
        border: Border.all(color: scheme.error.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scheme.error.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(kWordBuilderParchment, Colors.white, isDark ? 0.06 : 0.28) ??
              kWordBuilderParchment,
          Color.lerp(kWordBuilderParchment, scheme.primaryContainer, 0.12) ??
              kWordBuilderParchment,
        ],
      ),
      border: Border.all(
        color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.22),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static double layoutScale(Size size) {
    final d = size.shortestSide;
    return (d / 430.0).clamp(0.72, 1.0);
  }
}

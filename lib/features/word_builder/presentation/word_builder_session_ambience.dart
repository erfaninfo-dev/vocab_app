import 'package:flutter/material.dart';

const Color kWordBuilderParchment = Color(0xFFFFF6E8);
const Color kWordBuilderParchmentBorder = Color(0xFFC4956A);
const Color kWordBuilderBorderWarm = Color(0xFFD4A574);
const Color kWordBuilderSkyTop = Color(0xFFFFC107);
const Color kWordBuilderSkyBottom = Color(0xFFF48FB1);
const Color kWordBuilderAccentPlay = Color(0xFFE65100);
const Color kWordBuilderAccentPlayLight = Color(0xFFFF8F00);
const Color kWordBuilderWarmShadow = Color(0xFF8D6E63);
const Color kWordBuilderSuccessTop = Color(0xFF66BB6A);
const Color kWordBuilderSuccessBottom = Color(0xFF2E7D32);
const Color kWordBuilderErrorSoft = Color(0xFFFF7043);
const Color kWordBuilderErrorSoftLight = Color(0xFFFFAB91);

class WordBuilderSessionAmbience {
  WordBuilderSessionAmbience._();

  static LinearGradient skyBackground(ColorScheme scheme, {required bool isDark}) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(kWordBuilderSkyTop, scheme.surface, 0.45) ?? scheme.surface,
          Color.lerp(kWordBuilderSkyBottom, scheme.surface, 0.25) ?? scheme.surface,
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [kWordBuilderSkyTop, kWordBuilderSkyBottom],
    );
  }

  static Color appBarBackground(ColorScheme scheme, {required bool isDark}) {
    return Color.lerp(
          kWordBuilderParchment,
          scheme.surface,
          isDark ? 0.55 : 0.12,
        ) ??
        kWordBuilderParchment.withValues(alpha: 0.88);
  }

  static List<BoxShadow> parchmentShadows({required bool isDark}) => [
        BoxShadow(
          color: kWordBuilderWarmShadow.withValues(alpha: isDark ? 0.22 : 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: kWordBuilderAccentPlayLight.withValues(alpha: isDark ? 0.08 : 0.12),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 4),
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
                kWordBuilderSkyBottom,
                isDark ? 0.18 : 0.35,
              ) ??
              kWordBuilderParchment,
        ],
      ),
      border: Border.all(
        color: kWordBuilderBorderWarm.withValues(alpha: isDark ? 0.42 : 0.68),
        width: 2,
      ),
      boxShadow: parchmentShadows(isDark: isDark),
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
          color: kWordBuilderWarmShadow.withValues(alpha: isDark ? 0.16 : 0.14),
          blurRadius: 14,
          offset: const Offset(0, -2),
        ),
        BoxShadow(
          color: kWordBuilderAccentPlayLight.withValues(alpha: isDark ? 0.1 : 0.14),
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
        color: kWordBuilderErrorSoftLight.withValues(alpha: isDark ? 0.35 : 0.55),
        border: Border.all(
          color: kWordBuilderErrorSoft.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kWordBuilderErrorSoft.withValues(alpha: 0.22),
            blurRadius: 14,
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
          Color.lerp(kWordBuilderParchment, Colors.white, isDark ? 0.06 : 0.32) ??
              kWordBuilderParchment,
          Color.lerp(kWordBuilderParchment, kWordBuilderSkyTop, 0.35) ??
              kWordBuilderParchment,
        ],
      ),
      border: Border.all(
        color: kWordBuilderAccentPlayLight.withValues(alpha: isDark ? 0.45 : 0.55),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: kWordBuilderWarmShadow.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: kWordBuilderAccentPlayLight.withValues(alpha: 0.2),
          blurRadius: 18,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static LinearGradient selectedLetterGradient({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFFFFF8E1), Colors.white, isDark ? 0.08 : 0.25)!,
        Color.lerp(kWordBuilderAccentPlayLight, kWordBuilderAccentPlay, 0.35)!,
      ],
    );
  }

  static List<BoxShadow> selectedLetterShadows({required bool isDark}) => [
        BoxShadow(
          color: kWordBuilderAccentPlay.withValues(alpha: isDark ? 0.42 : 0.38),
          blurRadius: isDark ? 10 : 12,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: kWordBuilderAccentPlayLight.withValues(alpha: 0.22),
          blurRadius: 18,
          spreadRadius: 0,
        ),
      ];

  static double layoutScale(Size size) {
    final d = size.shortestSide;
    return (d / 430.0).clamp(0.72, 1.0);
  }
}

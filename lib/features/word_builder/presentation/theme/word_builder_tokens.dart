import 'package:flutter/material.dart';

/// Shared spacing / radius / motion / type tokens for Word Builder UI.
///
/// Prefer these over hardcoded paddings and durations in `presentation/`.
/// Physics constants (`ballRadius`, `gravity`, freeing timers, …) stay in
/// physics files — do **not** migrate them here.
abstract final class WbTokens {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;

  static const double rSm = 10;
  static const double rMd = 18;
  static const double rLg = 28;
  static const double rPill = 999;

  static const Duration dFast = Duration(milliseconds: 140);
  static const Duration dBase = Duration(milliseconds: 240);
  static const Duration dSlow = Duration(milliseconds: 420);

  /// Full-screen ambient transitions (chapter cross-fade). Not UI enter/exit.
  static const Duration dAmbient = Duration(milliseconds: 600);
  static const Curve cAmbient = Curves.easeInOutCubic;

  @Deprecated('Use dAmbient')
  static const Duration dChapter = dAmbient;

  static const Duration dComboIn = Duration(milliseconds: 180);
  static const Duration dShakeWrong = Duration(milliseconds: 300);
  static const Duration dLevelBlur = Duration(milliseconds: 200);
  static const Duration dStagger = Duration(milliseconds: 120);

  static const Curve cEnter = Curves.easeOutCubic;
  static const Curve cExit = Curves.easeInCubic;
  static const Curve cPop = Curves.easeOutBack;

  static const double tXs = 12;
  static const double tSm = 14;
  static const double tMd = 16;
  static const double tLg = 20;
  static const double tXl = 28;
  static const double tHero = 40;

  static const String fontFamily = 'Lexend';
  static const List<String> fontFamilyFallback = ['Vazirmatn'];

  static TextStyle textStyle({
    double fontSize = tMd,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

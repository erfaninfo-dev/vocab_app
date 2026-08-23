import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How the chapter sky gradient is painted (Angry Words board only).
enum WbSkyKind {
  verticalGradient,
  horizontalDual,
}

/// Per-chapter visual theme for **Angry Words only**.
///
/// Classic / Arkanoid / Puzzle keep their own art. Do not apply this outside
/// Angry Words without an explicit product decision.
@immutable
class WbChapterTheme {
  const WbChapterTheme({
    required this.id,
    required this.name,
    required this.firstStage,
    required this.lastStage,
    required this.skyStops,
    required this.groundStops,
    required this.accent,
    required this.particles,
    required this.chromeBrightness,
    required this.chromeSurface,
    required this.chromeOnSurface,
    this.skyKind = WbSkyKind.verticalGradient,
  });

  final String id;
  final String name;
  final int firstStage;
  final int lastStage;
  final List<Color> skyStops;
  final List<Color> groundStops;
  final Color accent;
  final List<Color> particles;
  final Brightness chromeBrightness;
  final Color chromeSurface;
  final Color chromeOnSurface;
  final WbSkyKind skyKind;

  bool containsStage(int stage1Based) =>
      stage1Based >= firstStage && stage1Based <= lastStage;

  /// Filler orbs: light pull toward mid-sky (keep candy color).
  Color biasFillerTowardBackground(Color materialColor) {
    final bg = skyStops.length > 1 ? skyStops[1] : skyStops.first;
    return Color.lerp(materialColor, bg, 0.18)!;
  }

  SystemUiOverlayStyle get systemUiOverlayStyle {
    final lightIcons = chromeBrightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          lightIcons ? Brightness.light : Brightness.dark,
      statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: chromeSurface,
      systemNavigationBarIconBrightness:
          lightIcons ? Brightness.light : Brightness.dark,
    );
  }

  static WbChapterTheme forStage(int stage1Based) {
    final s = stage1Based.clamp(1, 50);
    for (final t in all) {
      if (t.containsStage(s)) return t;
    }
    return all.last;
  }

  /// Bright, playful skies — all chapters use **light** chrome.
  /// Mid stop = saturated color (not mud/black) so the board stays cheerful
  /// while orbs still pop.
  static const List<WbChapterTheme> all = [
    WbChapterTheme(
      id: 'toy_box',
      name: 'Toy Box',
      firstStage: 1,
      lastStage: 7,
      skyStops: [Color(0xFFFFF59D), Color(0xFF1565C0), Color(0xFFFF80AB)],
      groundStops: [Color(0xFFAED581), Color(0xFF9CCC65)],
      accent: Color(0xFFFF5C8A),
      particles: [Color(0xFFFFD166), Color(0xFF7BDFF2), Color(0xFFB8E63B)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF8E7),
      chromeOnSurface: Color(0xFF5D4037),
    ),
    WbChapterTheme(
      id: 'street_spray',
      name: 'Street Spray',
      firstStage: 8,
      lastStage: 10,
      skyStops: [Color(0xFFE1F5FE), Color(0xFF3949AB), Color(0xFFFFAB91)],
      groundStops: [Color(0xFFB0BEC5), Color(0xFF90A4AE)],
      accent: Color(0xFFFFEA00),
      particles: [Color(0xFFFF3D00), Color(0xFF00E5FF), Color(0xFF76FF03)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFF5F7FA),
      chromeOnSurface: Color(0xFF263238),
    ),
    WbChapterTheme(
      id: 'pellet_party',
      name: 'Pellet Party',
      firstStage: 11,
      lastStage: 15,
      skyStops: [Color(0xFFFFE4F0), Color(0xFF6A1B9A), Color(0xFFFFF176)],
      groundStops: [Color(0xFFF48FB1), Color(0xFFF06292)],
      accent: Color(0xFF7C4DFF),
      particles: [Color(0xFFFF80AB), Color(0xFF82B1FF), Color(0xFFFFF176)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF0F6),
      chromeOnSurface: Color(0xFF6A1B4D),
    ),
    WbChapterTheme(
      id: 'war_band',
      name: 'War Band',
      firstStage: 16,
      lastStage: 22,
      skyStops: [Color(0xFFFFF8E1), Color(0xFF2E7D32), Color(0xFFFFB74D)],
      groundStops: [Color(0xFFC5E1A5), Color(0xFFAED581)],
      accent: Color(0xFFFF7043),
      particles: [Color(0xFFFFAB40), Color(0xFFFFE082), Color(0xFFFFCC80)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF8E7),
      chromeOnSurface: Color(0xFF4E342E),
    ),
    WbChapterTheme(
      id: 'ice_fire',
      name: 'Ice & Fire',
      firstStage: 23,
      lastStage: 26,
      skyKind: WbSkyKind.horizontalDual,
      skyStops: [Color(0xFF29B6F6), Color(0xFF455A64), Color(0xFFFF7043)],
      groundStops: [Color(0xFF80CBC4), Color(0xFFFFAB91)],
      accent: Color(0xFF26C6DA),
      particles: [Color(0xFF81D4FA), Color(0xFFFFAB91), Color(0xFFFFE082)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFF7FBFC),
      chromeOnSurface: Color(0xFF37474F),
    ),
    WbChapterTheme(
      id: 'piercers',
      name: 'Piercers',
      firstStage: 27,
      lastStage: 32,
      skyStops: [Color(0xFFE0F7FA), Color(0xFF00695C), Color(0xFF4DD0E1)],
      groundStops: [Color(0xFF80DEEA), Color(0xFF26C6DA)],
      accent: Color(0xFF00BCD4),
      particles: [Color(0xFF80DEEA), Color(0xFFFFF176), Color(0xFF4DD0E1)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFE8FAFC),
      chromeOnSurface: Color(0xFF006064),
    ),
    WbChapterTheme(
      id: 'energy_age',
      name: 'Energy Age',
      firstStage: 33,
      lastStage: 40,
      skyStops: [Color(0xFFF3E5F5), Color(0xFF7B1FA2), Color(0xFF80DEEA)],
      groundStops: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
      accent: Color(0xFFE040FB),
      particles: [Color(0xFF18FFFF), Color(0xFFFF4081), Color(0xFF76FF03)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFF8EAF8),
      chromeOnSurface: Color(0xFF4A148C),
    ),
    WbChapterTheme(
      id: 'boom_brigade',
      name: 'Boom Brigade',
      firstStage: 41,
      lastStage: 45,
      skyStops: [Color(0xFFFFFDE7), Color(0xFFC62828), Color(0xFFFFB74D)],
      groundStops: [Color(0xFFFFE082), Color(0xFFFFCA28)],
      accent: Color(0xFFFFEA00),
      particles: [Color(0xFFFFAB00), Color(0xFFFF5722), Color(0xFFFFF59D)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF8E1),
      chromeOnSurface: Color(0xFF5D4037),
    ),
    WbChapterTheme(
      id: 'endgame',
      name: 'Endgame',
      firstStage: 46,
      lastStage: 50,
      skyStops: [Color(0xFFFFF3E0), Color(0xFF6A1B9A), Color(0xFFFFD54F)],
      groundStops: [Color(0xFFFFCC80), Color(0xFFFFB74D)],
      accent: Color(0xFFFFD54F),
      particles: [Color(0xFFFFE082), Color(0xFFFF80AB), Color(0xFF82B1FF)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF8E7),
      chromeOnSurface: Color(0xFF4A148C),
    ),
  ];
}

/// Provides [WbChapterTheme] to Angry Words session chrome.
class WbChapterThemeScope extends InheritedWidget {
  const WbChapterThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final WbChapterTheme theme;

  static WbChapterTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WbChapterThemeScope>()
        ?.theme;
  }

  static WbChapterTheme of(BuildContext context) {
    final t = maybeOf(context);
    assert(t != null, 'WbChapterThemeScope not found');
    return t!;
  }

  @override
  bool updateShouldNotify(WbChapterThemeScope oldWidget) =>
      theme.id != oldWidget.theme.id;
}

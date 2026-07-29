import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How the chapter sky gradient is painted (Angry Words board only).
enum WbSkyKind {
  /// Top → bottom stops.
  verticalGradient,

  /// Left (cool) → center (neutral) → right (warm). Keeps mid-board readable.
  horizontalDual,
}

/// Per-chapter visual theme for **Angry Words only**.
///
/// Classic / Arkanoid / Puzzle keep their own art (`MagicBackground`, tray
/// scenes). Do not apply [WbChapterTheme] outside Angry Words without an
/// explicit product decision.
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

  /// Exactly three sky colors (top/mid/bottom or left/center/right).
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

  /// Relative filler tint: pull material color 35% toward chapter mid-sky.
  Color biasFillerTowardBackground(Color materialColor) {
    final bg = skyStops.length > 1 ? skyStops[1] : skyStops.first;
    return Color.lerp(materialColor, bg, 0.35)!;
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

  /// Nine chapters — see palette notes in docs / PR review.
  static const List<WbChapterTheme> all = [
    // 1 Toy Box — handcrafted warm pastel (off Material Orange 100)
    WbChapterTheme(
      id: 'toy_box',
      name: 'Toy Box',
      firstStage: 1,
      lastStage: 7,
      skyStops: [Color(0xFFFFE8C8), Color(0xFFFFB88A), Color(0xFFF07850)],
      groundStops: [Color(0xFF8B5E3C), Color(0xFF5C3D28)],
      accent: Color(0xFFFF5C8A),
      particles: [Color(0xFFFFD166), Color(0xFF7BDFF2), Color(0xFFB8E63B)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF6EB),
      chromeOnSurface: Color(0xFF4A2F1F),
    ),
    // 2 Street Spray — energetic concrete + graffiti accents (≠ Piercers)
    WbChapterTheme(
      id: 'street_spray',
      name: 'Street Spray',
      firstStage: 8,
      lastStage: 10,
      skyStops: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFF546E7A)],
      groundStops: [Color(0xFF455A64), Color(0xFF263238)],
      accent: Color(0xFFFFEA00),
      particles: [Color(0xFFFF3D00), Color(0xFF00E5FF), Color(0xFF76FF03)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFECEFF1),
      chromeOnSurface: Color(0xFF1C2830),
    ),
    // 3 Pellet Party — candy fair
    WbChapterTheme(
      id: 'pellet_party',
      name: 'Pellet Party',
      firstStage: 11,
      lastStage: 15,
      skyStops: [Color(0xFFFFE8F0), Color(0xFFFFB3D1), Color(0xFFE85D9A)],
      groundStops: [Color(0xFF9C4D6E), Color(0xFF5C2A42)],
      accent: Color(0xFF7C4DFF),
      particles: [Color(0xFFFF80AB), Color(0xFF82B1FF), Color(0xFFFFF176)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF0F6),
      chromeOnSurface: Color(0xFF4A1F35),
    ),
    // 4 War Band — dusty campaign; ground cooler than sand material
    WbChapterTheme(
      id: 'war_band',
      name: 'War Band',
      firstStage: 16,
      lastStage: 22,
      skyStops: [Color(0xFFE8D5B5), Color(0xFFC4A574), Color(0xFF8A6A3E)],
      groundStops: [Color(0xFF5A4638), Color(0xFF3A2E28)],
      accent: Color(0xFFD84315),
      particles: [Color(0xFFFFAB40), Color(0xFFA1887F), Color(0xFFFFCC80)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFF5EDE0),
      chromeOnSurface: Color(0xFF3E2C1C),
    ),
    // 5 Ice & Fire — dual sky with neutral mid (not hard horizontal split)
    WbChapterTheme(
      id: 'ice_fire',
      name: 'Ice & Fire',
      firstStage: 23,
      lastStage: 26,
      skyKind: WbSkyKind.horizontalDual,
      skyStops: [Color(0xFFA8DCF8), Color(0xFFE8ECF0), Color(0xFFFF9E7A)],
      groundStops: [Color(0xFF6B7B8A), Color(0xFF4A3A36)],
      accent: Color(0xFF26C6DA),
      particles: [Color(0xFF81D4FA), Color(0xFFFFAB91), Color(0xFFE0E0E0)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFF4F6F8),
      chromeOnSurface: Color(0xFF2A3238),
    ),
    // 6 Piercers — cooler bluer steel (≠ Street Spray Blue Grey)
    WbChapterTheme(
      id: 'piercers',
      name: 'Piercers',
      firstStage: 27,
      lastStage: 32,
      skyStops: [Color(0xFFB8C9D4), Color(0xFF6B8799), Color(0xFF3D5566)],
      groundStops: [Color(0xFF2C3E4A), Color(0xFF1A2830)],
      accent: Color(0xFF00BCD4),
      particles: [Color(0xFF80DEEA), Color(0xFFB0BEC5), Color(0xFF4DD0E1)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFE8F0F4),
      chromeOnSurface: Color(0xFF152028),
    ),
    // 7 Energy Age — neon night (chrome dark)
    WbChapterTheme(
      id: 'energy_age',
      name: 'Energy Age',
      firstStage: 33,
      lastStage: 40,
      skyStops: [Color(0xFF1A0A2E), Color(0xFF2D1B4E), Color(0xFF0D0221)],
      groundStops: [Color(0xFF12081C), Color(0xFF07040E)],
      accent: Color(0xFFE040FB),
      particles: [Color(0xFF18FFFF), Color(0xFFFF4081), Color(0xFF76FF03)],
      chromeBrightness: Brightness.dark,
      chromeSurface: Color(0xFF1E1230),
      chromeOnSurface: Color(0xFFF3E5F5),
    ),
    // 8 Boom Brigade — hot & bright (NOT dark; breaks 18-stage gloom)
    WbChapterTheme(
      id: 'boom_brigade',
      name: 'Boom Brigade',
      firstStage: 41,
      lastStage: 45,
      skyStops: [Color(0xFFFFCA28), Color(0xFFFF7043), Color(0xFFBF360C)],
      groundStops: [Color(0xFF6D4C41), Color(0xFF4E342E)],
      accent: Color(0xFFFFEA00),
      particles: [Color(0xFFFFAB00), Color(0xFFFF5722), Color(0xFFFFF59D)],
      chromeBrightness: Brightness.light,
      chromeSurface: Color(0xFFFFF3E0),
      chromeOnSurface: Color(0xFF3E2723),
    ),
    // 9 Endgame — handcrafted majestic dark + custom gold
    WbChapterTheme(
      id: 'endgame',
      name: 'Endgame',
      firstStage: 46,
      lastStage: 50,
      skyStops: [Color(0xFF0C0A0F), Color(0xFF1A1520), Color(0xFF2A2010)],
      groundStops: [Color(0xFF12100C), Color(0xFF080706)],
      accent: Color(0xFFE8C547),
      particles: [Color(0xFFFFE082), Color(0xFFBCAAA4), Color(0xFFFFD54F)],
      chromeBrightness: Brightness.dark,
      chromeSurface: Color(0xFF1A1612),
      chromeOnSurface: Color(0xFFFFF8E1),
    ),
  ];
}

/// Convenience: chapter label helpers stay on [WbChapterMeta]; themes here.

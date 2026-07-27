/// Optional Word Builder input presentation mode.
///
/// Classic keeps the circular letter tray + tray scenarios.
/// Arkanoid replaces only the input surface with a breakout-style board.
/// Angry Words uses slingshot aiming + physics trajectory preview.
/// Puzzle uses a sliding-tile grid (15-puzzle style) with letter tiles.
/// Word validation, coins, hints and campaign progress stay shared.
enum WordBuilderPlayMode {
  classic,
  arkanoid,
  angryWords,
  puzzle,
}

extension WordBuilderPlayModeX on WordBuilderPlayMode {
  String get prefsValue => name;

  /// Compact physics boards that skip tray tension / game-over water.
  bool get usesPhysicsLetterBoard =>
      this == WordBuilderPlayMode.arkanoid ||
      this == WordBuilderPlayMode.angryWords;

  bool get usesPuzzleLetterBoard => this == WordBuilderPlayMode.puzzle;

  /// Non-classic boards that share the compact session layout (no tray chrome).
  bool get usesCompactLetterBoard =>
      usesPhysicsLetterBoard || usesPuzzleLetterBoard;

  /// Modes that never raise tray water or trigger tray game-over.
  bool get skipsTrayTension => usesCompactLetterBoard;

  static WordBuilderPlayMode fromPrefs(String? raw) {
    for (final mode in WordBuilderPlayMode.values) {
      if (raw == mode.name) return mode;
    }
    return WordBuilderPlayMode.classic;
  }
}

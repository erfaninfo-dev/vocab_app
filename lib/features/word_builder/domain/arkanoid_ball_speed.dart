/// Ball speed levels 1..10 for Word Builder Arkanoid mode.
abstract final class ArkanoidBallSpeedScale {
  static const int minLevel = 1;
  static const int maxLevel = 10;
  static const int defaultLevel = 3;

  static int clampLevel(int level) =>
      level.clamp(minLevel, maxLevel);

  /// Maps level 1..10 → t in 0..1.
  static double _t(int level) =>
      (clampLevel(level) - minLevel) / (maxLevel - minLevel);

  /// Minimum velocity magnitude (px/s).
  static double minSpeed(int level) {
    final t = _t(level);
    return 95 + t * 185; // ~95..280
  }

  /// Maximum velocity magnitude (px/s).
  static double maxSpeed(int level) {
    final t = _t(level);
    return 140 + t * 260; // ~140..400
  }

  static double launchSpeed(int level) =>
      (minSpeed(level) + maxSpeed(level)) / 2;

  /// Migrates legacy enum prefs (`slow`/`normal`/`fast`) or int strings.
  static int fromPrefs(String? raw, {int? intRaw}) {
    if (intRaw != null) return clampLevel(intRaw);
    switch (raw) {
      case 'slow':
        return 2;
      case 'normal':
        return 5;
      case 'fast':
        return 9;
      default:
        final parsed = int.tryParse(raw ?? '');
        if (parsed != null) return clampLevel(parsed);
        return defaultLevel;
    }
  }
}

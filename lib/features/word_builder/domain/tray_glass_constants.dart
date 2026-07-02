abstract final class TrayGlassConstants {
  static const int maxWrongBeforeShatter = 5;
  static const double crackPerWrong = 0.2;

  static const int maxCrackSegments = 12;
  static const int maxShatterParticles = 48;

  static const Duration crackGrowDuration = Duration(milliseconds: 520);
  static const Duration healFadeDuration = Duration(milliseconds: 680);
  static const Duration impactShakeDuration = Duration(milliseconds: 340);
  static const Duration shatterDuration = Duration(milliseconds: 1100);
  static const Duration gameOverModalDelay = Duration(milliseconds: 380);
}

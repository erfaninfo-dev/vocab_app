/// Timings and thresholds for the train-escape tray scenario.
///
/// Tension (0..1) is shared with the water scenario and stored in
/// `WordBuilderViewState.trayWaterLevel`; here it drives how close the
/// train/headlight is to the tied character.
abstract final class TrayTrainConstants {
  /// Three rope segments; each correct word fully snaps one open.
  /// The third (last) snaps during [escape].
  static const int ropeCount = 3;

  static const Duration ropeSnapDuration = Duration(milliseconds: 800);
  static const Duration escapeDuration = Duration(milliseconds: 700);
  static const Duration trainPassDuration = Duration(milliseconds: 1150);

  /// Extra hold after the train pass before the level-complete panel shows.
  static const Duration victoryEndPadding = Duration(milliseconds: 250);

  static const Duration headlightPulseDuration = Duration(milliseconds: 650);

  /// Game over: the train rushes down the rails, hits the character and
  /// flings them out of the tray — no white flash.
  static const Duration gameOverRushDuration = Duration(milliseconds: 950);
  static const Duration gameOverFlingDuration = Duration(milliseconds: 1050);

  /// Fraction of the rush at which the train nose reaches the character
  /// (must match the ease curve used by the painter).
  static const double gameOverImpactFraction = 0.78;

  static const Duration gameOverModalDelay = Duration(milliseconds: 450);

  /// Tension at which the train silhouette becomes visible behind the light.
  static const double trainSilhouetteThreshold = 0.5;

  /// Passive creep: tension tween slows down for tiny increments so the
  /// train appears to glide closer continuously (like the tub filling).
  static const double smallTensionDelta = 0.06;
  static const Duration tensionTweenFast = Duration(milliseconds: 900);
  static const Duration tensionTweenCreep = Duration(milliseconds: 3000);
}

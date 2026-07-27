/// Timings and thresholds for the prison-escape tray scenario.
///
/// Tension (0..1) is shared with the other scenarios and stored in
/// `WordBuilderViewState.trayWaterLevel`; here it drives how close the
/// guard is to waking up. Reach progress (solved / targets) drives how
/// close the prisoner's hand is to the key.
abstract final class TrayPrisonConstants {
  /// How much of the way to the key the hand travels before the final
  /// word; the key is only grabbed during the escape sequence.
  static const double maxReachBeforeComplete = 0.82;

  /// Victory beat A — key steal stages (linear 0..1 over this duration):
  /// 0.00–0.20 approach · 0.20–0.38 contact · 0.38–0.62 unclip · 0.62–1.00 settle.
  static const Duration keyGrabDuration = Duration(milliseconds: 1200);
  static const Duration escapeDuration = Duration(milliseconds: 2200);

  /// Extra hold after the escape before the level-complete panel shows.
  static const Duration victoryEndPadding = Duration(milliseconds: 300);

  /// Guard reaction pulse right after a wrong answer.
  static const Duration guardPulseDuration = Duration(milliseconds: 780);

  /// Game-over beat B — soft grab stages (linear 0..1 over this duration):
  /// 0.00–0.28 wake · 0.28–0.48 stand · 0.48–0.62 step ·
  /// 0.62–0.82 soft grab · 0.82–0.93 retract · 0.93–1.00 lock.
  static const Duration gameOverGrabDuration = Duration(milliseconds: 1900);
  static const Duration gameOverModalDelay = Duration(milliseconds: 420);

  /// Hand reach tween between solved-count steps.
  static const Duration reachTweenDuration = Duration(milliseconds: 950);

  /// Passive creep: tension tween slows down for tiny increments so the
  /// guard's sleep gets visibly lighter continuously.
  static const double smallTensionDelta = 0.06;
  static const Duration tensionTweenFast = Duration(milliseconds: 1000);
  static const Duration tensionTweenCreep = Duration(milliseconds: 3200);
}

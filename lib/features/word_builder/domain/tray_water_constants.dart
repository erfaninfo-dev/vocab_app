/// Tray water mini-game limits and mood for the center face.
enum TrayFaceMood {
  neutral,
  happy,
  stressed,
  panic,
  dead,
}

abstract final class TrayWaterConstants {
  static const int maxWrongBeforeOverflow = 5;
  static const double waterPerWrong = 0.2;
  /// آب آرام از لولهٔ راست — اگر بازیکن دیر جواب دهد.
  static const Duration passiveWaterTickInterval = Duration(milliseconds: 3200);
  static const double passiveWaterIncrement = 0.017;
  static const Duration passiveDripCycleDuration = Duration(milliseconds: 900);
  /// یک دور حرکت حباب در لولهٔ ورودی ≈ همان ریتم پر شدن آرام سینی.
  static const Duration inletPipeFlowCycleDuration = passiveWaterTickInterval;
  static const double inletPipeFlowTravelScale = 0.095;
  static const double passiveInletVisualOpen = 0.38;
  static const Duration inletOpenDuration = Duration(milliseconds: 1100);
  static const Duration outletOpenDuration = Duration(milliseconds: 1300);
  static const Duration happyMoodDuration = Duration(milliseconds: 2400);
  static const Duration reactionPulseDuration = Duration(milliseconds: 650);
  static const Duration gameOverFillDuration = Duration(milliseconds: 900);
  static const Duration gameOverFlipDuration = Duration(milliseconds: 1400);
  static const Duration gameOverModalDelay = Duration(milliseconds: 450);
}

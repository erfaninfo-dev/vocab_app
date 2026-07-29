import 'package:flutter/material.dart';

/// Reduced-motion / accessibility scaling for Word Builder juice (Phase 5).
///
/// Use [WbMotion.of] from widgets; physics can take [particleScale] /
/// [allowShake] / [allowIdlePulse] via the board.
class WbMotion {
  const WbMotion._({required this.reduced});

  factory WbMotion.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return WbMotion._(
      reduced: mq.disableAnimations || mq.accessibleNavigation,
    );
  }

  /// True when store accessibility asks for less motion.
  final bool reduced;

  /// Halve durations when reduced; otherwise identity.
  Duration scale(Duration duration) {
    if (!reduced) return duration;
    final us = duration.inMicroseconds;
    return Duration(microseconds: (us / 2).round().clamp(1, us));
  }

  double get particleScale => reduced ? 0.25 : 1.0;

  bool get allowShake => !reduced;

  bool get allowIdlePulse => !reduced;

  /// Screen-shake amplitude multiplier (0 when reduced).
  double get shakeScale => reduced ? 0 : 1;

  /// Cap for screen shake offset in logical pixels.
  static const double maxShakePx = 6;

  /// Hit-stop freeze after a correct letter hit.
  static const Duration hitStop = Duration(milliseconds: 50);

  /// Screen-shake decay window (~250ms → rate 4/s).
  static const double shakeDecayPerSec = 4;
}

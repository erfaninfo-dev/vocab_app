import 'package:flutter/material.dart';

/// Accessibility / juice scale for Word Builder (phase 5 §4).
///
/// When the OS asks to reduce motion (`disableAnimations` or
/// `accessibleNavigation`): no screen shake, particles at 25%, durations ×0.5,
/// crack overlays jump to the final stage (no growth animation), fluid pools
/// appear at full size (no gradual spread).
@immutable
class WbMotion {
  const WbMotion({
    required this.reduced,
    required this.particleScale,
    required this.durationScale,
    required this.allowScreenShake,
    required this.animateCrackGrowth,
    required this.animateFluidSpread,
  });

  final bool reduced;

  /// Multiply explosion / debris shard counts (1.0 normal, 0.25 reduced).
  final double particleScale;

  /// Multiply animation durations (1.0 normal, 0.5 reduced).
  final double durationScale;

  final bool allowScreenShake;

  /// When false, crack overlays show the final damaged stage immediately.
  final bool animateCrackGrowth;

  /// When false, fluid pools spawn at full radius (no expand tween).
  final bool animateFluidSpread;

  static const WbMotion full = WbMotion(
    reduced: false,
    particleScale: 1,
    durationScale: 1,
    allowScreenShake: true,
    animateCrackGrowth: true,
    animateFluidSpread: true,
  );

  static const WbMotion reducedMotion = WbMotion(
    reduced: true,
    particleScale: 0.25,
    durationScale: 0.5,
    allowScreenShake: false,
    animateCrackGrowth: false,
    animateFluidSpread: false,
  );

  static WbMotion of(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return full;
    if (mq.disableAnimations || mq.accessibleNavigation) {
      return reducedMotion;
    }
    return full;
  }

  Duration scale(Duration d) {
    if (durationScale >= 0.99) return d;
    return Duration(
      microseconds: (d.inMicroseconds * durationScale).round().clamp(1, 1 << 30),
    );
  }
}

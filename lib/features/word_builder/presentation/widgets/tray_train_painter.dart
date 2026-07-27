import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tray_train_constants.dart';

/// Night diorama for the train-escape scenario: sky, fog, rails with
/// perspective, approaching headlight/train, victory train pass and the
/// game-over collision rush. Everything is clipped inside the scene circle.
class TrayTrainPainter extends CustomPainter {
  TrayTrainPainter({
    required this.size,
    required this.center,
    required this.sceneRadius,
    required this.saucerRadius,
    required this.tension,
    required this.ambientPhase,
    required this.headlightPulse,
    required this.trainPassProgress,
    required this.gameOverRushProgress,
    required this.impactBurst,
    required this.isGameOver,
  });

  final Size size;
  final Offset center;

  /// Dark circular viewport (≈ 0.72 × [saucerRadius]).
  final double sceneRadius;
  final double saucerRadius;

  /// 0..1 — how close the train is.
  final double tension;

  /// 0..1 looping phase for fog drift / light flicker / rail shimmer.
  final double ambientPhase;

  /// 0..1 elastic pulse right after a wrong answer.
  final double headlightPulse;

  /// 0..1 — victory: the train sweeps down the rails past the character.
  final double trainPassProgress;

  /// 0..1 — game over: the train charges down the rails into the character.
  final double gameOverRushProgress;

  /// 0..1 — short dust/debris burst right after the collision.
  final double impactBurst;

  final bool isGameOver;

  static const Color _skyTop = Color(0xFF1A1A2E);
  static const Color _skyBottom = Color(0xFF16213E);
  static const Color _railColor = Color(0xFF9FA8B8);
  static const Color _sleeperColor = Color(0xFF4E3B2A);
  static const Color _headlightCore = Color(0xFFFFF9E6);
  static const Color _headlightGlow = Color(0xFFFFC960);
  static const Color _trainBody = Color(0xFF10131C);

  Rect get _sceneRect => Rect.fromCircle(center: center, radius: sceneRadius);

  Offset get _vanishingPoint => Offset(center.dx, center.dy - sceneRadius * 0.82);

  double get _nearY => center.dy + sceneRadius * 0.92;

  /// Half-width of the track at a given screen y (perspective).
  double _trackHalfWidth(double y) {
    final vp = _vanishingPoint;
    final t = ((y - vp.dy) / (_nearY - vp.dy)).clamp(0.0, 1.0);
    return sceneRadius * 0.52 * t;
  }

  double _railJitter() {
    if (tension < 0.35 && trainPassProgress <= 0 && gameOverRushProgress <= 0) {
      return 0;
    }
    final strength = trainPassProgress > 0 || gameOverRushProgress > 0
        ? 1.6
        : ((tension - 0.35) / 0.65).clamp(0.0, 1.0);
    return math.sin(ambientPhase * math.pi * 10) * 1.6 * strength;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sceneRadius <= 0) return;
    canvas.save();
    canvas.clipPath(Path()..addOval(_sceneRect));
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: saucerRadius)),
    );

    _paintSky(canvas);
    _paintStars(canvas);
    _paintGround(canvas);
    _paintRails(canvas);
    _paintFog(canvas);
    if (gameOverRushProgress > 0) {
      _paintGameOverRush(canvas);
    } else if (trainPassProgress > 0) {
      _paintTrainPass(canvas);
    } else {
      _paintApproachingTrain(canvas);
    }
    _paintImpactBurst(canvas);

    canvas.restore();
    _paintRimGlow(canvas);
  }

  void _paintSky(Canvas canvas) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBottom],
      ).createShader(_sceneRect);
    canvas.drawRect(_sceneRect, paint);
  }

  void _paintStars(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final rng = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * 0.9;
      final p = center +
          Offset(math.cos(ang), math.sin(ang)) * sceneRadius * dist;
      if (p.dy > center.dy + sceneRadius * 0.1) continue;
      final twinkle =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(ambientPhase * math.pi * 2 + i));
      canvas.drawCircle(
        p,
        (i % 3 == 0 ? 1.4 : 0.9),
        paint..color = Colors.white.withValues(alpha: 0.55 * twinkle),
      );
    }
  }

  void _paintGround(Canvas canvas) {
    final vp = _vanishingPoint;
    final groundTop = vp.dy + sceneRadius * 0.12;
    final rect = Rect.fromLTRB(
      _sceneRect.left,
      groundTop,
      _sceneRect.right,
      _sceneRect.bottom,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF232338), Color(0xFF2B2540)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintRails(Canvas canvas) {
    final vp = _vanishingPoint;
    final jitter = _railJitter();

    final sleeperPaint = Paint()
      ..color = _sleeperColor
      ..strokeCap = StrokeCap.round;
    const sleeperCount = 9;
    for (var i = 0; i < sleeperCount; i++) {
      // Perspective spacing: denser near the horizon.
      final t = math.pow((i + 1) / sleeperCount, 1.7).toDouble();
      final y = vp.dy + (_nearY - vp.dy) * t;
      final hw = _trackHalfWidth(y) * 1.18;
      sleeperPaint.strokeWidth = (1.2 + 4.6 * t).clamp(1.2, 6.0);
      canvas.drawLine(
        Offset(center.dx - hw + jitter * t, y),
        Offset(center.dx + hw + jitter * t, y),
        sleeperPaint,
      );
    }

    final railPaint = Paint()
      ..color = _railColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final side in const [-1.0, 1.0]) {
      final path = Path();
      var first = true;
      const steps = 14;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final y = vp.dy + (_nearY - vp.dy) * t;
        final x = center.dx + side * _trackHalfWidth(y) + jitter * t;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      railPaint.strokeWidth = 2.6;
      canvas.drawPath(path, railPaint);
      // Moon-lit inner edge.
      railPaint
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawPath(path, railPaint);
      railPaint.color = _railColor;
    }
  }

  void _paintFog(Canvas canvas) {
    final fogPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (var i = 0; i < 3; i++) {
      final drift =
          math.sin(ambientPhase * math.pi * 2 + i * 2.1) * sceneRadius * 0.08;
      final y = center.dy - sceneRadius * (0.18 - i * 0.16);
      fogPaint.color = Colors.white.withValues(alpha: 0.05 + i * 0.015);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + drift, y),
          width: sceneRadius * (1.4 - i * 0.25),
          height: sceneRadius * 0.22,
        ),
        fogPaint,
      );
    }
  }

  ({Offset pos, double radius, double alpha}) _headlightGeometry() {
    final progress = Curves.easeIn.transform(tension.clamp(0.0, 1.0));
    final vp = _vanishingPoint;
    final farY = vp.dy + sceneRadius * 0.16;
    final nearLightY = center.dy + sceneRadius * 0.05;
    final y = farY + (nearLightY - farY) * progress;
    final pulse = 1.0 + headlightPulse * 0.3;
    final radius =
        (sceneRadius * 0.045 + sceneRadius * 0.3 * progress) * pulse;
    final flicker =
        1.0 - 0.06 * (0.5 + 0.5 * math.sin(ambientPhase * math.pi * 7));
    final alpha = (0.35 + 0.65 * progress) * flicker;
    return (pos: Offset(center.dx, y), radius: radius, alpha: alpha);
  }

  void _paintApproachingTrain(Canvas canvas) {
    final light = _headlightGeometry();
    final progress = Curves.easeIn.transform(tension.clamp(0.0, 1.0));

    if (tension >= TrayTrainConstants.trainSilhouetteThreshold) {
      final silT = ((tension - TrayTrainConstants.trainSilhouetteThreshold) /
              (1.0 - TrayTrainConstants.trainSilhouetteThreshold))
          .clamp(0.0, 1.0);
      _paintTrainBody(
        canvas,
        noseCenter: light.pos,
        scale: 0.35 + 0.75 * silT,
        alpha: 0.45 + 0.55 * silT,
      );
    }

    _paintHeadlightBeam(canvas, light.pos, light.radius, progress);
    _paintHeadlight(canvas, light.pos, light.radius, light.alpha);
  }

  void _paintHeadlightBeam(
    Canvas canvas,
    Offset pos,
    double radius,
    double progress,
  ) {
    if (progress <= 0.05) return;
    final beamLen = sceneRadius * (0.5 + 0.7 * progress);
    final beam = Path()
      ..moveTo(pos.dx - radius * 0.5, pos.dy)
      ..lineTo(pos.dx - radius * 2.6, pos.dy + beamLen)
      ..lineTo(pos.dx + radius * 2.6, pos.dy + beamLen)
      ..lineTo(pos.dx + radius * 0.5, pos.dy)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _headlightGlow.withValues(alpha: 0.30 * progress),
          _headlightGlow.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTRB(
          pos.dx - radius * 2.6,
          pos.dy,
          pos.dx + radius * 2.6,
          pos.dy + beamLen,
        ),
      );
    canvas.drawPath(beam, paint);
  }

  void _paintHeadlight(
    Canvas canvas,
    Offset pos,
    double radius,
    double alpha,
  ) {
    final halo = Paint()
      ..color = _headlightGlow.withValues(alpha: alpha * 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(pos, radius * 2.1, halo);

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          _headlightCore.withValues(alpha: alpha),
          _headlightGlow.withValues(alpha: alpha * 0.85),
          _headlightGlow.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: radius * 1.5));
    canvas.drawCircle(pos, radius * 1.5, core);
  }

  void _paintTrainBody(
    Canvas canvas, {
    required Offset noseCenter,
    required double scale,
    required double alpha,
  }) {
    final w = sceneRadius * 0.6 * scale;
    final h = sceneRadius * 0.72 * scale;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: noseCenter.translate(0, -h * 0.42),
        width: w,
        height: h,
      ),
      Radius.circular(w * 0.26),
    );
    final paint = Paint()..color = _trainBody.withValues(alpha: alpha);
    canvas.drawRRect(body, paint);

    // Cab roof + two small marker lights.
    final roof = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: noseCenter.translate(0, -h * 0.86),
        width: w * 0.72,
        height: h * 0.22,
      ),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(roof, paint);
    final marker = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: alpha * 0.9);
    canvas.drawCircle(noseCenter.translate(-w * 0.3, -h * 0.12), w * 0.05, marker);
    canvas.drawCircle(noseCenter.translate(w * 0.3, -h * 0.12), w * 0.05, marker);
  }

  void _paintTrainPass(Canvas canvas) {
    final t = Curves.easeInQuart.transform(trainPassProgress.clamp(0.0, 1.0));
    final vp = _vanishingPoint;
    final startY = vp.dy + sceneRadius * 0.1;
    final endY = center.dy + sceneRadius * 1.65;
    final noseY = startY + (endY - startY) * t;
    final scale = 0.4 + 1.5 * t;

    // Motion streaks behind the nose.
    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 * (1 - t))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final sx = center.dx + (i - 1.5) * sceneRadius * 0.16 * scale;
      canvas.drawLine(
        Offset(sx, noseY - sceneRadius * 0.9 * scale),
        Offset(sx, noseY - sceneRadius * 0.35 * scale),
        streak,
      );
    }

    _paintTrainBody(
      canvas,
      noseCenter: Offset(center.dx, noseY),
      scale: scale,
      alpha: 0.96,
    );
    _paintHeadlight(
      canvas,
      Offset(center.dx, noseY - sceneRadius * 0.06 * scale),
      sceneRadius * 0.12 * scale,
      0.95,
    );

    // Wind gust.
    final gust = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 * (1 - t))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, noseY),
        width: sceneRadius * 1.5 * scale,
        height: sceneRadius * 0.4 * scale,
      ),
      gust,
    );
  }

  /// Game over: the train accelerates down the rails toward the character.
  /// Curve must match [TrayTrainConstants.gameOverImpactFraction].
  void _paintGameOverRush(Canvas canvas) {
    final t = Curves.easeInCubic.transform(gameOverRushProgress.clamp(0.0, 1.0));
    final vp = _vanishingPoint;
    final startY = vp.dy + sceneRadius * 0.1;
    final endY = center.dy + sceneRadius * 1.65;
    final noseY = startY + (endY - startY) * t;
    final scale = 0.4 + 1.5 * t;

    // Speed streaks.
    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * (1 - t * 0.6))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final sx = center.dx + (i - 1.5) * sceneRadius * 0.16 * scale;
      canvas.drawLine(
        Offset(sx, noseY - sceneRadius * 0.9 * scale),
        Offset(sx, noseY - sceneRadius * 0.35 * scale),
        streak,
      );
    }

    _paintTrainBody(
      canvas,
      noseCenter: Offset(center.dx, noseY),
      scale: scale,
      alpha: 0.97,
    );
    _paintHeadlight(
      canvas,
      Offset(center.dx, noseY - sceneRadius * 0.06 * scale),
      sceneRadius * 0.14 * scale,
      1.0,
    );

    // Sparks screeching off the rails while braking.
    final sparkRng = math.Random((ambientPhase * 40).floor());
    final spark = Paint()..strokeCap = StrokeCap.round;
    final hw = _trackHalfWidth(noseY.clamp(vp.dy, _nearY));
    for (var i = 0; i < 5; i++) {
      final side = i.isEven ? -1.0 : 1.0;
      final sx = center.dx + side * hw;
      final len = sceneRadius * (0.05 + sparkRng.nextDouble() * 0.08);
      final ang = -math.pi / 2 + side * (0.4 + sparkRng.nextDouble() * 0.5);
      spark
        ..color = const Color(0xFFFFD54F)
            .withValues(alpha: 0.5 + sparkRng.nextDouble() * 0.4)
        ..strokeWidth = 1.6;
      canvas.drawLine(
        Offset(sx, noseY),
        Offset(sx + math.cos(ang) * len, noseY + math.sin(ang) * len),
        spark,
      );
    }
  }

  /// Dust and debris where the train hit the character.
  void _paintImpactBurst(Canvas canvas) {
    if (impactBurst <= 0) return;
    final t = impactBurst.clamp(0.0, 1.0);
    final fade = 1.0 - Curves.easeIn.transform(t);
    final impact = Offset(center.dx, center.dy + sceneRadius * 0.44);

    final dust = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.5 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(impact, sceneRadius * (0.12 + 0.4 * t), dust);

    final debris = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.85 * fade);
    final rng = math.Random(11);
    for (var i = 0; i < 7; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final dist = sceneRadius * (0.1 + 0.5 * t) * (0.6 + rng.nextDouble());
      final p = impact + Offset(math.cos(ang), math.sin(ang) * 0.7) * dist;
      canvas.drawLine(p, p + Offset(math.cos(ang), math.sin(ang)) * 5, debris);
    }
  }

  void _paintRimGlow(Canvas canvas) {
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF3D4A6B).withValues(alpha: 0.9),
          const Color(0xFF7986CB).withValues(alpha: 0.55),
          const Color(0xFF3D4A6B).withValues(alpha: 0.9),
        ],
        transform: GradientRotation(ambientPhase * math.pi * 2),
      ).createShader(_sceneRect);
    canvas.drawCircle(center, sceneRadius, rim);
  }

  @override
  bool shouldRepaint(covariant TrayTrainPainter old) {
    return old.tension != tension ||
        old.ambientPhase != ambientPhase ||
        old.headlightPulse != headlightPulse ||
        old.trainPassProgress != trainPassProgress ||
        old.gameOverRushProgress != gameOverRushProgress ||
        old.impactBurst != impactBurst ||
        old.isGameOver != isGameOver ||
        old.center != center ||
        old.sceneRadius != sceneRadius;
  }
}

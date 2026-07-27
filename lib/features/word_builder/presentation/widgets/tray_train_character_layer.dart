import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pose of the tied-to-the-rails cartoon character.
enum TrayTrainCharacterPose { bound, escaping, safe }

/// Cartoon character lying across the rails, tied with three rope segments
/// (chest, waist, ankles). Each correct word fully snaps one segment open;
/// on level complete the character rolls off the rails
/// ([TrayTrainCharacterPose.escaping]) and celebrates beside them
/// ([TrayTrainCharacterPose.safe]). On game over the train collision flings
/// the character out of the tray ([flingProgress]).
class TrayTrainCharacterPainter extends CustomPainter {
  TrayTrainCharacterPainter({
    required this.center,
    required this.sceneRadius,
    required this.characterRadius,
    required this.brokenRopes,
    required this.totalRopes,
    required this.strugglePhase,
    required this.ropeSnapProgress,
    required this.escapeProgress,
    required this.fear,
    required this.celebrate,
    this.flingProgress = 0,
  });

  final Offset center;
  final double sceneRadius;

  /// Overall character scale (≈ face radius of the water scenario).
  final double characterRadius;

  final int brokenRopes;
  final int totalRopes;

  /// 0..1 looping wiggle while still tied.
  final double strugglePhase;

  /// 0..1 while a rope is snapping (drives the flying rope ends).
  final double ropeSnapProgress;

  /// 0..1 — rolling off the rails; 1 = standing safely beside them.
  final double escapeProgress;

  /// 0..1 — how scared the face looks (follows train tension).
  final double fear;

  /// True after escape: waving happily while the train passes.
  final bool celebrate;

  /// 0..1 — game-over collision: the character is knocked off the rails
  /// and flies out of the tray in a spinning arc (drawn without the scene
  /// clip so it visibly leaves the saucer).
  final double flingProgress;

  static const Color _skin = Color(0xFFFFCC80);
  static const Color _outfit = Color(0xFF7E57C2);
  static const Color _outfitDark = Color(0xFF5E35B1);
  static const Color _rope = Color(0xFFBCAAA4);
  static const Color _ropeDark = Color(0xFF8D6E63);

  @override
  void paint(Canvas canvas, Size size) {
    if (characterRadius <= 0) return;
    final onRailsY = center.dy + sceneRadius * 0.44;

    if (flingProgress > 0) {
      // Collision fling: parabola up and to the side, spinning, leaving
      // the tray — intentionally NOT clipped to the scene circle.
      final f = flingProgress.clamp(0.0, 1.0);
      final fx = -sceneRadius * 1.75 * Curves.easeOut.transform(f);
      final fy = -sceneRadius * 1.25 * f + sceneRadius * 2.6 * f * f;
      canvas.save();
      canvas.translate(center.dx + fx, onRailsY + fy);
      canvas.rotate(-f * math.pi * 4);
      _paintBody(canvas, 0);
      canvas.restore();
      return;
    }

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: sceneRadius)),
    );

    final escape = Curves.easeOutBack.transform(escapeProgress.clamp(0.0, 1.0));
    final sideX = center.dx + sceneRadius * 0.58 * escape;
    final baseY = onRailsY - sceneRadius * 0.06 * escape;

    canvas.translate(sideX, baseY);
    // Lying flat while bound → upright once safe.
    final lieAngle = (1 - escape) * -math.pi / 2;
    canvas.rotate(lieAngle);

    final wiggle = escapeProgress >= 1.0
        ? 0.0
        : math.sin(strugglePhase * math.pi * 2) * (1 - escape);
    canvas.rotate(wiggle * 0.05);

    _paintBody(canvas, wiggle);
    if (escapeProgress < 1.0) _paintRopes(canvas, wiggle);
    canvas.restore();
  }

  void _paintBody(Canvas canvas, double wiggle) {
    final r = characterRadius;
    final bodyPaint = Paint()..color = _outfit;
    final limbPaint = Paint()
      ..color = _outfitDark
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Legs (kick harder while struggling, relaxed once safe).
    final legKick = celebrate ? 0.0 : wiggle * r * 0.14;
    canvas.drawLine(
      Offset(-r * 0.16, r * 0.55),
      Offset(-r * 0.26 - legKick.abs() * 0.4, r * 1.05 + legKick),
      limbPaint,
    );
    canvas.drawLine(
      Offset(r * 0.16, r * 0.55),
      Offset(r * 0.26, r * 1.05 - legKick),
      limbPaint,
    );

    // Torso.
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, r * 0.18),
        width: r * 0.95,
        height: r * 1.0,
      ),
      Radius.circular(r * 0.34),
    );
    canvas.drawRRect(torso, bodyPaint);

    // Arms: pinned while bound, one raised waving when celebrating.
    final armWave = celebrate
        ? math.sin(strugglePhase * math.pi * 4) * r * 0.16
        : wiggle * r * 0.1;
    if (celebrate) {
      canvas.drawLine(
        Offset(-r * 0.42, r * 0.05),
        Offset(-r * 0.8, -r * 0.55 + armWave),
        limbPaint,
      );
      canvas.drawLine(
        Offset(r * 0.42, r * 0.05),
        Offset(r * 0.7, r * 0.42),
        limbPaint,
      );
    } else {
      canvas.drawLine(
        Offset(-r * 0.42, r * 0.0),
        Offset(-r * 0.62 - armWave, r * 0.5),
        limbPaint,
      );
      canvas.drawLine(
        Offset(r * 0.42, r * 0.0),
        Offset(r * 0.62 + armWave, r * 0.5),
        limbPaint,
      );
    }

    _paintHead(canvas, wiggle);
  }

  void _paintHead(Canvas canvas, double wiggle) {
    final r = characterRadius;
    final headCenter = Offset(wiggle * r * 0.06, -r * 0.52);
    final headR = r * 0.42;

    canvas.drawCircle(headCenter, headR, Paint()..color = _skin);
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..color = const Color(0xFFBF8F4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final eyePaint = Paint()..color = const Color(0xFF3E2723);
    final f = fear.clamp(0.0, 1.0);
    final eyeR = headR * (0.10 + 0.07 * f);
    final eyeY = headCenter.dy - headR * 0.1;
    canvas.drawCircle(Offset(headCenter.dx - headR * 0.32, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(headCenter.dx + headR * 0.32, eyeY), eyeR, eyePaint);

    // Raised fear brows.
    if (!celebrate && f > 0.25) {
      final brow = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = headR * 0.09
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final lift = headR * 0.16 * f;
      canvas.drawLine(
        Offset(headCenter.dx - headR * 0.45, eyeY - headR * 0.28 - lift),
        Offset(headCenter.dx - headR * 0.18, eyeY - headR * 0.34 - lift * 0.6),
        brow,
      );
      canvas.drawLine(
        Offset(headCenter.dx + headR * 0.18, eyeY - headR * 0.34 - lift * 0.6),
        Offset(headCenter.dx + headR * 0.45, eyeY - headR * 0.28 - lift),
        brow,
      );
    }

    final mouth = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = headR * 0.1
      ..strokeCap = StrokeCap.round;
    final mouthY = headCenter.dy + headR * 0.32;
    if (celebrate) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(headCenter.dx, mouthY),
          width: headR * 0.7,
          height: headR * 0.5,
        ),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        mouth,
      );
    } else if (f > 0.55) {
      // Open "gasp" mouth.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx, mouthY),
          width: headR * (0.24 + 0.2 * f),
          height: headR * (0.3 + 0.26 * f),
        ),
        Paint()..color = const Color(0xFF4E342E),
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(headCenter.dx, mouthY + headR * 0.08),
          width: headR * 0.5,
          height: headR * 0.34,
        ),
        1.15 * math.pi,
        0.7 * math.pi,
        false,
        mouth,
      );
    }
  }

  void _paintRopes(Canvas canvas, double wiggle) {
    final r = characterRadius;
    final ropePaint = Paint()
      ..color = _rope
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final ropeShadow = Paint()
      ..color = _ropeDark
      ..strokeWidth = r * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Three rope segments over the body: chest, waist, ankles.
    final rows = <double>[-r * 0.05, r * 0.45, r * 0.95];
    final n = math.min(totalRopes, rows.length);
    // The rope that just snapped (brokenRopes counts it already).
    final snappingIndex =
        ropeSnapProgress > 0 ? (brokenRopes - 1).clamp(0, n - 1) : -1;

    for (var i = 0; i < n; i++) {
      final y = rows[i];
      final halfW = r * (0.66 - i * 0.08);

      if (i < brokenRopes) {
        // Broken segment: fully opened and gone. Only the one snapping
        // right now shows a short fly-apart animation, then disappears.
        if (i == snappingIndex) {
          _paintSnappingRope(canvas, y, halfW, ropeSnapProgress);
        }
        continue;
      }

      // Intact rope: taut band with a struggle bulge.
      final bulge = wiggle * r * 0.07;
      final path = Path()
        ..moveTo(-halfW, y)
        ..quadraticBezierTo(0, y - r * 0.1 - bulge, halfW, y);
      canvas.drawPath(path, ropePaint);
      canvas.drawPath(path, ropeShadow);
    }
  }

  /// The two halves of a snapped rope whip outward and fade away.
  void _paintSnappingRope(
    Canvas canvas,
    double y,
    double halfW,
    double snapT,
  ) {
    final r = characterRadius;
    final t = snapT.clamp(0.0, 1.0);
    final fling = Curves.easeOut.transform(t);
    final fade = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    if (fade <= 0) return;

    final ropePaint = Paint()
      ..color = _rope.withValues(alpha: fade)
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final endDrop = r * 0.45 * fling;
    final endOut = r * 0.4 * fling;
    for (final side in const [-1.0, 1.0]) {
      final start = Offset(side * halfW * (1 - 0.25 * fling), y);
      final mid = Offset(
        side * (halfW + endOut * 0.5),
        y + endDrop * 0.4 - r * 0.12 * fling,
      );
      final end = Offset(side * (halfW + endOut), y + endDrop);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      canvas.drawPath(path, ropePaint);
    }

    // Snap sparks.
    final spark = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: fade);
    for (var i = 0; i < 4; i++) {
      final ang = i * math.pi / 2 + t * 2;
      final p = Offset(
        math.cos(ang) * r * 0.25 * t,
        y + math.sin(ang) * r * 0.25 * t,
      );
      canvas.drawCircle(p, r * 0.04 * (1 - t) + 0.5, spark);
    }
  }

  @override
  bool shouldRepaint(covariant TrayTrainCharacterPainter old) {
    return old.brokenRopes != brokenRopes ||
        old.strugglePhase != strugglePhase ||
        old.ropeSnapProgress != ropeSnapProgress ||
        old.escapeProgress != escapeProgress ||
        old.fear != fear ||
        old.celebrate != celebrate ||
        old.flingProgress != flingProgress ||
        old.center != center ||
        old.characterRadius != characterRadius;
  }
}

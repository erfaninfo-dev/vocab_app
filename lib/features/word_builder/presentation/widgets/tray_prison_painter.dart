import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared geometry anchors for the prison-escape tray scene, so the
/// environment and figure painters stay perfectly aligned.
class TrayPrisonLayout {
  TrayPrisonLayout({required this.center, required this.sceneRadius});

  final Offset center;
  final double sceneRadius;

  double get floorY => center.dy + sceneRadius * 0.56;

  /// Barred wall covers the left part of the scene (the cell).
  double get cellLeft => center.dx - sceneRadius * 0.98;
  double get cellRight => center.dx - sceneRadius * 0.02;
  double get barsTop => center.dy - sceneRadius * 0.72;

  /// Door: the rightmost framed section of the bars, hinged on its left —
  /// shifted right so the prisoner stands close to the guard.
  double get doorLeft => center.dx - sceneRadius * 0.22;
  double get doorRight => cellRight;
  double get doorTop => floorY - sceneRadius * 0.98;

  /// Prisoner pressed up against the bars, close to the guard /
  /// chest-pocket key so the reach reads clearly.
  Offset get prisonerFeet => Offset(center.dx - sceneRadius * 0.16, floorY);

  /// Guard sits right outside the door (closer for chest-key readability).
  Offset get guardSeat =>
      Offset(center.dx + sceneRadius * 0.27, floorY - sceneRadius * 0.12);
  Offset get lampAnchor =>
      Offset(center.dx + sceneRadius * 0.10, center.dy - sceneRadius * 0.98);
}

/// Environment of the prison-escape scene: stone wall, moonlit window,
/// floor, swinging hanging lamp with a warm light cone, dust motes and a
/// soft rim. Figures (prisoner, bars, guard, key) live in
/// `TrayPrisonFiguresPainter` so the arm can thread between the bars.
class TrayPrisonPainter extends CustomPainter {
  TrayPrisonPainter({
    required this.size,
    required this.center,
    required this.sceneRadius,
    required this.saucerRadius,
    required this.ambientPhase,
    required this.tension,
    required this.isGameOver,
  }) : _layout = TrayPrisonLayout(center: center, sceneRadius: sceneRadius);

  final Size size;
  final Offset center;
  final double sceneRadius;
  final double saucerRadius;

  /// Looping 0..1 phase driving the lamp swing, key swing and dust drift.
  final double ambientPhase;

  /// 0..1 danger level (how close the guard is to waking up).
  final double tension;
  final bool isGameOver;

  final TrayPrisonLayout _layout;

  static const _wallTop = Color(0xFF37474F);
  static const _wallBottom = Color(0xFF263238);
  static const _floorColor = Color(0xFF1C262B);
  static const _lampGlow = Color(0xFFFFE082);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: sceneRadius)),
    );

    _paintWall(canvas);
    _paintWindow(canvas);
    _paintFloor(canvas);
    _paintLamp(canvas);
    _paintDust(canvas);
    _paintTensionVignette(canvas);

    canvas.restore();
    _paintRim(canvas);
  }

  void _paintWall(Canvas canvas) {
    final rect = Rect.fromCircle(center: center, radius: sceneRadius);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_wallTop, _wallBottom],
        ).createShader(rect),
    );

    // Soft stone blocks.
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = math.max(1, sceneRadius * 0.014)
      ..style = PaintingStyle.stroke;
    final blockH = sceneRadius * 0.24;
    final blockW = sceneRadius * 0.38;
    var row = 0;
    for (var y = rect.top + blockH; y < _layout.floorY; y += blockH) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
      final offset = row.isEven ? 0.0 : blockW / 2;
      for (var x = rect.left + offset; x < rect.right; x += blockW) {
        canvas.drawLine(Offset(x, y - blockH), Offset(x, y), line);
      }
      row++;
    }
  }

  void _paintWindow(Canvas canvas) {
    final c = Offset(
      center.dx + sceneRadius * 0.52,
      center.dy - sceneRadius * 0.52,
    );
    final r = sceneRadius * 0.17;
    final rect = Rect.fromCenter(center: c, width: r * 2, height: r * 1.6);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.5));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF90CAF9).withValues(alpha: 0.55),
            const Color(0xFF1A237E).withValues(alpha: 0.85),
          ],
        ).createShader(rect),
    );
    // Tiny moon.
    canvas.drawCircle(
      Offset(c.dx + r * 0.3, c.dy - r * 0.2),
      r * 0.22,
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.9),
    );
    final bar = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = math.max(1.4, r * 0.14)
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final x = c.dx + i * r * 0.55;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), bar);
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..strokeWidth = math.max(1.6, r * 0.16)
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintFloor(Canvas canvas) {
    final rect = Rect.fromLTRB(
      center.dx - sceneRadius,
      _layout.floorY,
      center.dx + sceneRadius,
      center.dy + sceneRadius,
    );
    canvas.drawRect(rect, Paint()..color = _floorColor);
    canvas.drawLine(
      Offset(rect.left, _layout.floorY),
      Offset(rect.right, _layout.floorY),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = math.max(1.2, sceneRadius * 0.02),
    );
    // Faint plank seams.
    final seam = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = _layout.floorY + (rect.height / 4) * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), seam);
    }
  }

  double get _lampSwing => math.sin(ambientPhase * 2 * math.pi) * 0.075;

  void _paintLamp(Canvas canvas) {
    final anchor = _layout.lampAnchor;
    final cordLen = sceneRadius * 0.34;
    final angle = _lampSwing;
    final lampPos = Offset(
      anchor.dx + math.sin(angle) * cordLen,
      anchor.dy + math.cos(angle) * cordLen,
    );

    // Light cone (follows the swing).
    final coneHalf = sceneRadius * 0.62;
    final coneBottom = _layout.floorY + sceneRadius * 0.1;
    final flicker =
        0.16 + 0.03 * math.sin(ambientPhase * 2 * math.pi * 3) + tension * 0.04;
    final cone = Path()
      ..moveTo(lampPos.dx, lampPos.dy)
      ..lineTo(lampPos.dx - coneHalf + math.sin(angle) * 30, coneBottom)
      ..lineTo(lampPos.dx + coneHalf + math.sin(angle) * 30, coneBottom)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lampGlow.withValues(alpha: flicker),
            _lampGlow.withValues(alpha: 0.0),
          ],
        ).createShader(cone.getBounds()),
    );

    // Cord + shade + bulb.
    canvas.drawLine(
      anchor,
      lampPos,
      Paint()
        ..color = const Color(0xFF37474F)
        ..strokeWidth = math.max(1.4, sceneRadius * 0.02),
    );
    final shadeW = sceneRadius * 0.15;
    final shade = Path()
      ..moveTo(lampPos.dx - shadeW, lampPos.dy)
      ..lineTo(lampPos.dx + shadeW, lampPos.dy)
      ..lineTo(lampPos.dx + shadeW * 0.4, lampPos.dy - shadeW * 0.75)
      ..lineTo(lampPos.dx - shadeW * 0.4, lampPos.dy - shadeW * 0.75)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFF4E5D65));
    canvas.drawCircle(
      Offset(lampPos.dx, lampPos.dy + shadeW * 0.22),
      shadeW * 0.3,
      Paint()
        ..color = _lampGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintDust(Canvas canvas) {
    final rng = math.Random(23);
    final paint = Paint();
    for (var i = 0; i < 14; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final drift = (ambientPhase + seedY) % 1.0;
      final x = center.dx +
          (seedX - 0.42) * sceneRadius * 1.2 +
          math.sin((ambientPhase + seedX) * 2 * math.pi) * sceneRadius * 0.03;
      final y = center.dy - sceneRadius * 0.6 + drift * sceneRadius * 1.1;
      if (y > _layout.floorY) continue;
      final alpha = 0.10 + 0.10 * math.sin(drift * math.pi);
      paint.color = _lampGlow.withValues(alpha: alpha.clamp(0.0, 0.2));
      canvas.drawCircle(
        Offset(x, y),
        sceneRadius * (0.008 + seedX * 0.008),
        paint,
      );
    }
  }

  void _paintTensionVignette(Canvas canvas) {
    if (tension <= 0.05 && !isGameOver) return;
    final rect = Rect.fromCircle(center: center, radius: sceneRadius);
    final strength = isGameOver ? 0.4 : tension * 0.28;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF4A148C).withValues(alpha: strength * 0.5),
            const Color(0xFF1A0033).withValues(alpha: strength),
          ],
          stops: const [0.45, 0.8, 1.0],
        ).createShader(rect),
    );
  }

  void _paintRim(Canvas canvas) {
    canvas.drawCircle(
      center,
      sceneRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = math.max(2, sceneRadius * 0.035)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      sceneRadius - math.max(2, sceneRadius * 0.035),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(TrayPrisonPainter oldDelegate) =>
      oldDelegate.ambientPhase != ambientPhase ||
      oldDelegate.tension != tension ||
      oldDelegate.isGameOver != isGameOver ||
      oldDelegate.sceneRadius != sceneRadius ||
      oldDelegate.center != center;
}

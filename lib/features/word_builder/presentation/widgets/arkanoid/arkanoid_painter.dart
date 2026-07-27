import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'arkanoid_physics.dart';

class ArkanoidBoardPainter extends CustomPainter {
  ArkanoidBoardPainter({
    required this.world,
    required this.selectedIds,
    required this.wrongFlash,
    required this.successFlash,
    this.prefixFlash = 0,
    this.lastHitLetterId,
    required this.trail,
    required this.sparkLife,
    required this.isDark,
    required this.scheme,
  });

  final ArkanoidPhysicsWorld world;
  final Set<int> selectedIds;
  final double wrongFlash;
  final double successFlash;
  final double prefixFlash;
  final int? lastHitLetterId;
  final List<Offset> trail;
  final double sparkLife;
  final bool isDark;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF152238), Color(0xFF0A1020)]
              : const [Color(0xFFE8F4FF), Color(0xFFD6E9FF)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
          ],
          stops: const [0.5, 1],
        ).createShader(Offset.zero & size),
    );

    if (wrongFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = const Color(0xFFFF5252).withValues(alpha: 0.2 * wrongFlash),
      );
    }
    if (successFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color =
              const Color(0xFF69F0AE).withValues(alpha: 0.22 * successFlash),
      );
    }
    if (prefixFlash > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color =
              const Color(0xFFFFD54F).withValues(alpha: 0.12 * prefixFlash),
      );
    }

    _paintBricks(canvas);
    _paintAimPreview(canvas);
    _paintPaddle(canvas);
    _paintTrail(canvas);
    _paintBall(canvas);
    if (sparkLife > 0 && world.sparkAt != null) {
      _paintSpark(canvas, world.sparkAt!, sparkLife);
    }

    if (successFlash > 0.15) {
      final tp = TextPainter(
        text: TextSpan(
          text: '✓',
          style: TextStyle(
            color: const Color(0xFF00C853).withValues(alpha: successFlash),
            fontSize: 42 + (1 - successFlash) * 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(size.width / 2 - tp.width / 2, size.height * 0.38 - tp.height / 2),
      );
    }

    if (world.serving) {
      final tp = TextPainter(
        text: TextSpan(
          text: '▲',
          style: TextStyle(
            color: scheme.primary.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(world.ball.dx - tp.width / 2, world.ball.dy - 36),
      );
    }

    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: isDark ? 0.55 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  void _paintAimPreview(Canvas canvas) {
    final preview = world.aimPreview();
    if (preview == null) return;

    final hitColor = preview.willHitPaddle
        ? const Color(0xFF69F0AE)
        : const Color(0xFFFF8A80);

    // Thin dashed approach toward predicted contact.
    if (preview.approach.length >= 2) {
      final path = Path()..moveTo(preview.approach.first.dx, preview.approach.first.dy);
      for (var i = 1; i < preview.approach.length; i++) {
        path.lineTo(preview.approach[i].dx, preview.approach[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = hitColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Contact tick on paddle line.
    canvas.drawCircle(
      preview.hit,
      4.5,
      Paint()..color = hitColor.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      preview.hit,
      4.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final dir = preview.reboundDir;
    if (dir == null || !preview.willHitPaddle) return;

    // Short rebound guide ray (prediction of bounce angle).
    final len = 88.0;
    final end = preview.hit + dir * len;
    final reboundPath = Path()
      ..moveTo(preview.hit.dx, preview.hit.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      reboundPath,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );

    // Dashed overlay for readability.
    _drawDashedLine(
      canvas,
      preview.hit,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Arrow tip.
    final tipAngle = math.atan2(dir.dy, dir.dx);
    final tip = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - 9 * math.cos(tipAngle - 0.45),
        end.dy - 9 * math.sin(tipAngle - 0.45),
      )
      ..lineTo(
        end.dx - 9 * math.cos(tipAngle + 0.45),
        end.dy - 9 * math.sin(tipAngle + 0.45),
      )
      ..close();
    canvas.drawPath(tip, Paint()..color = const Color(0xFFFFB300));
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total < 1) return;
    final dir = (b - a) / total;
    const dash = 6.0;
    const gap = 4.0;
    var d = 0.0;
    while (d < total) {
      final d2 = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * d2, paint);
      d += dash + gap;
    }
  }

  void _paintBricks(Canvas canvas) {
    for (final b in world.bricks) {
      if (b.removed) continue;
      final selected = selectedIds.contains(b.letter.id);
      final rect = b.rect;
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.22));

      // Soft drop shadow.
      canvas.drawRRect(
        rr.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );

      // Glass body.
      final tint = selected
          ? const Color(0xFF78909C)
          : Color.lerp(
              const Color(0xFF80D8FF),
              const Color(0xFFEA80FC),
              (b.letter.id % 7) / 7,
            )!;
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: selected ? 0.35 : 0.55),
              tint.withValues(alpha: selected ? 0.35 : 0.55),
              tint.withValues(alpha: selected ? 0.22 : 0.4),
            ],
          ).createShader(rect),
      );

      // Outer glow ring.
      canvas.drawRRect(
        rr,
        Paint()
          ..color = (selected ? Colors.white : tint).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Specular glass highlight.
      final hi = Rect.fromLTWH(
        rect.left + rect.width * 0.12,
        rect.top + rect.height * 0.1,
        rect.width * 0.55,
        rect.height * 0.28,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(hi, Radius.circular(rect.width * 0.12)),
        Paint()..color = Colors.white.withValues(alpha: selected ? 0.2 : 0.45),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: b.letter.char.toUpperCase(),
          style: TextStyle(
            color: selected
                ? Colors.white.withValues(alpha: 0.4)
                : (isDark ? Colors.white : const Color(0xFF1A237E)),
            fontSize: math.min(rect.height * 0.48, 22),
            fontWeight: FontWeight.w800,
            shadows: selected
                ? null
                : [
                    Shadow(
                      color: tint.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      tp.paint(
        canvas,
        Offset(
          rect.center.dx - tp.width / 2,
          rect.center.dy - tp.height / 2,
        ),
      );
    }
  }

  void _paintPaddle(Canvas canvas) {
    final p = world.paddleRect;
    final rr = RRect.fromRectAndRadius(p, const Radius.circular(12));
    canvas.drawRRect(
      rr.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFFF6F00)],
        ).createShader(p),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Glow scales with paddle size.
    canvas.drawRRect(
      rr.inflate(3),
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _paintTrail(Canvas canvas) {
    for (var i = 0; i < trail.length; i++) {
      final t = (i + 1) / (trail.length + 1);
      canvas.drawCircle(
        trail[i],
        ArkanoidPhysicsWorld.ballRadius * (0.35 + t * 0.35),
        Paint()..color = const Color(0xFFFFECB3).withValues(alpha: 0.25 * t),
      );
    }
  }

  void _paintBall(Canvas canvas) {
    final c = world.ball;
    canvas.drawCircle(
      c + const Offset(1.5, 2),
      ArkanoidPhysicsWorld.ballRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    canvas.drawCircle(
      c,
      ArkanoidPhysicsWorld.ballRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          c + const Offset(-3, -3),
          ArkanoidPhysicsWorld.ballRadius,
          const [Color(0xFFFFF8E1), Color(0xFFFFB300), Color(0xFFF57C00)],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  void _paintSpark(Canvas canvas, Offset at, double life) {
    final paint = Paint()
      ..color = const Color(0xFFFFECB3).withValues(alpha: life)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi * 2 / 6;
      final len = 6 + (1 - life) * 10;
      canvas.drawLine(
        at,
        Offset(at.dx + math.cos(a) * len, at.dy + math.sin(a) * len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArkanoidBoardPainter oldDelegate) => true;
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'angry_words_celebrate.dart';

/// Full-screen overlay that paints letters / chicks flying into answer slots.
class AngryWordsFlightOverlay extends StatelessWidget {
  const AngryWordsFlightOverlay({super.key, required this.flights});

  final List<AngryWordsFlightLetter> flights;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FlightPainter(flights: flights),
        size: Size.infinite,
      ),
    );
  }
}

class _FlightPainter extends CustomPainter {
  _FlightPainter({required this.flights});

  final List<AngryWordsFlightLetter> flights;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flights) {
      if (f.delay > 0) continue;
      final c = f.position;
      final r = 16.0 * f.scale;
      final glow = f.settled
          ? const Color(0xFF69F0AE)
          : f.asChick
              ? const Color(0xFFFFF176)
              : const Color(0xFFFFD54F);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(f.rotation);

      canvas.drawCircle(
        Offset.zero,
        r + 8,
        Paint()
          ..color = glow.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      if (f.asChick) {
        _paintChick(canvas, f, r);
      } else {
        _paintLetterOrb(canvas, f, r);
      }

      canvas.restore();
    }
  }

  void _paintLetterOrb(Canvas canvas, AngryWordsFlightLetter f, double r) {
    canvas.drawCircle(
      const Offset(0, 2),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.28, -r * 0.3),
          r * 1.15,
          [
            Colors.white.withValues(alpha: 0.95),
            Color.lerp(f.tint, Colors.white, 0.2)!,
            f.tint,
          ],
          const [0.0, 0.45, 1.0],
        ),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: f.char.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF4E342E),
          fontSize: math.min(r * 0.95, 22),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  void _paintChick(Canvas canvas, AngryWordsFlightLetter f, double r) {
    // Soft egg-shell halo / motion blur trail.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 3),
        width: r * 1.75,
        height: r * 1.25,
      ),
      Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.4),
    );

    final flap = f.wingFlap;
    _paintWing(canvas, r, left: true, flap: flap);
    _paintWing(canvas, r, left: false, flap: flap);

    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 1),
        width: r * 1.35,
        height: r * 1.2,
      ),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.2, -r * 0.25),
          r,
          const [
            Color(0xFFFFF59D),
            Color(0xFFFFEB3B),
            Color(0xFFFFC107),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Belly patch
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.28),
        width: r * 0.72,
        height: r * 0.48,
      ),
      Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.9),
    );

    // Beak
    final beak = Path()
      ..moveTo(r * 0.42, -r * 0.02)
      ..lineTo(r * 0.78, r * 0.06)
      ..lineTo(r * 0.42, r * 0.16)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF9800));

    // Eye
    canvas.drawCircle(
      Offset(r * 0.18, -r * 0.18),
      r * 0.11,
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawCircle(
      Offset(r * 0.21, -r * 0.21),
      r * 0.04,
      Paint()..color = Colors.white,
    );

    // Tuft
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -r * 0.55),
        width: r * 0.55,
        height: r * 0.4,
      ),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = const Color(0xFFFFCA28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round,
    );

    // Letter badge under the chick — written into the path/slot on arrival.
    final badgeR = r * 0.42;
    canvas.drawCircle(
      Offset(0, r * 0.78),
      badgeR,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      Offset(0, r * 0.78),
      badgeR,
      Paint()
        ..color = f.tint.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: f.char.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF4E342E),
          fontSize: math.min(badgeR * 1.35, 14),
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(-tp.width / 2, r * 0.78 - tp.height / 2),
    );
  }

  void _paintWing(
    Canvas canvas,
    double r, {
    required bool left,
    required double flap,
  }) {
    canvas.save();
    final root = Offset(left ? -r * 0.28 : r * 0.28, r * 0.02);
    canvas.translate(root.dx, root.dy);
    // Opposite phase on left/right + open upward when flap > 0.
    final angle = left ? -flap - 0.35 : flap + 0.35;
    canvas.rotate(angle);

    final wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        left ? -r * 0.95 : r * 0.95,
        -r * 0.15,
        left ? -r * 1.05 : r * 1.05,
        r * 0.35,
      )
      ..quadraticBezierTo(
        left ? -r * 0.45 : r * 0.45,
        r * 0.55,
        0,
        r * 0.12,
      )
      ..close();

    canvas.drawPath(
      wing,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(left ? -r : r, r * 0.4),
          const [
            Color(0xFFFFF176),
            Color(0xFFFFB300),
          ],
        ),
    );
    canvas.drawPath(
      wing,
      Paint()
        ..color = const Color(0xFFF57F17).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlightPainter oldDelegate) => true;
}

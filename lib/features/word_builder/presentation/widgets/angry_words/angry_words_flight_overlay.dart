import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'angry_words_celebrate.dart';

/// Full-screen overlay that paints letters flying into answer slots.
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
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlightPainter oldDelegate) => true;
}

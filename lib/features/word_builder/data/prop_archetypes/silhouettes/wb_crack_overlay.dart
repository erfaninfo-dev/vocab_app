import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Crack / dent / erode overlays — separate from silhouette fill.
///
/// Paths are in unit space `[0,1]²`. Transform with the same translate+scale
/// as the body. Stroke width is chosen in **screen px** by the painter
/// (minimum 1.5px) so cracks stay readable on small props.
abstract final class WbCrackOverlay {
  /// Single diagonal crack (crackStages == 1).
  static Path simpleCrack({Offset hit = const Offset(0.45, 0.35)}) {
    return Path()
      ..moveTo(hit.dx - 0.12, hit.dy - 0.08)
      ..lineTo(hit.dx + 0.05, hit.dy + 0.02)
      ..lineTo(hit.dx + 0.18, hit.dy + 0.22);
  }

  /// Two branches; [secondHit] drives the second fork (crackStages == 2).
  static Path dualCrack({
    Offset firstHit = const Offset(0.42, 0.32),
    Offset secondHit = const Offset(0.58, 0.55),
  }) {
    final p = simpleCrack(hit: firstHit);
    p
      ..moveTo(secondHit.dx, secondHit.dy)
      ..lineTo(secondHit.dx + 0.16, secondHit.dy - 0.10)
      ..moveTo(secondHit.dx, secondHit.dy)
      ..lineTo(secondHit.dx + 0.10, secondHit.dy + 0.18);
    return p;
  }

  /// Growing network: one branch per hit (crackCascade).
  static Path cascade(List<Offset> hits) {
    final p = Path();
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      final ang = i * 0.9;
      p.moveTo(h.dx, h.dy);
      p.lineTo(h.dx + math.cos(ang) * 0.22, h.dy + math.sin(ang) * 0.22);
      p.moveTo(h.dx, h.dy);
      p.lineTo(
        h.dx + math.cos(ang + 0.8) * 0.14,
        h.dy + math.sin(ang + 0.8) * 0.14,
      );
    }
    return p;
  }

  /// Radial spiderweb from [center]: 6–8 spokes + 2 rings.
  static Path spiderweb({
    Offset center = const Offset(0.5, 0.5),
    int spokes = 7,
  }) {
    final n = spokes.clamp(6, 8);
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a = (i / n) * math.pi * 2;
      p.moveTo(center.dx, center.dy);
      p.lineTo(center.dx + math.cos(a) * 0.42, center.dy + math.sin(a) * 0.42);
    }
    for (final r in [0.18, 0.32]) {
      p.addOval(Rect.fromCircle(center: center, radius: r));
    }
    return p;
  }

  /// Body minus circular pits (erode). Returns clip path in unit space.
  static Path erodeClip(Path body, List<Offset> pits, {double pitRadius = 0.12}) {
    final cut = Path.from(body);
    for (final pit in pits) {
      cut.fillType = PathFillType.evenOdd;
      cut.addOval(Rect.fromCircle(center: pit, radius: pitRadius));
    }
    return cut;
  }

  /// Soft multiply dents at hit points (dentThenRupture).
  static void paintDents(
    Canvas canvas,
    List<Offset> dents,
    Rect dest, {
    double radiusFrac = 0.14,
  }) {
    if (dents.isEmpty) return;
    final paint = Paint()
      ..blendMode = BlendMode.multiply
      ..style = PaintingStyle.fill;
    for (final d in dents) {
      final c = Offset(
        dest.left + d.dx * dest.width,
        dest.top + d.dy * dest.height,
      );
      final r = radiusFrac * math.min(dest.width, dest.height);
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF000000).withValues(alpha: 0.45),
          const Color(0xFF000000).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }
  }

  /// High-contrast crack stroke — call after transforming or pass screen width.
  static Paint crackStrokePaint(Color bodyColor, {double strokeWidthPx = 2.0}) {
    final luminance = bodyColor.computeLuminance();
    final crack = luminance > 0.45
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF5F5F5);
    return Paint()
      ..color = crack.withValues(alpha: 0.96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, strokeWidthPx)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }
}

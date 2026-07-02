import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/glass_crack_path_generator.dart';

class TrayGlassPainter extends CustomPainter {
  TrayGlassPainter({
    required this.center,
    required this.radius,
    required this.scheme,
    required this.isDark,
    required this.crackSegments,
    required this.crackGrowProgress,
    required this.healProgress,
    required this.healingIndex,
    required this.shimmerPhase,
    required this.stressLevel,
  });

  final Offset center;
  final double radius;
  final ColorScheme scheme;
  final bool isDark;
  final List<GlassCrackSegment> crackSegments;
  final double crackGrowProgress;
  final double healProgress;
  final int healingIndex;
  final double shimmerPhase;
  final double stressLevel;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;

    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));

    _drawGlassBody(canvas, bounds);
    _drawHighlights(canvas, bounds);
    _drawCracks(canvas);
    _drawRim(canvas, bounds);

    canvas.restore();
  }

  void _drawGlassBody(Canvas canvas, Rect bounds) {
    final base = isDark
        ? [
            const Color(0xFF90CAF9).withValues(alpha: 0.14),
            const Color(0xFF42A5F5).withValues(alpha: 0.08),
            const Color(0xFF1565C0).withValues(alpha: 0.18),
          ]
        : [
            Colors.white.withValues(alpha: 0.55),
            const Color(0xFFE3F2FD).withValues(alpha: 0.35),
            const Color(0xFFBBDEFB).withValues(alpha: 0.22),
          ];

    canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: base,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    final innerGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
          Colors.transparent,
        ],
      ).createShader(bounds.deflate(radius * 0.15));
    canvas.drawOval(bounds.deflate(radius * 0.08), innerGlow);
  }

  void _drawHighlights(Canvas canvas, Rect bounds) {
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.045
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.35 : 0.75),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(bounds);

    final highlightRect = bounds.deflate(radius * 0.12);
    canvas.drawArc(
      highlightRect,
      -math.pi * 0.82,
      math.pi * 0.55,
      false,
      arcPaint,
    );

    final shimmer = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + shimmerPhase * 2, -0.8),
        end: Alignment(-0.2 + shimmerPhase * 2, 0.8),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
          Colors.transparent,
        ],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(bounds);
    canvas.drawOval(bounds.deflate(radius * 0.05), shimmer);
  }

  void _drawCracks(Canvas canvas) {
    if (crackSegments.isEmpty) return;

    for (var i = 0; i < crackSegments.length; i++) {
      final segment = crackSegments[i];
      var progress = 1.0;
      if (i == crackSegments.length - 1 && crackGrowProgress < 1) {
        progress = crackGrowProgress;
      }
      if (i == healingIndex && healProgress > 0) {
        progress = (1 - healProgress).clamp(0.0, 1.0);
      }

      for (final branch in segment.branches) {
        final path = GlassCrackPathGenerator.branchPath(
          branch,
          progress: progress,
        );
        if (path.getBounds().isEmpty) continue;

        final w = branch.width * (1.1 + stressLevel * 0.35);
        final shadow = Paint()
          ..color = (isDark ? Colors.black : const Color(0xFF263238))
              .withValues(alpha: 0.35 * progress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 1.35
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        canvas.drawPath(path, shadow);

        final core = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.05),
              (isDark ? const Color(0xFFCFD8DC) : const Color(0xFF37474F))
                  .withValues(alpha: 0.85 * progress),
              Colors.white.withValues(alpha: 0.15 * progress),
            ],
          ).createShader(path.getBounds())
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, core);
      }
    }
  }

  void _drawRim(Canvas canvas, Rect bounds) {
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.45 : 0.85),
          scheme.primary.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: isDark ? 0.25 : 0.55),
          scheme.outline.withValues(alpha: 0.35),
        ],
      ).createShader(bounds);
    canvas.drawOval(bounds, rim);
  }

  @override
  bool shouldRepaint(covariant TrayGlassPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.crackSegments != crackSegments ||
        oldDelegate.crackGrowProgress != crackGrowProgress ||
        oldDelegate.healProgress != healProgress ||
        oldDelegate.healingIndex != healingIndex ||
        oldDelegate.shimmerPhase != shimmerPhase ||
        oldDelegate.stressLevel != stressLevel ||
        oldDelegate.scheme.brightness != scheme.brightness;
  }
}

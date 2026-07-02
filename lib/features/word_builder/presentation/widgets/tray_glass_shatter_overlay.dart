import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tray_glass_constants.dart';

class TrayGlassShatterParticle {
  TrayGlassShatterParticle({
    required this.origin,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.opacity,
  });

  final Offset origin;
  final Offset velocity;
  final double size;
  final double rotation;
  final double spin;
  final double opacity;
}

class TrayGlassShatterOverlay extends StatelessWidget {
  const TrayGlassShatterOverlay({
    super.key,
    required this.center,
    required this.radius,
    required this.progress,
    required this.particles,
    required this.isDark,
  });

  final Offset center;
  final double radius;
  final double progress;
  final List<TrayGlassShatterParticle> particles;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShatterPainter(
        center: center,
        radius: radius,
        progress: progress,
        particles: particles,
        isDark: isDark,
      ),
    );
  }
}

class _ShatterPainter extends CustomPainter {
  _ShatterPainter({
    required this.center,
    required this.radius,
    required this.progress,
    required this.particles,
    required this.isDark,
  });

  final Offset center;
  final double radius;
  final double progress;
  final List<TrayGlassShatterParticle> particles;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final gravity = 520.0;

    for (final p in particles) {
      final pos =
          p.origin +
          Offset(p.velocity.dx * t, p.velocity.dy * t + 0.5 * gravity * t * t);
      final rot = p.rotation + p.spin * t;
      final alpha = (p.opacity * (1 - t * 0.85)).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      final shard = Path()
        ..moveTo(-p.size * 0.5, -p.size * 0.35)
        ..lineTo(p.size * 0.45, -p.size * 0.15)
        ..lineTo(p.size * 0.25, p.size * 0.42)
        ..lineTo(-p.size * 0.35, p.size * 0.28)
        ..close();

      canvas.drawPath(
        shard,
        Paint()
          ..color = (isDark ? const Color(0xFFB3E5FC) : Colors.white)
              .withValues(alpha: 0.55 * alpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        shard,
        Paint()
          ..color = const Color(0xFF546E7A).withValues(alpha: 0.35 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }

    final flash = Paint()
      ..color = Colors.white.withValues(alpha: (1 - t) * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * (0.4 + t * 0.8), flash);
  }

  @override
  bool shouldRepaint(covariant _ShatterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles ||
        oldDelegate.isDark != isDark;
  }
}

List<TrayGlassShatterParticle> buildTrayGlassShatterParticles({
  required Offset center,
  required double radius,
  required int seed,
  int count = TrayGlassConstants.maxShatterParticles,
}) {
  final random = math.Random(seed);
  final capped = count.clamp(8, TrayGlassConstants.maxShatterParticles);
  return List.generate(capped, (_) {
    final angle = random.nextDouble() * math.pi * 2;
    final dist = radius * (0.05 + random.nextDouble() * 0.55);
    final origin = center + Offset(math.cos(angle), math.sin(angle)) * dist;
    final speed = 120 + random.nextDouble() * 280;
    return TrayGlassShatterParticle(
      origin: origin,
      velocity: Offset(
        math.cos(angle) * speed + (random.nextDouble() - 0.5) * 80,
        math.sin(angle) * speed - 40 - random.nextDouble() * 120,
      ),
      size: 6 + random.nextDouble() * 14,
      rotation: random.nextDouble() * math.pi,
      spin: (random.nextDouble() - 0.5) * 8,
      opacity: 0.55 + random.nextDouble() * 0.45,
    );
  });
}

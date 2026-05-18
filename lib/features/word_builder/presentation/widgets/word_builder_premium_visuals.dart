import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shared AAA casual palette and paint helpers for Word Builder session UI.
abstract final class WordBuilderPremiumColors {
  static const bgTop = Color(0xFFFFD54F);
  static const bgMid = Color(0xFFFF8A65);
  static const bgBottom = Color(0xFFFF6B9D);

  static const goldHi = Color(0xFFFFF8E1);
  static const goldMid = Color(0xFFFFD54F);
  static const goldDeep = Color(0xFFFF8F00);
  static const goldRim = Color(0xFFE65100);
  static const goldDark = Color(0xFFBF360C);

  static const slotGreenHi = Color(0xFF81C784);
  static const slotGreenMid = Color(0xFF43A047);
  static const slotGreenLo = Color(0xFF2E7D32);
  static const slotGreenBorder = Color(0xFF1B5E20);

  static const creamHi = Color(0xFFFFFDE7);
  static const creamMid = Color(0xFFFFECB3);
  static const creamLo = Color(0xFFFFE082);

  static const chromeHi = Color(0xFFF5F5F5);
  static const chromeMid = Color(0xFFB0BEC5);
  static const chromeLo = Color(0xFF546E7A);
}

/// Cinematic session backdrop: gradient, center bloom, bokeh, particles, vignette.
class PremiumSessionBackdropPainter extends CustomPainter {
  PremiumSessionBackdropPainter({
    required this.progress,
    required this.isDark,
    this.wheelCenter = const Alignment(0, 0.72),
  });

  final double progress;
  final bool isDark;
  final Alignment wheelCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF5D4037), Color(0xFF6D4C41), Color(0xFF8B5A6B)]
              : const [
                  WordBuilderPremiumColors.bgTop,
                  WordBuilderPremiumColors.bgMid,
                  WordBuilderPremiumColors.bgBottom,
                ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    final cx = rect.width * (wheelCenter.x + 1) / 2;
    final cy = rect.height * (wheelCenter.y + 1) / 2;
    final bloomR = size.shortestSide * 0.55;

    canvas.drawCircle(
      Offset(cx, cy),
      bloomR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFB300).withValues(alpha: isDark ? 0.22 : 0.42),
            const Color(0xFFFF7043).withValues(alpha: isDark ? 0.12 : 0.22),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: bloomR)),
    );

    final phase = progress * math.pi * 2;
    for (var i = 0; i < 14; i++) {
      final t = i / 14;
      final bx = size.width * ((t * 0.87 + progress * 0.11) % 1.0);
      final by = size.height * (((t * 0.53) + progress * 0.07) % 1.0);
      final br = 18.0 + (i % 5) * 14.0;
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..color = Colors.white.withValues(alpha: isDark ? 0.06 : 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }

    for (var i = 0; i < 48; i++) {
      final dx = size.width * ((i * 0.17 + progress * 0.35) % 1.0);
      final dy = size.height * (((i * 0.41) + progress * 0.22) % 1.0);
      final pulse = 0.55 + 0.45 * math.sin(phase + i * 0.7);
      canvas.drawCircle(
        Offset(dx, dy),
        (2.2 + (i % 4)) * pulse,
        Paint()
          ..color = Colors.white.withValues(alpha: isDark ? 0.1 : 0.32 * pulse),
      );
    }

    final streakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.2 + progress * 2.4, -0.8),
        end: Alignment(0.4 + progress * 0.6, 1.2),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.04 : 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, streakPaint);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant PremiumSessionBackdropPainter old) {
    return old.progress != progress ||
        old.isDark != isDark ||
        old.wheelCenter != wheelCenter;
  }
}

/// Gloss streak on top of circular widgets (letter tiles, buttons).
class PremiumShineSweepPainter extends CustomPainter {
  PremiumShineSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final sweep = Rect.fromCircle(center: c, radius: r * 0.92);
    final angle = progress * math.pi * 2;

    canvas.save();
    canvas.clipPath(Path()..addOval(sweep));
    final highlight = Path()
      ..moveTo(c.dx - r * 0.5, c.dy - r * 0.55)
      ..quadraticBezierTo(
        c.dx + math.cos(angle) * r * 0.15,
        c.dy - r * 0.65 + math.sin(angle) * r * 0.08,
        c.dx + r * 0.55,
        c.dy - r * 0.35,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(sweep)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-r * 0.22, -r * 0.28),
        width: r * 0.55,
        height: r * 0.22,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx - r * 0.4, c.dy - r * 0.4),
          Offset(c.dx, c.dy - r * 0.1),
          [
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiumShineSweepPainter old) =>
      old.progress != progress;
}

BoxDecoration premiumGoldCircleDecoration({
  required bool isDark,
  double borderWidth = 2.8,
  List<BoxShadow>? extraShadows,
}) {
  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: const RadialGradient(
      center: Alignment(-0.35, -0.45),
      radius: 1.1,
      colors: [
        WordBuilderPremiumColors.goldHi,
        WordBuilderPremiumColors.goldMid,
        WordBuilderPremiumColors.goldDeep,
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    border: Border.all(
      color: WordBuilderPremiumColors.goldRim.withValues(
        alpha: isDark ? 0.75 : 0.9,
      ),
      width: borderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: WordBuilderPremiumColors.goldDeep.withValues(
          alpha: isDark ? 0.55 : 0.42,
        ),
        blurRadius: 16,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.35 : 0.5),
        blurRadius: 22,
        spreadRadius: 1,
      ),
      ...?extraShadows,
    ],
  );
}

BoxDecoration premiumAnswerBarDecoration({required bool wrong}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: wrong
          ? const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)]
          : const [
              WordBuilderPremiumColors.creamHi,
              WordBuilderPremiumColors.creamMid,
              WordBuilderPremiumColors.creamLo,
            ],
    ),
    border: Border.all(
      color: wrong
          ? const Color(0xFFD32F2F)
          : WordBuilderPremiumColors.goldRim.withValues(alpha: 0.85),
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: (wrong ? Colors.red : const Color(0xFFFF9800))
            .withValues(alpha: 0.45),
        blurRadius: 20,
        spreadRadius: 1,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

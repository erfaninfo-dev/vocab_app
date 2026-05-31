import 'package:flutter/material.dart';

class SampleReadingLampButton extends StatelessWidget {
  const SampleReadingLampButton({
    super.key,
    required this.tooltip,
    required this.onTap,
  });

  final String tooltip;
  final VoidCallback onTap;

  static const _shade = Color(0xFFC9A86C);
  static const _base = Color(0xFF8B6914);
  static const _glow = Color(0xFFFFE8B0);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF5EDD8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: CustomPaint(
              size: Size(26, 26),
              painter: _ReadingLampPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingLampPainter extends CustomPainter {
  const _ReadingLampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shade = Path()
      ..moveTo(w * 0.15, h * 0.02)
      ..lineTo(w * 0.85, h * 0.02)
      ..lineTo(w * 0.72, h * 0.42)
      ..lineTo(w * 0.28, h * 0.42)
      ..close();
    canvas.drawPath(shade, Paint()..color = SampleReadingLampButton._shade);

    canvas.drawOval(
      Rect.fromLTWH(w * 0.32, h * 0.08, w * 0.36, h * 0.22),
      Paint()..color = SampleReadingLampButton._glow.withValues(alpha: 0.85),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.46, h * 0.42, w * 0.08, h * 0.38),
      Paint()..color = SampleReadingLampButton._base,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.78, w * 0.56, h * 0.14),
        const Radius.circular(3),
      ),
      Paint()..color = SampleReadingLampButton._base,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

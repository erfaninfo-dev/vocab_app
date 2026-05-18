import 'package:flutter/material.dart';

class MagicBackground extends StatefulWidget {
  const MagicBackground({super.key, this.isDark = false});

  final bool isDark;

  @override
  State<MagicBackground> createState() => _MagicBackgroundState();
}

class _MagicBackgroundState extends State<MagicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.isDark
        ? const [Color(0xFF4A3728), Color(0xFF6B4E3D), Color(0xFF8B5A6B)]
        : const [Color(0xFFFDE68A), Color(0xFFFAC05E), Color(0xFFF78DA7)];

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _FloatingParticlesPainter(
              progress: _c.value,
              isDark: widget.isDark,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _FloatingParticlesPainter extends CustomPainter {
  _FloatingParticlesPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.white).withValues(
        alpha: isDark ? 0.12 : 0.28,
      );

    for (var i = 0; i < 40; i++) {
      final dx = size.width * ((i * 0.13 + progress) % 1.0);
      final dy = size.height * (((i * 0.37) + progress * 0.5) % 1.0);
      final r = 2.0 + (i % 3);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FancyLetter extends StatefulWidget {
  const FancyLetter({
    super.key,
    required this.char,
    required this.diameter,
    this.onTap,
    this.selected = false,
    this.errorHighlight = false,
  });

  final String char;
  final double diameter;
  final VoidCallback? onTap;
  final bool selected;
  final bool errorHighlight;

  @override
  State<FancyLetter> createState() => _FancyLetterState();
}

class _FancyLetterState extends State<FancyLetter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 0.14,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    final fontSize = (d * 0.42).clamp(18.0, 32.0);

    final gradient = widget.errorHighlight
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8A80), Color(0xFFD32F2F)],
          )
        : widget.selected
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          );

    final glow = widget.errorHighlight
        ? Colors.red
        : widget.selected
        ? const Color(0xFF43A047)
        : Colors.orange;

    final textColor = widget.selected || widget.errorHighlight
        ? Colors.white
        : const Color(0xFF5D4037);

    final child = AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final scale = 1 - _press.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(
            color: glow.withValues(alpha: 0.65),
            width: widget.selected ? 2.4 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: widget.selected ? 18 : 14,
              spreadRadius: widget.selected ? 3 : 2,
              color: glow.withValues(alpha: 0.45),
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              blurRadius: 6,
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.char.toUpperCase(),
          style: GoogleFonts.fredoka(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1,
            shadows: widget.selected
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return child;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: child,
    );
  }
}

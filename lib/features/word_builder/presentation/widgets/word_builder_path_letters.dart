import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/word_builder_tokens.dart';

/// Path letters with slide-in + pop for the newest letter.
class WordBuilderPathLetters extends StatelessWidget {
  const WordBuilderPathLetters({
    super.key,
    required this.built,
    required this.fontSize,
    required this.letterSpacing,
    required this.color,
    this.ghostNext,
    this.ghostScale = 1,
    this.isDark = false,
  });

  final String built;
  final double fontSize;
  final double letterSpacing;
  final Color color;
  final String? ghostNext;
  final double ghostScale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final upper = built.toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (upper.isEmpty)
          Text(
            ' ',
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          )
        else
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < upper.length; i++) ...[
                    if (i > 0) SizedBox(width: letterSpacing * 0.35),
                    _PathLetter(
                      key: ValueKey('pl-$i-${upper[i]}-${upper.length}'),
                      char: upper[i],
                      fontSize: fontSize,
                      color: color,
                      isNewest: i == upper.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (ghostNext != null) ...[
          const SizedBox(width: 6),
          Opacity(
            opacity: 0.38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WbTokens.rSm - 2),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                ),
                color: (isDark ? Colors.white : Colors.white).withValues(
                  alpha: isDark ? 0.06 : 0.45,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * ghostScale,
                  vertical: 4 * ghostScale,
                ),
                child: Text(
                  ghostNext!.toUpperCase(),
                  style: GoogleFonts.fredoka(
                    fontSize: 22 * ghostScale,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFFFF8E1)
                        : const Color(0xFF5D4037),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PathLetter extends StatefulWidget {
  const _PathLetter({
    super.key,
    required this.char,
    required this.fontSize,
    required this.color,
    required this.isNewest,
  });

  final String char;
  final double fontSize;
  final Color color;
  final bool isNewest;

  @override
  State<_PathLetter> createState() => _PathLetterState();
}

class _PathLetterState extends State<_PathLetter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: WbTokens.dFast);
    if (widget.isNewest) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = WbTokens.cPop.transform(_c.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(12 * (1 - t), 0),
            child: Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.char,
        style: GoogleFonts.fredoka(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
          color: widget.color,
        ),
      ),
    );
  }
}

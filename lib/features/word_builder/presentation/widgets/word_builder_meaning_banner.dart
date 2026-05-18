import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Translation line inside the selected-letters card (RTL for fa/ku).
class WordBuilderEmbeddedMeaning extends StatelessWidget {
  const WordBuilderEmbeddedMeaning({
    super.key,
    required this.label,
    required this.meaning,
    required this.isDark,
    this.layoutScale = 1,
  });

  final String label;
  final String meaning;
  final bool isDark;
  final double layoutScale;

  @override
  Widget build(BuildContext context) {
    final s = layoutScale.clamp(0.85, 1.15);
    final labelColor =
        isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100);
    final bodyColor =
        isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF5D4037);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              ),
              border: Border.all(
                color: const Color(0xFFE65100).withValues(alpha: 0.45),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(8 * s),
              child: Icon(
                Icons.translate_rounded,
                size: 20 * s,
                color: const Color(0xFF5D4037),
              ),
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.fredoka(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: labelColor,
                  ),
                ),
                SizedBox(height: 3 * s),
                Text(
                  meaning,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.fredoka(
                    fontSize: (17 * s).clamp(15.0, 20.0),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: bodyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WordBuilderMeaningBanner extends StatelessWidget {
  const WordBuilderMeaningBanner({
    super.key,
    required this.label,
    required this.meaning,
    required this.isDark,
    this.layoutScale = 1,
  });

  final String label;
  final String meaning;
  final bool isDark;
  final double layoutScale;

  @override
  Widget build(BuildContext context) {
    final s = layoutScale.clamp(0.85, 1.15);
    final labelColor = isDark
        ? const Color(0xFFFFB300)
        : const Color(0xFFE65100);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF5D4037);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * s),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF3E3228), const Color(0xFF2D2640)]
                  : const [Color(0xFFFFFDE7), Color(0xFFFFECB3)],
            ),
            border: Border.all(
              color: const Color(
                0xFFFFB300,
              ).withValues(alpha: isDark ? 0.75 : 0.95),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFF9800,
                ).withValues(alpha: isDark ? 0.35 : 0.32),
                blurRadius: 16 * s,
                spreadRadius: 0,
                offset: Offset(0, 5 * s),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                blurRadius: 10 * s,
                offset: Offset(0, 3 * s),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 12 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.45),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10 * s),
                    child: Icon(
                      Icons.translate_rounded,
                      size: 22 * s,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.fredoka(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: labelColor,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        meaning,
                        style: GoogleFonts.fredoka(
                          fontSize: (18 * s).clamp(16.0, 22.0),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

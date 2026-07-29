import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/word_builder_tokens.dart';

/// Top-right combo chip with enter pop, decay bar, and fade-out.
class WordBuilderComboChip extends StatefulWidget {
  const WordBuilderComboChip({
    super.key,
    required this.combo,
    required this.life,
    this.isDark = false,
  });

  final int combo;

  /// 0..1 remaining time until combo resets.
  final double life;
  final bool isDark;

  @override
  State<WordBuilderComboChip> createState() => _WordBuilderComboChipState();
}

class _WordBuilderComboChipState extends State<WordBuilderComboChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: WbTokens.dComboIn);
    if (widget.combo >= 2) {
      _enter.forward();
      _lastCombo = widget.combo;
    }
  }

  @override
  void didUpdateWidget(covariant WordBuilderComboChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo >= 2 && widget.combo != _lastCombo) {
      _lastCombo = widget.combo;
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 2) return const SizedBox.shrink();

    final fadeOut = widget.life < 0.18 ? (widget.life / 0.18).clamp(0.0, 1.0) : 1.0;

    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = WbTokens.cPop.transform(_enter.value.clamp(0.0, 1.0));
        final scale = 1.4 - 0.4 * t;
        return Opacity(
          opacity: fadeOut * t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale * (0.92 + 0.08 * fadeOut),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WbTokens.rPill),
          gradient: LinearGradient(
            colors: widget.isDark
                ? const [Color(0xFF5D4037), Color(0xFF3E2723)]
                : const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
          border: Border.all(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.85),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Combo x${widget.combo}',
                style: GoogleFonts.fredoka(
                  fontSize: WbTokens.tSm,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: widget.isDark
                      ? const Color(0xFFFFE0B2)
                      : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(WbTokens.rPill),
                child: LinearProgressIndicator(
                  value: widget.life.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: Colors.black.withValues(alpha: 0.12),
                  color: const Color(0xFFFF6F00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

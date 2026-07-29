import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../theme/word_builder_motion.dart';
import '../theme/word_builder_tokens.dart';

/// Staged level-complete panel: blur → card from bottom → staggered chrome.
class WordBuilderLevelCompletePanel extends StatefulWidget {
  const WordBuilderLevelCompletePanel({
    super.key,
    required this.l10n,
    required this.isDark,
    required this.layoutScale,
    required this.emoji,
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.tierComplete,
    this.chapterComplete = false,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final double layoutScale;
  final String emoji;
  final String title;
  final String body;
  final String nextLabel;
  final bool tierComplete;

  /// Confetti only on last stage of a chapter (Phase 5).
  final bool chapterComplete;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  State<WordBuilderLevelCompletePanel> createState() =>
      _WordBuilderLevelCompletePanelState();
}

class _WordBuilderLevelCompletePanelState
    extends State<WordBuilderLevelCompletePanel>
    with TickerProviderStateMixin {
  late final AnimationController _blur;
  late final AnimationController _card;
  late final AnimationController _stagger;
  late final AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    // MediaQuery is available after first frame; start with base tokens then
    // scale if reduced motion once dependencies resolve.
    _blur = AnimationController(vsync: this, duration: WbTokens.dLevelBlur);
    _card = AnimationController(vsync: this, duration: WbTokens.dSlow);
    _stagger = AnimationController(
      vsync: this,
      duration: WbTokens.dStagger * 4,
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = WbMotion.of(context);
    _blur.duration = motion.scale(WbTokens.dLevelBlur);
    _card.duration = motion.scale(WbTokens.dSlow);
    _stagger.duration = motion.scale(WbTokens.dStagger * 4);
    _confetti.duration = motion.scale(const Duration(milliseconds: 1600));
    if (!_started) {
      _started = true;
      _runIntro();
    }
  }

  bool _started = false;

  Future<void> _runIntro() async {
    await _blur.forward();
    if (!mounted) return;
    await _card.forward();
    if (!mounted) return;
    _stagger.forward();
    if (widget.chapterComplete) {
      _confetti.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _blur.dispose();
    _card.dispose();
    _stagger.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.layoutScale.clamp(0.85, 1.15);
    final titleColor = widget.isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4E342E);
    final bodyColor = widget.isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.82)
        : const Color(0xFF6D4C41);

    return AnimatedBuilder(
      animation: Listenable.merge([_blur, _card, _stagger, _confetti]),
      builder: (context, _) {
        final blurT = WbTokens.cEnter.transform(_blur.value);
        final cardT = WbTokens.cPop.transform(_card.value.clamp(0.0, 1.0));
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: blurT,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8 * blurT,
                  sigmaY: 8 * blurT,
                ),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.28 * blurT),
                ),
              ),
            ),
            if (widget.chapterComplete)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TierConfettiPainter(progress: _confetti.value),
                  ),
                ),
              ),
            Center(
              child: Opacity(
                opacity: cardT.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 56 * (1 - cardT)),
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * cardT,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22 * s,
                        vertical: 10 * s,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 360 * s),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              WbTokens.rLg * s,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.isDark
                                  ? const [
                                      Color(0xFF5D4037),
                                      Color(0xFF2D2640),
                                    ]
                                  : const [
                                      Color(0xFFFFFDE7),
                                      Color(0xFFFFECB3),
                                    ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFB300).withValues(
                                alpha: widget.isDark ? 0.82 : 0.95,
                              ),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(
                                  alpha: widget.isDark ? 0.28 : 0.36,
                                ),
                                blurRadius: 24 * s,
                                offset: Offset(0, 8 * s),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              WbTokens.s5 * s,
                              WbTokens.s5 * s,
                              WbTokens.s5 * s,
                              WbTokens.s4 * s,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _staggerChild(
                                  0,
                                  Text(
                                    widget.emoji,
                                    style: TextStyle(
                                      fontSize: widget.tierComplete
                                          ? WbTokens.tHero * s * 0.95
                                          : WbTokens.tXl * s * 1.15,
                                    ),
                                  ),
                                ),
                                SizedBox(height: WbTokens.s2 * s),
                                _staggerChild(
                                  1,
                                  Text(
                                    widget.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.fredoka(
                                      fontSize: WbTokens.tXl * s * 0.9,
                                      fontWeight: FontWeight.w900,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: WbTokens.s1 * s),
                                _staggerChild(
                                  2,
                                  Text(
                                    widget.body,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: WbTokens.tSm * s,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                      color: bodyColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: WbTokens.s4 * s),
                                _staggerChild(
                                  3,
                                  _LevelCompleteButton(
                                    label: widget.nextLabel,
                                    icon: Icons.arrow_forward_rounded,
                                    prominence: _BtnProminence.primary,
                                    isDark: widget.isDark,
                                    onPressed: widget.onNext,
                                  ),
                                ),
                                SizedBox(height: WbTokens.s2 * s + 2),
                                _staggerChild(
                                  3,
                                  _LevelCompleteButton(
                                    label: widget.l10n.wordBuilderReplayLevel,
                                    icon: Icons.replay_rounded,
                                    prominence: _BtnProminence.secondary,
                                    isDark: widget.isDark,
                                    onPressed: widget.onReplay,
                                  ),
                                ),
                                SizedBox(height: WbTokens.s2 * s),
                                _staggerChild(
                                  3,
                                  _LevelCompleteButton(
                                    label: widget.l10n.exit,
                                    icon: Icons.logout_rounded,
                                    prominence: _BtnProminence.tertiary,
                                    isDark: widget.isDark,
                                    onPressed: widget.onExit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _staggerChild(int index, Widget child) {
    final start = (index * WbTokens.dStagger.inMilliseconds) /
        _stagger.duration!.inMilliseconds;
    final t = Curves.easeOutCubic.transform(
      ((_stagger.value - start) / (1 - start).clamp(0.15, 1.0)).clamp(0.0, 1.0),
    );
    // Before stagger runs, keep content visible after card is in.
    final visible = _card.value >= 1 ? t : (_card.value > 0.85 ? 1.0 : 0.0);
    return Opacity(
      opacity: visible.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - visible)),
        child: child,
      ),
    );
  }
}

enum _BtnProminence { primary, secondary, tertiary }

class _LevelCompleteButton extends StatelessWidget {
  const _LevelCompleteButton({
    required this.label,
    required this.icon,
    required this.prominence,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final _BtnProminence prominence;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w900,
            fontSize: WbTokens.tMd,
          ),
        ),
      ],
    );

    switch (prominence) {
      case _BtnProminence.primary:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: const Color(0xFF4E342E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WbTokens.rMd - 2),
              ),
            ),
            child: child,
          ),
        );
      case _BtnProminence.secondary:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF3E3228).withValues(alpha: 0.64)
                  : const Color(0xFFFFF8E1).withValues(alpha: 0.7),
              foregroundColor: isDark
                  ? const Color(0xFFFFECB3)
                  : const Color(0xFF5D4037),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
                    : const Color(0xFFFFB300).withValues(alpha: 0.95),
                width: 1.6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WbTokens.rMd - 2),
              ),
            ),
            child: child,
          ),
        );
      case _BtnProminence.tertiary:
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFFFFECB3).withValues(alpha: 0.72)
                  : const Color(0xFF5D4037).withValues(alpha: 0.62),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Opacity(opacity: 0.85, child: child),
          ),
        );
    }
  }
}

class _TierConfettiPainter extends CustomPainter {
  _TierConfettiPainter({required this.progress});

  final double progress;

  static final _pieces = List<_Bit>.generate(32, (i) {
    final r = math.Random(i * 97 + 3);
    return _Bit(
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.35,
      speed: 0.55 + r.nextDouble() * 0.7,
      size: 4 + r.nextDouble() * 6,
      color: [
        const Color(0xFFFF7043),
        const Color(0xFFFFD54F),
        const Color(0xFF42A5F5),
        const Color(0xFF66BB6A),
        const Color(0xFFAB47BC),
      ][i % 5],
      spin: (r.nextDouble() - 0.5) * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    for (final p in _pieces) {
      final local = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * p.speed * (size.height + 40);
      final x = p.x * size.width + math.sin(local * math.pi * 2 + p.spin) * 18;
      final alpha = (1 - local).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withValues(alpha: 0.85 * alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TierConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Bit {
  const _Bit({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double spin;
}

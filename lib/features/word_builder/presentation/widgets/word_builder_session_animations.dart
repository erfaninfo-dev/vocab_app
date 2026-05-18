import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../word_builder_session_ambience.dart';

class WordBuilderShake extends StatefulWidget {
  const WordBuilderShake({
    super.key,
    required this.child,
    required this.trigger,
  });

  final Widget child;
  final int trigger;

  @override
  State<WordBuilderShake> createState() => _WordBuilderShakeState();
}

class _WordBuilderShakeState extends State<WordBuilderShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant WordBuilderShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _c.forward(from: 0);
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
      animation: _offset,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offset.value, _offset.value * 0.35),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Brief scale + amber glow on the current-word chip when a target is solved.
class WordBuilderSuccessChipGlow extends StatefulWidget {
  const WordBuilderSuccessChipGlow({
    super.key,
    required this.child,
    required this.trigger,
  });

  final Widget child;
  final int trigger;

  @override
  State<WordBuilderSuccessChipGlow> createState() =>
      _WordBuilderSuccessChipGlowState();
}

class _WordBuilderSuccessChipGlowState extends State<WordBuilderSuccessChipGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.07)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.07, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_c);
    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant WordBuilderSuccessChipGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _c.forward(from: 0);
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
        return Transform.scale(
          scale: _scale.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kWordBuilderSuccessTop
                      .withValues(alpha: 0.38 * _glow.value),
                  blurRadius: 22 * _glow.value,
                  spreadRadius: 2 * _glow.value,
                ),
                BoxShadow(
                  color: kWordBuilderAccentPlayLight
                      .withValues(alpha: 0.28 * _glow.value),
                  blurRadius: 14 * _glow.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class WordBuilderSuccessSparkles extends StatefulWidget {
  const WordBuilderSuccessSparkles({
    super.key,
    required this.trigger,
    this.grand = false,
  });

  final int trigger;
  final bool grand;

  @override
  State<WordBuilderSuccessSparkles> createState() =>
      _WordBuilderSuccessSparklesState();
}

class _WordBuilderSuccessSparklesState extends State<WordBuilderSuccessSparkles>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.grand ? 950 : 650),
    );
  }

  @override
  void didUpdateWidget(covariant WordBuilderSuccessSparkles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _c.duration = Duration(milliseconds: widget.grand ? 950 : 650);
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          if (_c.value == 0) return const SizedBox.shrink();
          return CustomPaint(
            painter: _SparklePainter(
              progress: _c.value,
              particleCount: widget.grand ? 14 : 6,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress, required this.particleCount});

  final double progress;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
      final center = Offset(size.width * 0.5, size.height * 0.28);
      final fade = (1 - progress).clamp(0.0, 1.0);
      for (var i = 0; i < particleCount; i++) {
        final rnd = math.Random(i * 17 + 3);
        final angle = rnd.nextDouble() * math.pi * 2;
        final dist = 32 + rnd.nextDouble() * (particleCount > 8 ? 58 : 42);
        final t = Curves.easeOut.transform(progress);
        final pos =
            center + Offset(math.cos(angle), math.sin(angle)) * dist * t;
        final color = i % 3 == 0
            ? kWordBuilderSuccessTop
            : i % 3 == 1
                ? kWordBuilderAccentPlayLight
                : const Color(0xFFFFF59D);
        final r = 3.5 + rnd.nextDouble() * 4;
        final paint = Paint()
          ..color = color.withValues(alpha: 0.85 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(pos, r, paint);
        final core = Paint()..color = Colors.white.withValues(alpha: 0.55 * fade);
        canvas.drawCircle(pos, r * 0.45, core);
      }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.particleCount != particleCount;
}

class WordBuilderLevelCompleteOverlay extends StatefulWidget {
  const WordBuilderLevelCompleteOverlay({
    super.key,
    required this.trigger,
    required this.title,
  });

  final int trigger;
  final String title;

  @override
  State<WordBuilderLevelCompleteOverlay> createState() =>
      _WordBuilderLevelCompleteOverlayState();
}

class _WordBuilderLevelCompleteOverlayState
    extends State<WordBuilderLevelCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _main;
  late AnimationController _confetti;
  late Animation<double> _backdrop;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeRotate;
  late Animation<double> _titleOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();
    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _backdrop = CurvedAnimation(
      parent: _main,
      curve: const Interval(0, 0.2, curve: Curves.easeOut),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 62,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
      ),
    );
    _badgeRotate = Tween<double>(begin: -0.35, end: 0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.05, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _ringScale = Tween<double>(begin: 0.4, end: 1.35).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.08, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _main,
      curve: const Interval(0.22, 0.45, curve: Curves.easeOut),
    );
    _titleSlide = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _main,
        curve: const Interval(0.22, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _main.addStatusListener(_onMainStatus);
  }

  void _onMainStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _main.reset();
      _confetti.reset();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant WordBuilderLevelCompleteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _main.forward(from: 0);
      _confetti.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _main.removeStatusListener(_onMainStatus);
    _main.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_main, _confetti]),
        builder: (context, _) {
          if (_main.value == 0 && _confetti.value == 0) {
            return const SizedBox.shrink();
          }
          final fadeOut = _main.value > 0.68
              ? (1 - ((_main.value - 0.68) / 0.32).clamp(0.0, 1.0))
              : 1.0;
          final backdropAlpha =
              (_backdrop.value * fadeOut * 0.42).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black.withValues(alpha: backdropAlpha * 0.35),
              ),
              CustomPaint(
                painter: _LevelConfettiPainter(progress: _confetti.value),
                size: Size.infinite,
              ),
              Center(
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.scale(
                    scale: _badgeScale.value,
                    child: Transform.rotate(
                      angle: _badgeRotate.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Container(
                              width: 168,
                              height: 168,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kWordBuilderAccentPlayLight
                                      .withValues(alpha: 0.55),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kWordBuilderAccentPlay
                                        .withValues(alpha: 0.35),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  kWordBuilderSuccessTop,
                                  kWordBuilderSuccessBottom,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kWordBuilderSuccessBottom
                                      .withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.sizeOf(context).height * 0.58,
                child: Opacity(
                  opacity: (_titleOpacity.value * fadeOut).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: kWordBuilderAccentPlay,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelConfettiPainter extends CustomPainter {
  _LevelConfettiPainter({required this.progress});

  final double progress;

  static final _pieces = List<_ConfettiPiece>.generate(28, (i) {
    final rnd = math.Random(i * 31 + 11);
    return _ConfettiPiece(
      x: rnd.nextDouble(),
      startY: -0.05 - rnd.nextDouble() * 0.15,
      speed: 0.55 + rnd.nextDouble() * 0.55,
      wobble: rnd.nextDouble() * math.pi * 2,
      wobbleAmp: 6 + rnd.nextDouble() * 14,
      width: 5 + rnd.nextDouble() * 5,
      height: 8 + rnd.nextDouble() * 10,
      rotation: rnd.nextDouble() * math.pi,
      spin: (rnd.nextDouble() - 0.5) * 6,
      color: i % 4 == 0
          ? kWordBuilderAccentPlay
          : i % 4 == 1
              ? kWordBuilderAccentPlayLight
              : i % 4 == 2
                  ? kWordBuilderSuccessTop
                  : kWordBuilderSuccessBottom,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final fade = (1 - ((progress - 0.55) / 0.45).clamp(0.0, 1.0));
    for (final p in _pieces) {
      final y = (p.startY + t * p.speed) * size.height;
      if (y < -20 || y > size.height + 40) continue;
      final x =
          p.x * size.width + math.sin(p.wobble + t * 5) * p.wobbleAmp;
      final paint = Paint()..color = p.color.withValues(alpha: 0.9 * fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.width,
            height: p.height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LevelConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.wobble,
    required this.wobbleAmp,
    required this.width,
    required this.height,
    required this.rotation,
    required this.spin,
    required this.color,
  });

  final double x;
  final double startY;
  final double speed;
  final double wobble;
  final double wobbleAmp;
  final double width;
  final double height;
  final double rotation;
  final double spin;
  final Color color;
}

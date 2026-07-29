import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/word_builder_tokens.dart';

enum CoachFingerKind { none, tap, hold, dragPull }

/// One coach-mark step. Advance when [isComplete] becomes true (polled),
/// or after [autoAdvanceAfter] elapses once the step is shown.
class CoachStep {
  const CoachStep({
    required this.id,
    required this.message,
    this.targetRect,
    this.isComplete,
    this.autoAdvanceAfter,
    this.finger = CoachFingerKind.none,
    this.allowSkip = false,
    this.dimOpacity = 0.58,
    this.blocksInput = true,
  });

  final String id;
  final String message;

  /// Hole in the dim overlay (board-local coordinates). Null = full dim.
  final Rect? Function()? targetRect;

  /// When this returns true, the coach advances (polled each frame).
  final bool Function()? isComplete;

  /// Auto-advance after this duration (e.g. freeing banner).
  final Duration? autoAdvanceAfter;

  final CoachFingerKind finger;
  final bool allowSkip;
  final double dimOpacity;

  /// When false, only the visual spotlight is shown (gameplay stays interactive).
  final bool blocksInput;
}

/// Reusable spotlight coach (Phase 6). Place inside a [Stack] over the board.
class CoachOverlay extends StatefulWidget {
  const CoachOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
    this.onStepChanged,
  });

  final List<CoachStep> steps;
  final VoidCallback onFinished;
  final ValueChanged<int>? onStepChanged;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay>
    with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _finger;
  late final Ticker _pollTicker;
  DateTime? _stepShownAt;
  bool _advancing = false;

  CoachStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _finger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pollTicker = createTicker((_) {
      if (!mounted || _advancing) return;
      _tryAdvance();
    })..start();
    _stepShownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onStepChanged?.call(_index);
    });
  }

  @override
  void dispose() {
    _pollTicker.dispose();
    _finger.dispose();
    super.dispose();
  }

  void _advance() {
    if (_advancing) return;
    _advancing = true;
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index += 1;
      _stepShownAt = DateTime.now();
      _advancing = false;
    });
    widget.onStepChanged?.call(_index);
  }

  void _tryAdvance() {
    if (!mounted || widget.steps.isEmpty || _advancing) return;
    final step = _step;
    if (step.isComplete?.call() ?? false) {
      _advance();
      return;
    }
    final auto = step.autoAdvanceAfter;
    final shown = _stepShownAt;
    if (auto != null && shown != null) {
      if (DateTime.now().difference(shown) >= auto) {
        _advance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final hole = _step.targetRect?.call();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                dimOpacity: _step.dimOpacity,
              ),
              size: size,
            ),
            if (_step.blocksInput) ..._barrierRects(hole, size),
            if (hole != null && _step.finger != CoachFingerKind.none)
              IgnorePointer(
                child: _FingerHint(
                  hole: hole,
                  kind: _step.finger,
                  animation: _finger,
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: !_step.allowSkip,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WbTokens.s4,
                    WbTokens.s2,
                    WbTokens.s4,
                    WbTokens.s5,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(WbTokens.rMd),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.75),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _step.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: WbTokens.tMd,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (_step.allowSkip) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _advance,
                                child: Text(
                                  MaterialLocalizations.of(context)
                                      .continueButtonLabel,
                                ),
                              ),
                            ],
                          ],
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

  List<Widget> _barrierRects(Rect? hole, Size size) {
    Widget barrier() => const AbsorbPointer(
          child: ColoredBox(color: Color(0x00000000)),
        );
    if (hole == null) {
      return [Positioned.fill(child: barrier())];
    }
    final h = hole.inflate(6);
    return [
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: h.top.clamp(0.0, size.height),
        child: barrier(),
      ),
      Positioned(
        left: 0,
        top: h.bottom,
        right: 0,
        bottom: 0,
        child: barrier(),
      ),
      Positioned(
        left: 0,
        top: h.top,
        width: h.left.clamp(0.0, size.width),
        height: h.height,
        child: barrier(),
      ),
      Positioned(
        left: h.right,
        top: h.top,
        right: 0,
        height: h.height,
        child: barrier(),
      ),
    ];
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.dimOpacity});

  final Rect? hole;
  final double dimOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: dimOpacity);
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }
    final h = hole!.inflate(4);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(h, const Radius.circular(16)));
    canvas.drawPath(path, dim);
    canvas.drawRRect(
      RRect.fromRectAndRadius(h, const Radius.circular(16)),
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.dimOpacity != dimOpacity;
}

class _FingerHint extends StatelessWidget {
  const _FingerHint({
    required this.hole,
    required this.kind,
    required this.animation,
  });

  final Rect hole;
  final CoachFingerKind kind;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        final Offset pos = switch (kind) {
          CoachFingerKind.hold => hole.center + Offset(0, 18 + 6 * t),
          CoachFingerKind.dragPull => hole.center + Offset(0, 10 + 28 * t),
          CoachFingerKind.tap => hole.center + Offset(0, 8 * t),
          CoachFingerKind.none => hole.center,
        };
        return Positioned(
          left: pos.dx - 18,
          top: pos.dy - 8,
          child: Transform.rotate(
            angle: kind == CoachFingerKind.dragPull ? 0.35 : 0.2,
            child: Icon(
              Icons.touch_app_rounded,
              size: 36,
              color: Colors.white.withValues(alpha: 0.92),
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Resolve a [GlobalKey] into a rect in [ancestor] coordinates.
Rect? coachRectForKey(GlobalKey key, BuildContext ancestor) {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final box = ctx.findRenderObject() as RenderBox?;
  final ancestorBox = ancestor.findRenderObject() as RenderBox?;
  if (box == null || ancestorBox == null || !box.hasSize) return null;
  final topLeft = ancestorBox.globalToLocal(box.localToGlobal(Offset.zero));
  return topLeft & box.size;
}

/// Soft pulse ring for cargo highlight without a GlobalKey.
void paintCoachPulse(Canvas canvas, Offset c, double r, double phase) {
  final t = 0.5 + 0.5 * math.sin(phase);
  canvas.drawCircle(
    c,
    r + 6 + 4 * t,
    Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35 + 0.25 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
}

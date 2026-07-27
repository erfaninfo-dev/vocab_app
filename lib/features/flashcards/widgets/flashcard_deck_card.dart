import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flashcard_progress.dart';

/// Full flashcard deck widget: 3D flip (tap) + horizontal slide (swipe/buttons).
///
/// Front and back faces always occupy the same [StackFit.expand] box so their
/// size never changes when flipping. Card navigation plays a slide-out / slide-in
/// animation instead of swapping text instantly.
class FlashcardDeckCard extends StatefulWidget {
  const FlashcardDeckCard({
    super.key,
    required this.cardKey,
    required this.front,
    required this.back,
    required this.showBack,
    required this.onFlip,
    this.onNext,
    this.onPrev,
    this.swipeEnabled = true,
  });

  final Object cardKey;
  final Widget front;
  final Widget back;
  final bool showBack;
  final VoidCallback onFlip;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final bool swipeEnabled;

  @override
  FlashcardDeckCardState createState() => FlashcardDeckCardState();
}

class FlashcardDeckCardState extends State<FlashcardDeckCard>
    with TickerProviderStateMixin {
  static const _flipMs = 340;
  static const _slideMs = 300;
  static const _dragCommitPx = 72.0;
  static const _velocityCommit = 420.0;

  late final AnimationController _flipCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _flipAnim;

  double _dragPx = 0;
  bool _navBusy = false;
  int _navDirection = 1;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _flipMs),
      value: widget.showBack ? 1 : 0,
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slideMs),
    );
    _flipAnim = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant FlashcardDeckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack != widget.showBack && !_navBusy) {
      if (widget.showBack) {
        _flipCtrl.forward();
      } else {
        _flipCtrl.reverse();
      }
    }
    if (oldWidget.cardKey != widget.cardKey && !_navBusy) {
      _dragPx = 0;
      _slideCtrl.value = 0;
      _flipCtrl.value = widget.showBack ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> goNext() => _navigate(1, widget.onNext);

  Future<void> goPrev() => _navigate(-1, widget.onPrev);

  Future<void> _navigate(int direction, VoidCallback? action) async {
    if (action == null || _navBusy || !mounted) return;
    _navBusy = true;
    _navDirection = direction;
    HapticFeedback.selectionClick();

    // Phase 1: slide current card off-screen (0 → 0.5).
    await _slideCtrl.animateTo(
      0.5,
      curve: Curves.easeInCubic,
    );

    if (!mounted) return;
    action();
    _dragPx = 0;

    // Phase 2: slide new card in from the opposite edge (0.5 → 1).
    await _slideCtrl.animateTo(
      1,
      curve: Curves.easeOutCubic,
    );

    if (mounted) {
      _slideCtrl.value = 0;
      _navBusy = false;
    }
  }

  void _onTap() {
    if (_navBusy) return;
    HapticFeedback.lightImpact();
    widget.onFlip();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_navBusy || !widget.swipeEnabled) return;
    setState(() {
      _dragPx += details.delta.dx;
      final width = context.size?.width ?? 400;
      _dragPx = _dragPx.clamp(-width * 0.45, width * 0.45);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_navBusy || !widget.swipeEnabled) return;
    final v = details.primaryVelocity ?? 0;
    if (_dragPx <= -_dragCommitPx || v <= -_velocityCommit) {
      goNext();
      return;
    }
    if (_dragPx >= _dragCommitPx || v >= _velocityCommit) {
      goPrev();
      return;
    }
    setState(() => _dragPx = 0);
  }

  double _slideOffsetPx(double width) {
    if (_navBusy) {
      final t = _slideCtrl.value;
      if (t <= 0.5) {
        return -_navDirection * (t / 0.5) * width;
      }
      final inT = (t - 0.5) / 0.5;
      return _navDirection * (1 - inT) * width;
    }
    return _dragPx;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onTap: _onTap,
          onHorizontalDragUpdate: widget.swipeEnabled ? _onDragUpdate : null,
          onHorizontalDragEnd: widget.swipeEnabled ? _onDragEnd : null,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(FlashcardTokens.cardRadius),
            child: AnimatedBuilder(
              animation: Listenable.merge([_flipAnim, _slideCtrl]),
              builder: (context, _) {
                final slideX = _slideOffsetPx(width);
                final t = _flipAnim.value;
                return Transform.translate(
                  offset: Offset(slideX, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      _FlipLayer(
                        angle: math.pi * t,
                        visible: t <= 0.5,
                        child: widget.front,
                      ),
                      _FlipLayer(
                        angle: math.pi * (t - 1),
                        visible: t > 0.5,
                        child: widget.back,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FlipLayer extends StatelessWidget {
  const _FlipLayer({
    required this.angle,
    required this.visible,
    required this.child,
  });

  final double angle;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

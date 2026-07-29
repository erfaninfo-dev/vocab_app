import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/word_builder_tokens.dart';

/// Horizontal shake — 3 oscillations over [WbTokens.dShakeWrong] (~300ms).
class ShakeWrapper extends StatefulWidget {
  const ShakeWrapper({
    super.key,
    required this.shake,
    required this.child,
  });

  final bool shake;
  final Widget child;

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: WbTokens.dShakeWrong);
  }

  @override
  void didUpdateWidget(ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
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
    if (!widget.shake && !_c.isAnimating) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // 3 full oscillations, decaying amplitude.
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

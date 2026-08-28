import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/word_builder_models.dart';
import '../widgets/fancy_letter.dart';

class PvpChallengeLetterTray extends StatefulWidget {
  const PvpChallengeLetterTray({
    super.key,
    required this.letters,
    required this.path,
    required this.pathWrong,
    required this.enabled,
    required this.onLetter,
    required this.onRelease,
    required this.onClearPath,
  });

  final List<LetterInstance> letters;
  final List<LetterInstance> path;
  final bool pathWrong;
  final bool enabled;
  final void Function(LetterInstance letter) onLetter;
  final VoidCallback onRelease;
  final VoidCallback onClearPath;

  @override
  State<PvpChallengeLetterTray> createState() => _PvpChallengeLetterTrayState();
}

class _PvpChallengeLetterTrayState extends State<PvpChallengeLetterTray>
    with SingleTickerProviderStateMixin {
  int? _dragLastId;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = _layout(size, widget.letters.length);
        final pathColor = widget.pathWrong
            ? scheme.error.withValues(alpha: 0.82)
            : scheme.primary.withValues(alpha: 0.55);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: widget.enabled ? (e) => _down(e.localPosition, layout) : null,
          onPointerMove: widget.enabled ? (e) => _move(e.localPosition, layout) : null,
          onPointerUp: widget.enabled ? (_) => _up() : null,
          onPointerCancel: widget.enabled
              ? (_) {
                  _dragLastId = null;
                  widget.onClearPath();
                }
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RotationTransition(
                turns: _orbit,
                child: CustomPaint(
                  size: size,
                  painter: _GlowPainter(center: layout.center, radius: layout.trayRadius + 8),
                ),
              ),
              CustomPaint(
                size: size,
                painter: _SaucerPainter(center: layout.center, radius: layout.trayRadius, scheme: scheme),
              ),
              if (widget.path.length > 1)
                CustomPaint(
                  size: size,
                  painter: _PathPainter(
                    centers: layout.centers,
                    pathIndices: _pathIndices(layout),
                    color: pathColor,
                  ),
                ),
              for (var i = 0; i < widget.letters.length; i++)
                Positioned(
                  left: layout.centers[i].dx - layout.tile / 2,
                  top: layout.centers[i].dy - layout.tile / 2,
                  child: FancyLetter(
                    char: widget.letters[i].char,
                    diameter: layout.tile,
                    selected: widget.path.any((p) => p.id == widget.letters[i].id),
                    errorHighlight: widget.pathWrong &&
                        widget.path.any((p) => p.id == widget.letters[i].id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<int> _pathIndices(_TrayLayout layout) {
    final out = <int>[];
    for (final p in widget.path) {
      final i = widget.letters.indexWhere((e) => e.id == p.id);
      if (i >= 0) out.add(i);
    }
    return out;
  }

  void _down(Offset local, _TrayLayout layout) {
    _dragLastId = null;
    final hit = _hit(local, layout);
    if (hit != null) {
      final letter = widget.letters[hit];
      _dragLastId = letter.id;
      widget.onLetter(letter);
    }
  }

  void _move(Offset local, _TrayLayout layout) {
    final hit = _hit(local, layout);
    if (hit == null) return;
    final letter = widget.letters[hit];
    if (_dragLastId == letter.id) return;
    _dragLastId = letter.id;
    widget.onLetter(letter);
  }

  void _up() {
    _dragLastId = null;
    if (widget.path.length <= 1) {
      widget.onClearPath();
      return;
    }
    widget.onRelease();
  }

  int? _hit(Offset local, _TrayLayout layout) {
    for (var i = 0; i < layout.centers.length; i++) {
      if ((layout.centers[i] - local).distance <= layout.hitRadius) return i;
    }
    return null;
  }
}

class _TrayLayout {
  const _TrayLayout({
    required this.centers,
    required this.tile,
    required this.hitRadius,
    required this.center,
    required this.trayRadius,
  });

  final List<Offset> centers;
  final double tile;
  final double hitRadius;
  final Offset center;
  final double trayRadius;
}

_TrayLayout _layout(Size bounds, int n) {
  if (n <= 0) {
    return _TrayLayout(
      centers: const [],
      tile: 0,
      hitRadius: 0,
      center: Offset(bounds.width / 2, bounds.height / 2),
      trayRadius: 0,
    );
  }
  final m = math.min(bounds.width, bounds.height);
  final maxR = m * 0.5 - 6;
  var tile = 54.0;
  final gap = n <= 3 ? 34.0 : (n <= 4 ? 30.0 : 28.0);
  const ringFill = 0.84;
  final sinHalf = math.sin(math.pi / n);
  double minRadiusForTile(double t) => (t + gap) / (2 * sinHalf);
  while (minRadiusForTile(tile) > maxR * 0.98 && tile > 32) {
    tile -= 2;
  }
  final need = minRadiusForTile(tile);
  final r = math.min(maxR, math.max(need, maxR * ringFill));
  final c = Offset(bounds.width / 2, bounds.height / 2);
  final out = <Offset>[];
  for (var i = 0; i < n; i++) {
    final ang = -math.pi / 2 + 2 * math.pi * i / n;
    out.add(c + Offset(math.cos(ang), math.sin(ang)) * r);
  }
  final trayR = math.min(r + tile / 2 + 22, m / 2 - 5);
  return _TrayLayout(
    centers: out,
    tile: tile,
    hitRadius: tile * 0.55,
    center: c,
    trayRadius: trayR,
  );
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB300).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _SaucerPainter extends CustomPainter {
  _SaucerPainter({required this.center, required this.radius, required this.scheme});

  final Offset center;
  final double radius;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          scheme.surfaceContainerHighest.withValues(alpha: 0.95),
          scheme.surface.withValues(alpha: 0.88),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFFFB300).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _SaucerPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.centers,
    required this.pathIndices,
    required this.color,
  });

  final List<Offset> centers;
  final List<int> pathIndices;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (pathIndices.length < 2) return;
    final path = Path();
    path.moveTo(centers[pathIndices.first].dx, centers[pathIndices.first].dy);
    for (var i = 1; i < pathIndices.length; i++) {
      path.lineTo(centers[pathIndices[i]].dx, centers[pathIndices[i]].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}

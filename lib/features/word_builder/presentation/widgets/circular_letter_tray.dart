import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/word_builder_game_notifier.dart';
import '../../domain/word_builder_models.dart';
import 'fancy_letter.dart';
import 'tray_scenario_scene.dart';

class _TrayLayout {
  const _TrayLayout({
    required this.centers,
    required this.tile,
    required this.hitRadius,
    required this.center,
    required this.ringRadius,
    required this.trayRadius,
  });

  final List<Offset> centers;
  final double tile;
  final double hitRadius;
  final Offset center;
  final double ringRadius;
  final double trayRadius;
}

_TrayLayout _computeTrayLayout(Size bounds, int n, {double? layoutMinExtent}) {
  if (n <= 0) {
    return _TrayLayout(
      centers: const [],
      tile: 0,
      hitRadius: 0,
      center: Offset(bounds.width / 2, bounds.height / 2),
      ringRadius: 0,
      trayRadius: 0,
    );
  }
  final m = layoutMinExtent ?? math.min(bounds.width, bounds.height);
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
  final maxTray = m / 2 - 5;
  final trayR = math.min(r + tile / 2 + 22, maxTray);
  return _TrayLayout(
    centers: out,
    tile: tile,
    hitRadius: tile * 0.55,
    center: c,
    ringRadius: r,
    trayRadius: trayR,
  );
}

double wordBuilderTraySaucerRadius(Size trayBoxSize, int letterCount) {
  if (letterCount <= 0) return 0;
  return _computeTrayLayout(trayBoxSize, letterCount).trayRadius;
}

bool wordBuilderTrayChromeHit(
  Offset p,
  double w,
  double h,
  double inset,
  double btn,
  TextDirection textDir,
) {
  final rHit = btn * 0.58;
  final hintLeft = textDir == TextDirection.ltr ? inset : w - inset - btn;
  final translateLeft = textDir == TextDirection.ltr ? w - inset - btn : inset;
  final centers = <Offset>[
    Offset(hintLeft + btn / 2, inset + btn / 2),
    Offset(hintLeft + btn / 2, h - inset - btn / 2),
    Offset(translateLeft + btn / 2, h - inset - btn / 2),
  ];
  for (final c in centers) {
    if ((p - c).distance <= rHit) return true;
  }
  return false;
}

class CircularLetterTray extends ConsumerStatefulWidget {
  const CircularLetterTray({
    super.key,
    required this.bookKey,
    required this.letters,
    this.layoutMinExtent,
    this.chromeInset,
    this.chromeButtonSize,
  });

  final int bookKey;
  final List<LetterInstance> letters;

  /// When set (e.g. `min(panelWidth, side)`), letter ring size matches that
  /// extent while [LayoutBuilder] [bounds] can be taller for tap-outside.
  final double? layoutMinExtent;

  /// When both set, taps on session corner controls do not clear the path.
  final double? chromeInset;
  final double? chromeButtonSize;

  @override
  ConsumerState<CircularLetterTray> createState() => _CircularLetterTrayState();
}

class _CircularLetterTrayState extends ConsumerState<CircularLetterTray>
    with TickerProviderStateMixin {
  int? _dragLastId;
  Timer? _wrongFadeTimer;
  bool _fadingWrongLetters = false;
  bool _trackedPathWrong = false;
  late final AnimationController _orbit;

  static const double _kTapClearMoveSlop = 18;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  Offset? _tapClearOrigin;
  bool _tapClearStartedOutsideTrayCircle = false;
  double _tapClearMaxMove = 0;

  @override
  void dispose() {
    _wrongFadeTimer?.cancel();
    _orbit.dispose();
    super.dispose();
  }

  void _syncWrongFadeAnimation(bool pathWrong) {
    if (pathWrong == _trackedPathWrong) return;
    final was = _trackedPathWrong;
    _trackedPathWrong = pathWrong;
    if (!was && pathWrong) {
      _wrongFadeTimer?.cancel();
      _fadingWrongLetters = false;
      _wrongFadeTimer = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _fadingWrongLetters = true);
      });
    } else if (was && !pathWrong) {
      _wrongFadeTimer?.cancel();
      _fadingWrongLetters = false;
    }
  }

  int? _hit(Offset local, _TrayLayout layout, int n) {
    final centers = layout.centers;
    final hitR = layout.hitRadius;
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - local).distance <= hitR) {
        return i;
      }
    }
    return null;
  }

  bool _outsideTrayCircle(Offset local, _TrayLayout layout) {
    return (local - layout.center).distance > layout.trayRadius;
  }

  void _resetTapClearTracking() {
    _tapClearOrigin = null;
    _tapClearStartedOutsideTrayCircle = false;
    _tapClearMaxMove = 0;
  }

  bool _hitChrome(Offset local, Size bounds) {
    final inset = widget.chromeInset;
    final btn = widget.chromeButtonSize;
    if (inset == null || btn == null) return false;
    return wordBuilderTrayChromeHit(
      local,
      bounds.width,
      bounds.height,
      inset,
      btn,
      Directionality.of(context),
    );
  }

  void _onTrayPointerUp(
    List<LetterInstance> path,
    bool pathWrong,
    WordBuilderGameNotifier notifier,
  ) {
    final startedOutside = _tapClearStartedOutsideTrayCircle;
    final maxMove = _tapClearMaxMove;
    _resetTapClearTracking();
    _dragLastId = null;

    if (pathWrong) return;

    if (startedOutside && path.isNotEmpty && maxMove < _kTapClearMoveSlop) {
      unawaited(notifier.clearPathOnly());
      return;
    }

    if (path.length <= 1) {
      if (path.isNotEmpty) {
        unawaited(notifier.clearPathOnly());
      }
      return;
    }

    unawaited(notifier.evaluatePathOnDragRelease());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(wordBuilderGameProvider(widget.bookKey));
    final path = async.valueOrNull?.path ?? const <LetterInstance>[];
    final pathWrong = async.valueOrNull?.pathWrongHighlight ?? false;
    final trayBlocked = async.valueOrNull?.trayInputBlocked ?? false;
    final notifier = ref.read(wordBuilderGameProvider(widget.bookKey).notifier);

    _syncWrongFadeAnimation(pathWrong);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final n = widget.letters.length;
        final layout = _computeTrayLayout(
          size,
          n,
          layoutMinExtent: widget.layoutMinExtent,
        );
        final centers = layout.centers;
        final pathIdx = <int>[];
        for (final p in path) {
          final i = widget.letters.indexWhere((e) => e.id == p.id);
          if (i >= 0) pathIdx.add(i);
        }
        final half = layout.tile / 2;
        final trayD = layout.trayRadius * 2;

        if (n <= 0) {
          return SizedBox(width: size.width, height: size.height);
        }

        final pathColor = pathWrong
            ? scheme.error.withValues(alpha: 0.82)
            : scheme.primary.withValues(alpha: 0.55);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: trayBlocked,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  _dragLastId = null;
                  if (_hitChrome(e.localPosition, size)) {
                    _resetTapClearTracking();
                    return;
                  }
                  _tapClearOrigin = e.localPosition;
                  _tapClearStartedOutsideTrayCircle = _outsideTrayCircle(
                    e.localPosition,
                    layout,
                  );
                  _tapClearMaxMove = 0;
                  final hit = _hit(e.localPosition, layout, n);
                  if (hit != null) {
                    final letter = widget.letters[hit];
                    _dragLastId = letter.id;
                    unawaited(notifier.appendLetterFromDrag(letter));
                  }
                },
                onPointerMove: (e) {
                  if (_hitChrome(e.localPosition, size)) {
                    _resetTapClearTracking();
                  }
                  final o = _tapClearOrigin;
                  if (o != null) {
                    _tapClearMaxMove = math.max(
                      _tapClearMaxMove,
                      (e.localPosition - o).distance,
                    );
                  }
                  final hit = _hit(e.localPosition, layout, n);
                  if (hit == null) return;
                  final letter = widget.letters[hit];
                  if (_dragLastId == letter.id) return;
                  _dragLastId = letter.id;
                  notifier.appendLetterFromDrag(letter);
                },
                onPointerUp: (_) => _onTrayPointerUp(path, pathWrong, notifier),
                onPointerCancel: (_) {
                  _resetTapClearTracking();
                  _dragLastId = null;
                  if (!pathWrong && path.isNotEmpty) {
                    unawaited(notifier.clearPathOnly());
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _orbit,
                      child: CustomPaint(
                        size: size,
                        painter: _OrbitGlowPainter(
                          center: layout.center,
                          radius: layout.trayRadius + 8,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: size,
                      painter: _TraySaucerPainter(
                        center: layout.center,
                        radius: layout.trayRadius,
                        scheme: scheme,
                      ),
                    ),
                    TrayScenarioScene(
                      bookKey: widget.bookKey,
                      size: size,
                      center: layout.center,
                      innerRadius: layout.trayRadius * 0.72,
                      saucerRadius: layout.trayRadius,
                      faceRadius: layout.trayRadius * 0.5,
                    ),
                    AnimatedOpacity(
                      key: ValueKey(pathWrong),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      opacity: pathWrong && _fadingWrongLetters ? 0 : 1,
                      onEnd: () {
                        if (!mounted) return;
                        final cur = ref
                            .read(wordBuilderGameProvider(widget.bookKey))
                            .valueOrNull;
                        if (cur?.pathWrongHighlight == true &&
                            _fadingWrongLetters) {
                          notifier.clearWrongSelectionAfterFade();
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: size,
                            painter: _PathPainter(
                              centers: centers,
                              pathIndices: pathIdx,
                              color: pathColor,
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: trayD,
                              height: trayD,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  for (var i = 0; i < n; i++)
                                    Positioned(
                                      left:
                                          centers[i].dx -
                                          half -
                                          (layout.center.dx - trayD / 2),
                                      top:
                                          centers[i].dy -
                                          half -
                                          (layout.center.dy - trayD / 2),
                                      width: layout.tile,
                                      height: layout.tile,
                                      child: FancyLetter(
                                        char: widget.letters[i].char,
                                        diameter: layout.tile,
                                        selected: path.any(
                                          (e) => e.id == widget.letters[i].id,
                                        ),
                                        errorHighlight:
                                            pathWrong &&
                                            path.any(
                                              (e) =>
                                                  e.id == widget.letters[i].id,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrbitGlowPainter extends CustomPainter {
  _OrbitGlowPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, paint);
    final dots = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final ang = 2 * math.pi * i / 8;
      final p = center + Offset(math.cos(ang), math.sin(ang)) * radius;
      canvas.drawCircle(p, 4, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitGlowPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}

class _TraySaucerPainter extends CustomPainter {
  _TraySaucerPainter({
    required this.center,
    required this.radius,
    required this.scheme,
  });

  final Offset center;
  final double radius;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final r = Rect.fromCircle(center: center, radius: radius);
    final fill = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topLeft,
        radius: 1.05,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(r);
    canvas.drawCircle(center, radius, fill);

    final rim = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, rim);
  }

  @override
  bool shouldRepaint(covariant _TraySaucerPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.scheme.surfaceContainerLow != scheme.surfaceContainerLow;
  }
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(centers[pathIndices.first].dx, centers[pathIndices.first].dy);
    for (var k = 1; k < pathIndices.length; k++) {
      final p = centers[pathIndices[k]];
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.pathIndices != pathIndices ||
        oldDelegate.centers != centers ||
        oldDelegate.color != color;
  }
}

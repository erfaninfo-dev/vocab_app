import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tray_water_constants.dart';

enum _FaucetFlow { left, up }

/// Tub, inlet/outlet pipes, valves, and animated water for the letter tray center.
class TrayWaterPainter extends CustomPainter {
  TrayWaterPainter({
    required this.size,
    required this.center,
    required this.tubRadius,
    required this.saucerRadius,
    required this.waterLevel,
    required this.wavePhase,
    this.inletPipeFlowPhase = 0,
    required this.inletValveOpen,
    required this.outletValveOpen,
    this.liveInletDrip = false,
    this.inletDripPhase = 0,
    this.waterAgitation = 0,
    this.scheme,
  });

  final Size size;
  final Offset center;
  /// Glass tub scale (≈ 0.72 × [saucerRadius]).
  final double tubRadius;

  /// Visible cream saucer — water/drips clip to this circle.
  final double saucerRadius;
  final double waterLevel;
  final double wavePhase;
  final double inletPipeFlowPhase;
  final double inletValveOpen;
  final double outletValveOpen;
  final bool liveInletDrip;
  final double inletDripPhase;
  final double waterAgitation;
  final ColorScheme? scheme;

  static const Color _tubGlass = Color(0xFFE8F4FC);
  static const Color _tubRim = Color(0xFFB0BEC5);
  static const Color _chromeHi = Color(0xFFECEFF1);
  static const Color _chromeMid = Color(0xFF90A4AE);
  static const Color _chromeLo = Color(0xFF546E7A);
  static const Color _waterDeep = Color(0xFF4FC3F7);
  static const Color _waterHi = Color(0xFF81D4FA);

  Rect _tubRect() {
    return Rect.fromCenter(
      center: center + Offset(0, tubRadius * 0.04),
      width: tubRadius * 1.75,
      height: tubRadius * 1.95,
    );
  }

  Path _saucerClipPath() => Path()
    ..addOval(Rect.fromCircle(center: center, radius: saucerRadius));

  void _clipToBowl(Canvas canvas, Rect tub) {
    canvas.clipPath(Path()..addOval(tub));
    canvas.clipPath(_saucerClipPath());
  }

  double get _pipeThick => tubRadius * 0.19;

  double _saucerBottomY() => center.dy + saucerRadius;

  static const double _bottomPipeBleed = 10.0;
  static const double _rightPipeBleed = 10.0;

  double _pipeScreenBottom(double canvasHeight) =>
      canvasHeight + _bottomPipeBleed;

  double _pipeScreenRight(double canvasWidth) => canvasWidth + _rightPipeBleed;

  void _clipExcludeBowl(Canvas canvas, Size canvasSize, Rect tub) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        Rect.fromLTWH(
          -40,
          -40,
          canvasSize.width + 80,
          canvasSize.height + 80,
        ),
      )
      ..addOval(tub)
      ..addOval(Rect.fromCircle(center: center, radius: saucerRadius));
    canvas.clipPath(path);
  }

  /// Faucet sits just under the cream saucer circle.
  Offset _outletFaucetAnchor(Rect tub) {
    final saucerBottom = _saucerBottomY();
    final y = math.max(
      tub.bottom + tubRadius * 0.06,
      saucerBottom + saucerRadius * 0.06,
    );
    return Offset(tub.center.dx, y);
  }

  /// Tub side rounded; wall side (right/bottom) square so the pipe sits flush.
  RRect _pipeShellRRect(Rect outer, {required bool horizontal}) {
    final r = Radius.circular(_pipeThick);
    if (horizontal) {
      return RRect.fromRectAndCorners(outer, topLeft: r, bottomLeft: r);
    }
    return RRect.fromRectAndCorners(outer, topLeft: r, topRight: r);
  }

  RRect _pipeBoreRRect(Rect bore, {required bool horizontal}) {
    final r = Radius.circular(_pipeThick * 0.55);
    if (horizontal) {
      return RRect.fromRectAndCorners(bore, topLeft: r, bottomLeft: r);
    }
    return RRect.fromRectAndCorners(bore, topLeft: r, topRight: r);
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final tub = _tubRect();
    final cw = canvasSize.width;
    final ch = canvasSize.height;

    _drawOutletAssembly(canvas, tub, cw, ch, canvasSize);
    _drawInletAssembly(canvas, tub, cw, ch, canvasSize);
    _drawTubBack(canvas, tub);
    _drawWater(canvas, tub);
    _drawTubFront(canvas, tub);
    _drawInletFaucet(canvas, tub);
    _drawOutletFaucet(canvas, tub);

    if (inletValveOpen > 0.05) {
      canvas.save();
      _clipExcludeBowl(canvas, canvasSize, tub);
      _redrawPipeFlow(
        canvas,
        tub: tub,
        cw: cw,
        ch: ch,
        horizontal: true,
        flow: inletValveOpen,
        flowAnimPhase: inletPipeFlowPhase * math.pi * 2,
      );
      canvas.restore();
    }
    if (outletValveOpen > 0.05) {
      canvas.save();
      _clipExcludeBowl(canvas, canvasSize, tub);
      _redrawPipeFlow(
        canvas,
        tub: tub,
        cw: cw,
        ch: ch,
        horizontal: false,
        flow: outletValveOpen,
      );
      canvas.restore();
    }

    if (liveInletDrip) {
      _drawLiveInletDrips(
        canvas,
        tub,
        strength: math.max(inletValveOpen, 0.34),
      );
    }
  }

  double _waterSurfaceY(Rect tub) {
    if (waterLevel <= 0.01) {
      return tub.bottom - tub.height * 0.06;
    }
    return tub.bottom - tub.height * waterLevel.clamp(0.0, 1.0);
  }

  void _drawLiveInletDrips(
    Canvas canvas,
    Rect tub, {
    required double strength,
  }) {
    final spout = _inletSpoutEnd;
    if (spout == Offset.zero) return;

    final surfaceY = _waterSurfaceY(tub);
    final fallSpan = math.max(surfaceY - spout.dy, tubRadius * 0.12);
    final flow = strength.clamp(0.0, 1.0);

    canvas.save();
    _clipToBowl(canvas, tub);

    _drawVerticalDripStream(
      canvas,
      spout: spout,
      surfaceY: surfaceY,
      strength: flow,
    );

    const dropCount = 8;
    for (var i = 0; i < dropCount; i++) {
      final phase = (inletDripPhase + i / dropCount) % 1.0;
      final fallT = Curves.easeIn.transform(phase);
      final wobble =
          math.sin((inletDripPhase + i * 0.7) * math.pi * 2) * tubRadius * 0.035;
      final x = spout.dx + wobble;
      final y = math.min(spout.dy + fallSpan * fallT, surfaceY - tubRadius * 0.01);
      final dropR = tubRadius * (0.028 + 0.018 * (1 - phase)) * flow;

      if (phase > 0.04 && phase < 0.94) {
        canvas.drawLine(
          Offset(x, spout.dy + tubRadius * 0.04),
          Offset(x, y - dropR),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _waterHi.withValues(alpha: 0.15 * flow),
                _waterDeep.withValues(alpha: 0.55 * flow),
              ],
            ).createShader(Rect.fromLTWH(x - 2, spout.dy, 4, y - spout.dy))
            ..strokeWidth = (tubRadius * 0.018).clamp(1.2, 2.8)
            ..strokeCap = StrokeCap.round,
        );
      }

      final dropCenter = Offset(x, y);
      canvas.drawOval(
        Rect.fromCenter(
          center: dropCenter,
          width: dropR * 1.35,
          height: dropR * 1.85,
        ),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.35),
            colors: [
              _waterHi.withValues(alpha: 0.95 * flow),
              _waterDeep.withValues(alpha: 0.88 * flow),
              const Color(0xFF0288D1).withValues(alpha: 0.75 * flow),
            ],
          ).createShader(
            Rect.fromCircle(center: dropCenter, radius: dropR * 1.2),
          ),
      );
      canvas.drawCircle(
        dropCenter + Offset(-dropR * 0.35, -dropR * 0.45),
        dropR * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.72 * flow),
      );

      if (phase > 0.88) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, surfaceY + tubRadius * 0.02),
            width: dropR * 2.8,
            height: dropR * 1.1,
          ),
          Paint()
            ..color = _waterHi.withValues(alpha: 0.35 * flow * (1 - phase)),
        );
      }
    }

    canvas.restore();
  }

  void _drawVerticalDripStream(
    Canvas canvas, {
    required Offset spout,
    required double surfaceY,
    required double strength,
  }) {
    final tip = Offset(spout.dx, spout.dy + tubRadius * 0.04);
    final end = Offset(spout.dx, surfaceY - tubRadius * 0.02);
    if (end.dy <= tip.dy + 2) return;

    final streamRect = Rect.fromPoints(tip, end).inflate(tubRadius * 0.08);
    final span = end.dy - tip.dy;

    canvas.drawLine(
      tip,
      end,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _waterHi.withValues(alpha: 0.7 * strength),
            const Color(0xFF29B6F6).withValues(alpha: 0.82 * strength),
            _waterDeep.withValues(alpha: 0.9 * strength),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(streamRect)
        ..strokeWidth = (tubRadius * 0.052 * strength).clamp(2.4, 6.0)
        ..strokeCap = StrokeCap.round,
    );

    final innerW = (tubRadius * 0.028 * strength).clamp(1.2, 3.2);
    canvas.drawLine(
      tip + Offset(innerW * 0.35, 0),
      end + Offset(innerW * 0.35, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * strength)
        ..strokeWidth = innerW
        ..strokeCap = StrokeCap.round,
    );

    const streakCount = 14;
    for (var i = 0; i < streakCount; i++) {
      final t = (inletDripPhase + i / streakCount) % 1.0;
      final y = tip.dy + span * t;
      final wobble = math.sin((inletDripPhase * 2.4 + i) * math.pi * 2) *
          tubRadius *
          0.018;
      canvas.drawCircle(
        Offset(spout.dx + wobble, y),
        tubRadius * (0.016 + (i % 3) * 0.004) * strength,
        Paint()
          ..color = Colors.white.withValues(alpha: (0.35 + (i % 2) * 0.15) * strength),
      );
    }
  }

  void _redrawPipeFlow(
    Canvas canvas, {
    required Rect tub,
    required double cw,
    required double ch,
    required bool horizontal,
    required double flow,
    double? flowAnimPhase,
  }) {
    if (horizontal) {
      final y = _inletValvePos.dy;
      final joinX = tub.right - tub.width * 0.05;
      _drawPipeWaterFlow(
        canvas,
        bore: Rect.fromLTRB(
          joinX,
          y - _pipeThick * 0.7,
          _pipeScreenRight(cw),
          y + _pipeThick * 0.7,
        ),
        horizontal: true,
        flow: flow,
        flowToStart: true,
        flowAnimPhase: flowAnimPhase,
      );
    } else {
      final x = _outletValvePos.dx;
      final joinY = tub.bottom - tub.height * 0.05;
      final pipeBottom = _pipeScreenBottom(ch);
      _drawPipeWaterFlow(
        canvas,
        bore: Rect.fromLTRB(
          x - _pipeThick * 0.68,
          joinY,
          x + _pipeThick * 0.68,
          pipeBottom,
        ),
        horizontal: false,
        flow: flow,
        flowToStart: true,
      );
    }
  }

  void _drawTubBack(Canvas canvas, Rect tub) {
    canvas.drawOval(
      tub,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _tubGlass.withValues(alpha: 0.55),
            _tubGlass.withValues(alpha: 0.28),
          ],
        ).createShader(tub),
    );
    canvas.drawOval(
      tub.deflate(3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawTubFront(Canvas canvas, Rect tub) {
    canvas.drawOval(
      tub,
      Paint()
        ..color = _tubRim.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (tubRadius * 0.045).clamp(2.0, 4.0),
    );
    canvas.drawArc(
      tub.inflate(2),
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawWater(Canvas canvas, Rect tub) {
    if (waterLevel <= 0.01) return;

    final level = waterLevel.clamp(0.0, 1.0);
    final surfaceY = tub.bottom - tub.height * level;
    final waterPath = Path()
      ..addRect(Rect.fromLTRB(tub.left, surfaceY, tub.right, tub.bottom));

    canvas.save();
    _clipToBowl(canvas, tub);

    canvas.drawPath(
      waterPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _waterHi.withValues(alpha: 0.75),
                _waterDeep.withValues(alpha: 0.92),
              ],
            ).createShader(
              Rect.fromLTRB(tub.left, surfaceY, tub.right, tub.bottom),
            ),
    );

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final wavePath = Path();
    const segments = 24;
    final w = tub.width;
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final x = tub.left + w * t;
      final amp = tubRadius * (0.035 + waterAgitation * 0.055);
      final y =
          surfaceY +
          math.sin(t * math.pi * 4 + wavePhase) * amp +
          math.sin(t * math.pi * 7 + wavePhase * 1.3) * amp * 0.55;
      if (i == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);

    for (var b = 0; b < 4; b++) {
      final bx = tub.left + w * (0.2 + b * 0.18);
      final by = surfaceY + tub.height * 0.08 * (b % 2);
      canvas.drawCircle(
        Offset(bx, by),
        tubRadius * 0.025,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }

    canvas.restore();
  }

  void _drawInletAssembly(
    Canvas canvas,
    Rect tub,
    double cw,
    double ch,
    Size canvasSize,
  ) {
    final y = tub.center.dy - tub.height * 0.04;
    final joinX = tub.right - tub.width * 0.05;
    _inletValvePos = Offset(cw - tubRadius * 0.36, y);

    final outer = Rect.fromLTRB(
      joinX,
      y - _pipeThick,
      _pipeScreenRight(cw),
      y + _pipeThick,
    );
    canvas.save();
    _clipExcludeBowl(canvas, canvasSize, tub);
    _drawPipeRun(
      canvas,
      outer: outer,
      horizontal: true,
      flow: inletValveOpen,
      flowToStart: true,
      flowAnimPhase: inletPipeFlowPhase * math.pi * 2,
    );
    canvas.restore();
    _drawWallPlate(canvas, Offset(cw, y), horizontal: true);
    if (inletValveOpen > 0.05) {
      _drawTubJet(
        canvas,
        from: Offset(joinX + tubRadius * 0.02, y),
        to: Offset(tub.right - tub.width * 0.06, y + tubRadius * 0.02),
        strength: inletValveOpen,
      );
    }
  }

  void _drawOutletAssembly(
    Canvas canvas,
    Rect tub,
    double cw,
    double ch,
    Size canvasSize,
  ) {
    final x = tub.center.dx;
    final joinY = tub.bottom - tub.height * 0.05;
    final pipeBottom = _pipeScreenBottom(ch);
    _outletValvePos = _outletFaucetAnchor(tub);

    final outer = Rect.fromLTRB(
      x - _pipeThick,
      joinY,
      x + _pipeThick,
      pipeBottom,
    );
    canvas.save();
    _clipExcludeBowl(canvas, canvasSize, tub);
    _drawPipeRun(
      canvas,
      outer: outer,
      horizontal: false,
      flow: outletValveOpen,
      flowToStart: true,
    );
    canvas.restore();
    _drawWallPlate(canvas, Offset(x, ch), horizontal: false);
    if (outletValveOpen > 0.05) {
      _drawTubJet(
        canvas,
        from: Offset(x, joinY + tubRadius * 0.02),
        to: Offset(x, pipeBottom),
        strength: outletValveOpen,
      );
    }
  }

  void _drawTubJet(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required double strength,
  }) {
    final path = Path()..moveTo(from.dx, from.dy);
    path.quadraticBezierTo(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2,
      to.dx,
      to.dy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _waterHi.withValues(alpha: 0.95 * strength),
            _waterDeep.withValues(alpha: 0.8 * strength),
          ],
        ).createShader(Rect.fromPoints(from, to).inflate(8))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (tubRadius * 0.1 * strength).clamp(4.0, 12.0)
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 5; i++) {
      final t = ((i + 1) / 6 + wavePhase * 0.12) % 1.0;
      final p = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );
      canvas.drawCircle(
        p,
        2.5 + strength * 3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * strength),
      );
    }
  }

  /// [flowToStart]: آب از انتهای دیوار (راست/پایین) به سمت سینی حرکت می‌کند.
  void _drawPipeRun(
    Canvas canvas, {
    required Rect outer,
    required bool horizontal,
    required double flow,
    required bool flowToStart,
    double? flowAnimPhase,
  }) {
    final shell = _pipeShellRRect(outer, horizontal: horizontal);
    canvas.drawRRect(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
          end: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
          colors: const [
            Color(0xFFCFD8DC),
            Color(0xFF90A4AE),
            Color(0xFF455A64),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(outer),
    );

    final highlight = horizontal
        ? Rect.fromLTWH(
            outer.left,
            outer.top + 1.5,
            outer.width,
            _pipeThick * 0.38,
          )
        : Rect.fromLTWH(
            outer.left + 1.5,
            outer.top,
            _pipeThick * 0.38,
            outer.height,
          );
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlight, Radius.circular(_pipeThick * 0.2)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    canvas.drawRRect(
      shell,
      Paint()
        ..color = const Color(0xFF37474F).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final bore = outer.deflate(_pipeThick * 0.28);
    final boreShape = _pipeBoreRRect(bore, horizontal: horizontal);
    canvas.drawRRect(
      boreShape,
      Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.3 + flow * 0.45),
    );

    if (flow > 0.03) {
      canvas.drawRRect(
        _pipeShellRRect(outer.inflate(1.5), horizontal: horizontal),
        Paint()
          ..color = _waterHi.withValues(alpha: 0.5 * flow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      _drawPipeWaterFlow(
        canvas,
        bore: bore,
        horizontal: horizontal,
        flow: flow,
        flowToStart: flowToStart,
        flowAnimPhase: flowAnimPhase,
      );
    }
  }

  void _drawPipeWaterFlow(
    Canvas canvas, {
    required Rect bore,
    required bool horizontal,
    required double flow,
    required bool flowToStart,
    double? flowAnimPhase,
  }) {
    canvas.save();
    canvas.clipRRect(_pipeBoreRRect(bore, horizontal: horizontal));

    final flowColors = [
      _waterHi.withValues(alpha: 0.95 * flow),
      const Color(0xFF4FC3F7).withValues(alpha: 1.0 * flow),
      const Color(0xFF0288D1).withValues(alpha: 1.0 * flow),
    ];
    canvas.drawRect(
      bore,
      Paint()
        ..shader = LinearGradient(
          begin: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
          end: horizontal ? Alignment.centerLeft : Alignment.topCenter,
          colors: flowColors,
        ).createShader(bore),
    );

    final len = horizontal ? bore.width : bore.height;
    final anim = flowAnimPhase ?? wavePhase;
    final travelScale = flowAnimPhase != null
        ? TrayWaterConstants.inletPipeFlowTravelScale
        : 0.35;
    final phase = anim * len * travelScale;
    final bubbleCount = flowAnimPhase != null ? 10 : 16;
    for (var i = 0; i < bubbleCount; i++) {
      final offset = (phase + i * len / bubbleCount) % len;
      late Offset p;
      if (horizontal) {
        final dx = flowToStart ? bore.right - offset : bore.left + offset;
        p = Offset(
          dx,
          bore.center.dy + math.sin(anim * 1.15 + i * 0.6) * 2.0,
        );
      } else {
        final dy = flowToStart ? bore.bottom - offset : bore.top + offset;
        p = Offset(bore.center.dx + math.sin(anim * 3 + i) * 2.5, dy);
      }
      canvas.drawCircle(
        p,
        (_pipeThick * 0.22 + (i % 2) * 1.5) * flow,
        Paint()..color = Colors.white.withValues(alpha: 0.65 * flow),
      );
    }

    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * flow)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    final streakCount = flowAnimPhase != null ? 3 : 5;
    final streakSpan = flowAnimPhase != null ? len * 0.1 : len * 0.18;
    for (var s = 0; s < streakCount; s++) {
      final t = (phase + s * len / streakCount) % len;
      if (horizontal) {
        final x1 = flowToStart ? bore.right - t : bore.left + t;
        final x2 = flowToStart ? x1 - streakSpan : x1 + streakSpan;
        canvas.drawLine(
          Offset(x1, bore.center.dy),
          Offset(x2, bore.center.dy),
          streakPaint,
        );
      } else {
        final y1 = flowToStart ? bore.bottom - t : bore.top + t;
        final y2 = flowToStart ? y1 - streakSpan : y1 + streakSpan;
        canvas.drawLine(
          Offset(bore.center.dx, y1),
          Offset(bore.center.dx, y2),
          streakPaint,
        );
      }
    }

    canvas.restore();
  }

  void _drawWallPlate(Canvas canvas, Offset edge, {required bool horizontal}) {
    final w = tubRadius * 0.36;
    final h = tubRadius * 0.24;
    final rect = horizontal
        ? Rect.fromLTWH(edge.dx - 2, edge.dy - w / 2, h + 2, w)
        : Rect.fromLTWH(edge.dx - w / 2, edge.dy - 2, w, h + 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_chromeHi, _chromeMid, _chromeLo],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(3)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Offset _inletValvePos = Offset.zero;
  Offset _outletValvePos = Offset.zero;
  Offset _inletSpoutEnd = Offset.zero;

  void _drawInletFaucet(Canvas canvas, Rect tub) {
    _inletSpoutEnd = Offset(
      tub.right - tub.width * 0.12,
      _inletValvePos.dy + tubRadius * 0.08,
    );
    _drawFaucet(
      canvas,
      anchor: _inletValvePos,
      open: inletValveOpen,
      flow: _FaucetFlow.left,
      spoutEnd: _inletSpoutEnd,
    );
  }

  void _drawOutletFaucet(Canvas canvas, Rect tub) {
    final joinY = tub.bottom - tub.height * 0.05;
    _drawFaucet(
      canvas,
      anchor: _outletValvePos,
      open: outletValveOpen,
      flow: _FaucetFlow.up,
      spoutEnd: Offset(_outletValvePos.dx, joinY + tubRadius * 0.04),
    );
  }

  void _drawFaucet(
    Canvas canvas, {
    required Offset anchor,
    required double open,
    required _FaucetFlow flow,
    required Offset spoutEnd,
  }) {
    final scale = tubRadius * 0.01;
    final bodyW = 18 * scale;
    final bodyH = 22 * scale;

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);

    if (flow == _FaucetFlow.left) {
      canvas.scale(-1, 1);
    } else {
      canvas.rotate(-math.pi / 2);
    }

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: bodyW, height: bodyH),
      Radius.circular(bodyW * 0.35),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_chromeHi, _chromeMid, _chromeLo],
        ).createShader(bodyRect.outerRect),
    );

    final collar = Rect.fromCenter(
      center: Offset(bodyW * 0.38, 0),
      width: bodyW * 0.55,
      height: bodyH * 0.35,
    );
    canvas.drawOval(collar, Paint()..color = _chromeLo.withValues(alpha: 0.85));

    final handleAngle = open * math.pi / 2;
    canvas.save();
    canvas.translate(-bodyW * 0.05, 0);
    canvas.rotate(handleAngle);
    final handleRect = Rect.fromCenter(
      center: Offset.zero,
      width: bodyH,
      height: bodyH,
    );
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
      ).createShader(handleRect)
      ..strokeWidth = bodyW * 0.14
      ..strokeCap = StrokeCap.round;
    final hl = bodyH * 0.55;
    canvas.drawLine(Offset(-hl, 0), Offset(hl, 0), handlePaint);
    canvas.drawLine(Offset(0, -hl * 0.55), Offset(0, hl * 0.55), handlePaint);
    canvas.drawCircle(
      Offset.zero,
      bodyW * 0.12,
      Paint()..color = const Color(0xFFC62828),
    );
    canvas.restore();

    final spout = Path()
      ..moveTo(bodyW * 0.35, bodyH * 0.15)
      ..quadraticBezierTo(bodyW * 0.75, bodyH * 0.35, bodyW * 0.9, bodyH * 0.55)
      ..lineTo(bodyW * 0.95, bodyH * 0.7);
    canvas.drawPath(
      spout,
      Paint()
        ..color = _chromeMid
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW * 0.22
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(bodyW * 0.95, bodyH * 0.72),
      bodyW * 0.14,
      Paint()
        ..shader = RadialGradient(colors: [_chromeHi, _chromeLo]).createShader(
          Rect.fromCircle(
            center: Offset(bodyW * 0.95, bodyH * 0.72),
            radius: bodyW * 0.14,
          ),
        ),
    );

    canvas.restore();

    if (open > 0.08) {
      _drawWaterStream(canvas, anchor, spoutEnd, open, flow);
    }
  }

  void _drawWaterStream(
    Canvas canvas,
    Offset from,
    Offset to,
    double open,
    _FaucetFlow flow,
  ) {
    final stream = Path()..moveTo(from.dx, from.dy);
    if (flow == _FaucetFlow.left) {
      stream.quadraticBezierTo(
        from.dx - tubRadius * 0.25,
        from.dy + tubRadius * 0.08,
        to.dx,
        to.dy,
      );
    } else {
      stream.quadraticBezierTo(
        from.dx + tubRadius * 0.06,
        from.dy - tubRadius * 0.2,
        to.dx,
        to.dy,
      );
    }

    final streamRect = Rect.fromPoints(from, to).inflate(tubRadius * 0.08);
    canvas.drawPath(
      stream,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _waterHi.withValues(alpha: 0.95 * open),
            const Color(0xFF29B6F6).withValues(alpha: 0.85 * open),
            _waterDeep.withValues(alpha: 0.7 * open),
          ],
        ).createShader(streamRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (tubRadius * 0.09 * open).clamp(3.0, 11.0)
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < 6; i++) {
      final t = ((i + 1) / 7 + wavePhase * 0.15) % 1.0;
      final p = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );
      canvas.drawCircle(
        p,
        2.5 + open * 3,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * open),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrayWaterPainter old) {
    return old.waterLevel != waterLevel ||
        old.wavePhase != wavePhase ||
        old.inletPipeFlowPhase != inletPipeFlowPhase ||
        old.inletValveOpen != inletValveOpen ||
        old.outletValveOpen != outletValveOpen ||
        old.liveInletDrip != liveInletDrip ||
        old.inletDripPhase != inletDripPhase ||
        old.waterAgitation != waterAgitation ||
        old.center != center ||
        old.tubRadius != tubRadius ||
        old.saucerRadius != saucerRadius ||
        old.size != size;
  }
}

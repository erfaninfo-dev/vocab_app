import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tray_prison_painter.dart';

/// Figures of the prison-escape scene: the prisoner behind the bars with
/// one arm reaching through, the barred door, the sleeping guard on a
/// chair and the golden key clipped to his chest pocket.
///
/// All motion is parameterized so the scene widget can drive it from
/// animation controllers without this painter holding any state.
class TrayPrisonFiguresPainter extends CustomPainter {
  TrayPrisonFiguresPainter({
    required this.center,
    required this.sceneRadius,
    required this.idlePhase,
    required this.ambientPhase,
    required this.reachProgress,
    required this.guardWake,
    required this.wakePulse,
    required this.keyGrabProgress,
    required this.escapeProgress,
    required this.gameOverProgress,
    required this.fear,
    required this.celebrate,
  }) : _layout = TrayPrisonLayout(center: center, sceneRadius: sceneRadius);

  final Offset center;
  final double sceneRadius;

  /// Slow 0..1 loop: breathing, blinking, finger stretching, Zzz drift.
  final double idlePhase;

  /// Faster 0..1 loop shared with the environment (key swing).
  final double ambientPhase;

  /// 0..1 — how far the prisoner's hand has traveled toward the key.
  final double reachProgress;

  /// 0..1 — how close the guard is to waking (tension).
  final double guardWake;

  /// 1→0 elastic pulse right after a wrong answer (guard stirs).
  final double wakePulse;

  /// 0..1 — the key slides off the chest pocket into the prisoner's hand.
  final double keyGrabProgress;

  /// 0..1 — door swings open and the prisoner tiptoes out past the guard.
  final double escapeProgress;

  /// 0..1 — guard wakes, gently pulls the hand back and takes the key.
  final double gameOverProgress;

  /// 0..1 prisoner anxiety (drives eyes / brows / trembling).
  final double fear;
  final bool celebrate;

  final TrayPrisonLayout _layout;

  static const _skin = Color(0xFFFFCC80);
  static const _skinDeep = Color(0xFFE0A060);
  static const _suit = Color(0xFFFF8A65);
  static const _suitDark = Color(0xFFE64A19);
  static const _suitStripe = Color(0xFFFFE0B2);
  static const _barColor = Color(0xFF78909C);
  static const _barDark = Color(0xFF455A64);
  static const _guardUniform = Color(0xFF5C6BC0);
  static const _guardMid = Color(0xFF3F51B5);
  static const _guardDark = Color(0xFF3949AB);
  static const _guardPants = Color(0xFF283593);
  static const _keyGold = Color(0xFFFFD54F);
  static const _keyGoldDeep = Color(0xFFFFB300);
  static const _belt = Color(0xFF4E342E);

  double get _s => sceneRadius;

  bool get _keyFullyClipped =>
      gameOverProgress <= 0 && escapeProgress <= 0 && keyGrabProgress <= 0;

  /// Still attached through approach / contact / early unclip.
  /// On GO the key stays clipped until the soft retract beat.
  bool get _keyOnClip =>
      escapeProgress <= 0 &&
      keyGrabProgress < 0.52 &&
      (_go < 0.82 || _go >= 0.93);

  // Key-steal stages (A) — linear keyGrabProgress 0..1
  double get _kg => keyGrabProgress.clamp(0.0, 1.0);
  double get _kgApproach => (_kg / 0.20).clamp(0.0, 1.0);
  double get _kgContact => ((_kg - 0.20) / 0.18).clamp(0.0, 1.0);
  double get _kgUnclip => ((_kg - 0.38) / 0.24).clamp(0.0, 1.0);
  double get _kgSettle => ((_kg - 0.62) / 0.38).clamp(0.0, 1.0);

  // Game-over stages (B) — linear gameOverProgress 0..1
  double get _go => gameOverProgress.clamp(0.0, 1.0);
  double get _goWake =>
      Curves.easeOutCubic.transform((_go / 0.28).clamp(0.0, 1.0));
  double get _goStand => Curves.easeOutBack.transform(
        ((_go - 0.28) / 0.20).clamp(0.0, 1.0),
      );
  double get _goStep => Curves.easeOutCubic.transform(
        ((_go - 0.48) / 0.14).clamp(0.0, 1.0),
      );
  double get _goGrab => Curves.easeOutCubic.transform(
        ((_go - 0.62) / 0.20).clamp(0.0, 1.0),
      );
  double get _goRetract => Curves.easeInOutCubic.transform(
        ((_go - 0.82) / 0.11).clamp(0.0, 1.0),
      );
  double get _goLock => Curves.easeOutBack.transform(
        ((_go - 0.93) / 0.07).clamp(0.0, 1.0),
      );

  // ---------------------------------------------------------------- anchors

  Offset get _prisonerFeet {
    if (escapeProgress <= 0) return _layout.prisonerFeet;
    final walk = Curves.easeInOut.transform(
      ((escapeProgress - 0.35) / 0.65).clamp(0.0, 1.0),
    );
    final startX = _layout.prisonerFeet.dx;
    final endX = center.dx + _s * 1.18;
    final bounce = math.sin(walk * math.pi * 6).abs() * _s * 0.028;
    return Offset(ui.lerpDouble(startX, endX, walk)!, _layout.floorY - bounce);
  }

  /// World-space chest-pocket center (cell-facing side) while seated.
  Offset get _guardChestPocket {
    final seat = _layout.guardSeat;
    final bodyH = _s * 0.38;
    final bodyW = _s * 0.28;
    final bodyCenterY = -bodyH * 0.42;
    return Offset(
      seat.dx - bodyW * 0.24,
      seat.dy + bodyCenterY - bodyH * 0.06,
    );
  }

  Offset get _prisonerShoulder {
    final feet = _layout.prisonerFeet;
    final breathY = math.sin(idlePhase * 2 * math.pi) * _s * 0.006;
    final reachLean = Curves.easeOutCubic.transform(reachProgress.clamp(0, 1));
    return Offset(
      feet.dx + _s * 0.095 + reachLean * _s * 0.012,
      feet.dy - _s * 0.34 + breathY,
    );
  }

  /// Eased reach so each correct word advances the hand with a soft settle.
  double get _reachEased =>
      Curves.easeOutCubic.transform(reachProgress.clamp(0.0, 1.0));

  Offset get _handPos {
    final keyRest = _keyRestPos;
    final shoulder = _prisonerShoulder;
    final aim = Offset(keyRest.dx - _s * 0.01, keyRest.dy + _s * 0.01);
    var t = _reachEased;
    t *= (1 - wakePulse * 0.48);
    // Soft retract only after the grab beat (not during stand/step).
    if (_goRetract > 0) {
      t *= 1 - _goRetract * 0.88;
    } else if (_goGrab > 0) {
      t *= 1 - _goGrab * 0.08;
    }
    final stretch =
        math.sin(idlePhase * 2 * math.pi) * _s * 0.006 * (1 - t);
    final tremble = fear > 0.35
        ? (math.sin(idlePhase * 2 * math.pi * 11) * 0.55 +
                math.sin(idlePhase * 2 * math.pi * 17) * 0.45) *
            _s *
            0.0055 *
            fear
        : 0.0;
    final start = Offset(shoulder.dx + _s * 0.065, shoulder.dy + _s * 0.02);
    final raw = Offset(
      ui.lerpDouble(start.dx, aim.dx, t)! + stretch,
      ui.lerpDouble(start.dy, aim.dy, t)! + tremble,
    );
    final maxLen = _s * 0.39;
    final delta = raw - shoulder;
    final dist = delta.distance;
    if (dist <= maxLen || dist < 0.001) return raw;
    return shoulder + delta * (maxLen / dist);
  }

  /// Natural bent elbow between shoulder and hand.
  Offset get _elbowPos {
    final shoulder = _prisonerShoulder;
    final hand = _handPos;
    final mid = Offset(
      shoulder.dx + (hand.dx - shoulder.dx) * 0.42,
      shoulder.dy + (hand.dy - shoulder.dy) * 0.38,
    );
    final dx = hand.dx - shoulder.dx;
    final dy = hand.dy - shoulder.dy;
    final len = math.sqrt(dx * dx + dy * dy).clamp(1.0, double.infinity);
    final drop = _s * (0.055 + (1 - _reachEased) * 0.02);
    return Offset(mid.dx + (-dy / len) * drop * 0.15, mid.dy + drop);
  }

  /// Rest pose on the clip; swing fades as the steal starts.
  Offset get _keyRestPos {
    final swingAmp = _keyFullyClipped ? 1.0 : (1 - _kgApproach) * 0.35;
    final ang = (math.sin(ambientPhase * 2 * math.pi + 1.3) * 0.55 +
            math.sin(ambientPhase * 2 * math.pi * 2.1) * 0.18) *
        swingAmp;
    return Offset(
      _guardChestPocket.dx - _s * 0.008 + math.sin(ang) * _s * 0.022,
      _guardChestPocket.dy +
          _s * 0.052 +
          (1 - math.cos(ang).abs()) * _s * 0.006,
    );
  }

  /// Staged key pose for steal / escape / GO — no teleports.
  (Offset pos, double angle) get _keyStealPose {
    if (gameOverProgress > 0) {
      if (_goRetract > 0) {
        final back = _goRetract;
        return (Offset.lerp(_handPos, _keyRestPos, back)!, (1 - back) * 0.3);
      }
      return (_keyRestPos, 0.0);
    }
    if (escapeProgress > 0) {
      final feet = _prisonerFeet;
      return (
        Offset(feet.dx + _s * 0.18, feet.dy - _s * 0.42),
        math.sin(escapeProgress * math.pi * 8) * 0.22,
      );
    }

    final rest = _keyRestPos;
    final hand = _handPos;
    if (_kg < 0.20) {
      return (
        rest,
        math.sin(ambientPhase * 2 * math.pi + 1.3) * 0.08 * (1 - _kgApproach),
      );
    }
    if (_kg < 0.38) {
      final n = Curves.easeOutCubic.transform(_kgContact);
      return (Offset.lerp(rest, hand, n * 0.2)!, -n * 0.15);
    }
    if (_kg < 0.52) {
      final u = Curves.easeIn.transform(((_kg - 0.38) / 0.14).clamp(0.0, 1.0));
      return (Offset.lerp(rest, hand, 0.2 + u * 0.38)!, -0.15 - u * 0.35);
    }
    final s = Curves.easeOutBack.transform(_kgSettle);
    final mid = Offset.lerp(rest, hand, 0.58)!;
    final pos = Offset.lerp(mid, hand, s)!;
    final lift = math.sin(s.clamp(0.0, 1.0) * math.pi) * _s * 0.045;
    final angle = (1 - s) * -0.55 + math.sin(s * math.pi) * 0.25;
    return (pos + Offset(0, -lift), angle);
  }

  // ------------------------------------------------------------------ paint

  @override
  void paint(Canvas canvas, Size canvasSize) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: sceneRadius)),
    );

    final escaping = escapeProgress > 0;
    final doorOpen = escaping
        ? Curves.easeOutBack.transform(
            (escapeProgress / 0.4).clamp(0.0, 1.0),
          )
        : 0.0;

    if (!escaping || escapeProgress < 0.42) {
      _paintPrisoner(canvas, inCell: true);
    }
    _paintBarsAndDoor(canvas, doorOpen: doorOpen);
    if (!escaping) _paintArmAndHand(canvas);
    _paintGuard(canvas);
    // Free-flying key after unclip pop (and during escape / GO return).
    if (!_keyOnClip) _paintKey(canvas);
    if (escaping && escapeProgress >= 0.42) {
      _paintPrisoner(canvas, inCell: false);
    }
    if (_goLock > 0) _paintLock(canvas);

    canvas.restore();
  }

  // ------------------------------------------------------------------- bars

  void _paintBarsAndDoor(Canvas canvas, {required double doorOpen}) {
    final top = _layout.barsTop;
    final bottom = _layout.floorY;
    final barW = math.max(2.4, _s * 0.045);
    final rail = Paint()
      ..color = _barDark
      ..strokeWidth = barW * 0.9
      ..strokeCap = StrokeCap.round;
    final bar = Paint()
      ..color = _barColor
      ..strokeWidth = barW
      ..strokeCap = StrokeCap.round;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = barW * 0.28
      ..strokeCap = StrokeCap.round;

    const wallBars = 3;
    final wallSpan = _layout.doorLeft - _layout.cellLeft;
    for (var i = 0; i <= wallBars; i++) {
      final x = _layout.cellLeft + wallSpan * i / wallBars;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), bar);
      canvas.drawLine(
        Offset(x - barW * 0.22, top + _s * 0.02),
        Offset(x - barW * 0.22, bottom - _s * 0.02),
        highlight,
      );
    }
    canvas.drawLine(
      Offset(_layout.cellLeft, top),
      Offset(_layout.doorLeft, top),
      rail,
    );
    canvas.drawLine(
      Offset(_layout.cellLeft, bottom - barW),
      Offset(_layout.doorLeft, bottom - barW),
      rail,
    );

    final doorW = _layout.doorRight - _layout.doorLeft;
    canvas.save();
    canvas.translate(_layout.doorLeft, 0);
    canvas.scale(1 - doorOpen * 0.82, 1.0);
    canvas.translate(-_layout.doorLeft, 0);

    const doorBars = 3;
    for (var i = 0; i <= doorBars; i++) {
      final x = _layout.doorLeft + doorW * i / doorBars;
      canvas.drawLine(Offset(x, _layout.doorTop), Offset(x, bottom), bar);
      canvas.drawLine(
        Offset(x - barW * 0.22, _layout.doorTop + _s * 0.02),
        Offset(x - barW * 0.22, bottom - _s * 0.02),
        highlight,
      );
    }
    canvas.drawLine(
      Offset(_layout.doorLeft, _layout.doorTop),
      Offset(_layout.doorRight, _layout.doorTop),
      rail,
    );
    canvas.drawLine(
      Offset(_layout.doorLeft, bottom - barW),
      Offset(_layout.doorRight, bottom - barW),
      rail,
    );
    final lockPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          _layout.doorRight - doorW * 0.16,
          (bottom + _layout.doorTop) / 2,
        ),
        width: _s * 0.09,
        height: _s * 0.13,
      ),
      Radius.circular(_s * 0.02),
    );
    canvas.drawRRect(lockPlate, Paint()..color = _barDark);
    canvas.drawRRect(
      lockPlate,
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(
        _layout.doorRight - doorW * 0.16,
        (bottom + _layout.doorTop) / 2,
      ),
      _s * 0.018,
      Paint()..color = const Color(0xFFB0BEC5),
    );
    canvas.restore();
  }

  // --------------------------------------------------------------- prisoner

  void _paintPrisoner(Canvas canvas, {required bool inCell}) {
    final feet = _prisonerFeet;
    final breathWave = math.sin(idlePhase * 2 * math.pi);
    final breath = 1 + breathWave * 0.018;
    final bodyH = _s * 0.36 * breath;
    final bodyW = _s * (0.23 + breathWave.abs() * 0.008);
    final reachLean = _reachEased * _s * 0.018;
    final bodyCenter = Offset(
      feet.dx + reachLean,
      feet.dy - bodyH * 0.52 - _s * 0.04,
    );
    final headR = _s * 0.11;
    final headCenter = Offset(
      bodyCenter.dx + reachLean * 0.35,
      bodyCenter.dy - bodyH * 0.52 - headR * 0.62 + breathWave * _s * 0.004,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(feet.dx, feet.dy + _s * 0.01),
        width: bodyW * 1.2,
        height: _s * 0.042,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    _paintPrisonerLeg(
      canvas,
      hip: Offset(bodyCenter.dx - bodyW * 0.22, bodyCenter.dy + bodyH * 0.28),
      foot: Offset(feet.dx - bodyW * 0.26, feet.dy),
    );
    _paintPrisonerLeg(
      canvas,
      hip: Offset(bodyCenter.dx + bodyW * 0.22, bodyCenter.dy + bodyH * 0.28),
      foot: Offset(feet.dx + bodyW * 0.26, feet.dy),
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: bodyW, height: bodyH),
      Radius.circular(bodyW * 0.36),
    );
    canvas.drawRRect(
      torso,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_suit, _suitDark],
        ).createShader(torso.outerRect),
    );
    // Soft belly highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx - bodyW * 0.08, bodyCenter.dy),
        width: bodyW * 0.55,
        height: bodyH * 0.55,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
    for (var i = 0; i < 5; i++) {
      final y = bodyCenter.dy - bodyH * 0.32 + i * bodyH * 0.155;
      canvas.drawLine(
        Offset(bodyCenter.dx - bodyW * 0.34, y),
        Offset(bodyCenter.dx + bodyW * 0.34, y),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.38)
          ..strokeWidth = _s * 0.015
          ..strokeCap = StrokeCap.round,
      );
    }
    // Collar V.
    final collar = Path()
      ..moveTo(bodyCenter.dx - bodyW * 0.28, bodyCenter.dy - bodyH * 0.42)
      ..lineTo(bodyCenter.dx, bodyCenter.dy - bodyH * 0.22)
      ..lineTo(bodyCenter.dx + bodyW * 0.28, bodyCenter.dy - bodyH * 0.42);
    canvas.drawPath(
      collar,
      Paint()
        ..color = _suitDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * 0.02
        ..strokeJoin = StrokeJoin.round,
    );
    // Chest number patch.
    final patch = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bodyCenter.dx + bodyW * 0.02, bodyCenter.dy - bodyH * 0.02),
        width: bodyW * 0.4,
        height: bodyH * 0.24,
      ),
      Radius.circular(_s * 0.012),
    );
    canvas.drawRRect(patch, Paint()..color = _suitStripe);
    canvas.drawRRect(
      patch,
      Paint()
        ..color = _suitDark.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Tiny stitch marks on the patch.
    for (final dx in const [-0.1, 0.0, 0.1]) {
      canvas.drawLine(
        Offset(bodyCenter.dx + bodyW * dx, bodyCenter.dy - bodyH * 0.08),
        Offset(bodyCenter.dx + bodyW * dx, bodyCenter.dy + bodyH * 0.04),
        Paint()
          ..color = _suitDark.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
    }

    // Free left arm with sleeve + cuff + hand.
    final leftShoulder =
        Offset(bodyCenter.dx - bodyW * 0.42, bodyCenter.dy - bodyH * 0.22);
    final leftElbow =
        Offset(bodyCenter.dx - bodyW * 0.54, bodyCenter.dy + bodyH * 0.02);
    final leftHand =
        Offset(bodyCenter.dx - bodyW * 0.48, bodyCenter.dy + bodyH * 0.22);
    final sleevePaint = Paint()
      ..color = _suit
      ..strokeWidth = _s * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(leftShoulder, leftElbow, sleevePaint);
    canvas.drawLine(
      leftElbow,
      leftHand,
      Paint()
        ..color = _skin
        ..strokeWidth = _s * 0.038
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(leftHand, _s * 0.03, Paint()..color = _skin);
    canvas.drawCircle(
      leftElbow,
      _s * 0.028,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * 0.012,
    );

    if (!inCell) {
      final sway = math.sin(escapeProgress * math.pi * 8) * _s * 0.016;
      final rs =
          Offset(bodyCenter.dx + bodyW * 0.42, bodyCenter.dy - bodyH * 0.18);
      final rh = Offset(
        bodyCenter.dx + bodyW * 0.58 + sway,
        bodyCenter.dy + bodyH * 0.1,
      );
      canvas.drawLine(rs, rh, sleevePaint);
      canvas.drawCircle(rh, _s * 0.03, Paint()..color = _skin);
    }

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy + headR * 0.88),
          width: headR * 0.72,
          height: headR * 0.38,
        ),
        Radius.circular(headR * 0.2),
      ),
      Paint()..color = _skin,
    );

    _paintPrisonerHead(canvas, headCenter, headR);
  }

  void _paintPrisonerLeg(
    Canvas canvas, {
    required Offset hip,
    required Offset foot,
  }) {
    final knee = Offset(
      (hip.dx + foot.dx) / 2,
      (hip.dy + foot.dy) / 2 + _s * 0.012,
    );
    canvas.drawLine(
      hip,
      knee,
      Paint()
        ..color = _suitDark
        ..strokeWidth = _s * 0.052
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      knee,
      foot,
      Paint()
        ..color = _suit
        ..strokeWidth = _s * 0.044
        ..strokeCap = StrokeCap.round,
    );
    // Pant cuff stripe.
    canvas.drawCircle(
      Offset(foot.dx, foot.dy - _s * 0.028),
      _s * 0.022,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * 0.01,
    );
    // Shoe + sole.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(foot.dx + _s * 0.014, foot.dy - _s * 0.01),
          width: _s * 0.078,
          height: _s * 0.034,
        ),
        Radius.circular(_s * 0.012),
      ),
      Paint()..color = const Color(0xFF4E342E),
    );
    canvas.drawLine(
      Offset(foot.dx - _s * 0.02, foot.dy + _s * 0.004),
      Offset(foot.dx + _s * 0.048, foot.dy + _s * 0.004),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = _s * 0.012
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintPrisonerHead(Canvas canvas, Offset c, double r) {
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + side * r * 0.92, c.dy + r * 0.05),
          width: r * 0.28,
          height: r * 0.38,
        ),
        Paint()..color = _skin,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + side * r * 0.92, c.dy + r * 0.05),
          width: r * 0.12,
          height: r * 0.18,
        ),
        Paint()..color = const Color(0xFFFFAB91).withValues(alpha: 0.5),
      );
    }

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [_skin, _skinDeep],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = _skinDeep.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    for (final side in const [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + side * r * 0.48, c.dy + r * 0.2),
        r * 0.18,
        Paint()..color = const Color(0xFFFF8A65).withValues(alpha: 0.42),
      );
    }

    // Beanie with band + fold.
    final beanie = Path()
      ..moveTo(c.dx - r * 0.98, c.dy - r * 0.08)
      ..quadraticBezierTo(c.dx, c.dy - r * 1.62, c.dx + r * 0.98, c.dy - r * 0.08)
      ..close();
    canvas.drawPath(
      beanie,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_suitDark, _suit],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.4)),
    );
    canvas.drawLine(
      Offset(c.dx - r * 0.92, c.dy - r * 0.06),
      Offset(c.dx + r * 0.92, c.dy - r * 0.06),
      Paint()
        ..color = _suitStripe
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(c.dx - r * 0.55, c.dy - r * 0.55),
      Offset(c.dx + r * 0.55, c.dy - r * 0.55),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );
    final hair = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - r * 0.55, c.dy - r * 0.05),
      Offset(c.dx - r * 0.62, c.dy + r * 0.12),
      hair,
    );
    canvas.drawLine(
      Offset(c.dx + r * 0.55, c.dy - r * 0.05),
      Offset(c.dx + r * 0.62, c.dy + r * 0.12),
      hair,
    );

    final blink = _blinkAmount(offsetSeed: 0.0);
    final eyeOpen = celebrate ? 1.0 : (1 - blink);
    final look = _s *
        0.005 *
        (1 + math.sin(idlePhase * 2 * math.pi * 2)) *
        (fear + 0.3);
    for (final side in const [-1.0, 1.0]) {
      final eye = Offset(c.dx + side * r * 0.34 + look, c.dy - r * 0.02);
      final eyeW = r * (0.17 + fear * 0.05);
      final eyeH = r * 0.2 * eyeOpen * (1 + fear * 0.3);
      canvas.drawArc(
        Rect.fromCenter(center: eye, width: eyeW * 2.3, height: r * 0.22),
        math.pi + 0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..color = _skinDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.04,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: eye,
          width: eyeW * 2.15,
          height: math.max(1.5, eyeH * 2.05),
        ),
        Paint()..color = Colors.white,
      );
      final iris = eye + Offset(look * 0.35, r * 0.02);
      canvas.drawCircle(
        iris,
        math.max(1.1, eyeH * 0.72),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawCircle(
        iris + Offset(-r * 0.03, -r * 0.03),
        math.max(0.6, eyeH * 0.28),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.2),
        width: r * 0.22,
        height: r * 0.18,
      ),
      Paint()..color = const Color(0xFFFFB74D),
    );
    canvas.drawCircle(
      Offset(c.dx - r * 0.04, c.dy + r * 0.16),
      r * 0.04,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    if (fear > 0.2) {
      final brow = Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round;
      for (final side in const [-1.0, 1.0]) {
        final bx = c.dx + side * r * 0.34;
        final by = c.dy - r * 0.34 - fear * r * 0.1;
        canvas.drawLine(
          Offset(bx - r * 0.14, by + side * fear * r * 0.06),
          Offset(bx + r * 0.14, by - side * fear * r * 0.04),
          brow,
        );
      }
      if (fear > 0.7) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + r * 0.72, c.dy + r * 0.05),
            width: r * 0.12,
            height: r * 0.2,
          ),
          Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.85),
        );
      }
    } else {
      final brow = Paint()
        ..color = const Color(0xFF6D4C41).withValues(alpha: 0.7)
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round;
      for (final side in const [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(c.dx + side * r * 0.22, c.dy - r * 0.28),
          Offset(c.dx + side * r * 0.46, c.dy - r * 0.26),
          brow,
        );
      }
    }

    final mouth = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (celebrate || (reachProgress > 0.5 && fear < 0.4)) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.4),
          width: r * 0.58,
          height: r * 0.42,
        ),
        0.2,
        math.pi - 0.4,
        false,
        mouth,
      );
    } else if (fear > 0.65 || gameOverProgress > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.44),
          width: r * 0.24,
          height: r * 0.28,
        ),
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.46),
          width: r * 0.14,
          height: r * 0.14,
        ),
        Paint()..color = const Color(0xFFE57373),
      );
    } else {
      canvas.drawLine(
        Offset(c.dx - r * 0.16, c.dy + r * 0.46),
        Offset(c.dx + r * 0.16, c.dy + r * 0.46),
        mouth,
      );
    }
  }

  void _paintArmAndHand(Canvas canvas) {
    final shoulder = _prisonerShoulder;
    final hand = _handPos;
    final elbow = _elbowPos;
    final grasp = keyGrabProgress > 0
        ? (0.3 +
                _kgApproach * 0.25 +
                _kgContact * 0.35 +
                _kgUnclip * 0.1)
            .clamp(0.0, 1.0)
        : (_reachEased * 0.75 + (fear > 0.5 ? 0.15 : 0)).clamp(0.0, 1.0);

    canvas.drawLine(
      shoulder + const Offset(1.8, 2.2),
      elbow + const Offset(1.8, 2.2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = _s * 0.058
        ..strokeCap = StrokeCap.round,
    );

    final sleeve = Paint()
      ..color = _suit
      ..strokeWidth = _s * 0.054
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(shoulder, elbow, sleeve);
    // Cloth crease at the elbow bend.
    canvas.drawCircle(
      elbow,
      _s * 0.032,
      Paint()
        ..color = _suitDark.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * 0.014,
    );
    canvas.drawCircle(
      elbow,
      _s * 0.03,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * 0.01,
    );
    canvas.drawLine(
      elbow,
      hand,
      Paint()
        ..color = _skin
        ..strokeWidth = _s * 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(shoulder, _s * 0.028, Paint()..color = _suit);
    canvas.drawCircle(
      shoulder + Offset(-_s * 0.008, -_s * 0.006),
      _s * 0.01,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    canvas.drawCircle(hand, _s * 0.035, Paint()..color = _skin);
    canvas.drawCircle(
      hand + Offset(-_s * 0.01, -_s * 0.008),
      _s * 0.012,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    final fingerWiggle = math.sin(idlePhase * 2 * math.pi * 2.4) * 0.5 + 0.5;
    final finger = Paint()
      ..color = _skin
      ..strokeWidth = _s * 0.014
      ..strokeCap = StrokeCap.round;
    final towardKey = (_keyRestPos - hand);
    final baseAng = towardKey.distance > 0.001
        ? math.atan2(towardKey.dy, towardKey.dx)
        : 0.0;
    // Fingers fan open when far, curl toward the key as grasp grows.
    for (var i = -1; i <= 2; i++) {
      final fan = ui.lerpDouble(0.42, 0.16, grasp)!;
      final a = baseAng + (i - 0.5) * fan;
      final curl = grasp * 0.55;
      final len = _s *
          (0.02 +
              fingerWiggle * 0.008 * (1 - grasp) +
              (i == 0 || i == 1 ? 0.008 : 0) +
              grasp * 0.01);
      final tip = Offset(
        hand.dx + math.cos(a) * len,
        hand.dy + math.sin(a) * len + curl * _s * 0.008,
      );
      // Two-segment finger for a softer curl.
      final knuckle = Offset(
        hand.dx + math.cos(a) * len * 0.55,
        hand.dy + math.sin(a) * len * 0.55,
      );
      canvas.drawLine(hand, knuckle, finger);
      canvas.drawLine(
        knuckle,
        tip + Offset(math.sin(a) * curl * _s * 0.01, curl * _s * 0.012),
        finger,
      );
    }
    // Thumb opposite the grasp.
    final thumbAng = baseAng - 0.95 + grasp * 0.35;
    canvas.drawLine(
      hand,
      Offset(
        hand.dx + math.cos(thumbAng) * _s * 0.028,
        hand.dy + math.sin(thumbAng) * _s * 0.028,
      ),
      finger..strokeWidth = _s * 0.016,
    );
  }

  // ------------------------------------------------------------------ guard

  void _paintGuard(Canvas canvas) {
    final seat = _layout.guardSeat;
    final wake = guardWake.clamp(0.0, 1.0);
    // Deep sleep → light → half-awake → alert (non-linear for readable stages).
    final deep = (1 - (wake / 0.28).clamp(0.0, 1.0));
    final lightSleep = ((wake - 0.18) / 0.32).clamp(0.0, 1.0);
    final halfAwake = ((wake - 0.45) / 0.3).clamp(0.0, 1.0);
    final alert = ((wake - 0.72) / 0.28).clamp(0.0, 1.0);

    final snore =
        math.sin(idlePhase * 2 * math.pi) * (0.028 * deep + 0.012 * (1 - deep));
    final rock = snore * (1 - halfAwake) * (1 - wakePulse.clamp(0, 1) * 0.5);
    final breath =
        1 + math.sin(idlePhase * 2 * math.pi + 0.6) * (0.028 * deep + 0.014);
    // Wrong-answer stir: sharp torso jolt that settles with elastic pulse.
    final stir = wakePulse * 0.22;

    // GO stages: wake → stand → step (sequenced, short overlap only).
    final stand = gameOverProgress > 0 ? _goStand : 0.0;
    final upright = gameOverProgress > 0
        ? _goWake
        : Curves.easeInOutCubic.transform(
            (lightSleep * 0.35 + halfAwake * 0.4 + alert * 0.25).clamp(0.0, 1.0),
          );
    final slump = (1 - upright) * 0.38 - stir * 0.55 * (gameOverProgress > 0 ? 0.0 : 1.0);

    canvas.save();
    canvas.translate(seat.dx, seat.dy);
    _paintChair(canvas);
    canvas.restore();

    final stepAmount = gameOverProgress > 0 ? _goStep : 0.0;
    final stepX = -stepAmount * _s * 0.22;
    final riseY = -stand * _s * 0.16;

    canvas.save();
    canvas.translate(seat.dx + stepX, seat.dy + riseY);
    canvas.rotate(rock * (1 - stand) + stir * 0.35 * (1 - stand));

    final bodyW = _s * 0.28;
    final bodyH = _s * 0.38 * breath;
    final bodyCenter = Offset(0, -bodyH * 0.42 - stand * _s * 0.02);
    canvas.save();
    canvas.rotate(-slump * 0.5);

    _paintGuardLegs(
      canvas,
      bodyW: bodyW,
      bodyH: bodyH,
      stand: stand,
      seat: seat,
      riseY: riseY,
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: bodyW, height: bodyH),
      Radius.circular(bodyW * 0.42),
    );
    canvas.drawRRect(
      torso,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_guardUniform, _guardMid, _guardDark],
        ).createShader(torso.outerRect),
    );
    // Lapel / button placket.
    canvas.drawLine(
      Offset(0, bodyCenter.dy - bodyH * 0.35),
      Offset(0, bodyCenter.dy + bodyH * 0.2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = _s * 0.012,
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(0, bodyCenter.dy - bodyH * 0.22 + i * bodyH * 0.16),
        _s * 0.012,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
    // Shoulder epaulettes.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(side * bodyW * 0.42, bodyCenter.dy - bodyH * 0.38),
            width: _s * 0.055,
            height: _s * 0.028,
          ),
          Radius.circular(_s * 0.008),
        ),
        Paint()..color = const Color(0xFFFFCA28),
      );
    }
    // Badge on the far side of the chest.
    canvas.drawCircle(
      Offset(bodyW * 0.26, bodyCenter.dy - bodyH * 0.14),
      _s * 0.028,
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawCircle(
      Offset(bodyW * 0.26, bodyCenter.dy - bodyH * 0.14),
      _s * 0.014,
      Paint()..color = _guardDark,
    );

    // Belt + buckle (no key here — key is on the chest pocket).
    canvas.drawLine(
      Offset(-bodyW * 0.5, bodyCenter.dy + bodyH * 0.28),
      Offset(bodyW * 0.5, bodyCenter.dy + bodyH * 0.28),
      Paint()
        ..color = _belt
        ..strokeWidth = _s * 0.036
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, bodyCenter.dy + bodyH * 0.28),
          width: _s * 0.05,
          height: _s * 0.04,
        ),
        Radius.circular(_s * 0.006),
      ),
      Paint()..color = const Color(0xFFFFB300),
    );

    // Chest pocket (cell-facing). Key stays here through contact/unclip stretch.
    if (escapeProgress <= 0 && (_go < 0.82 || _go >= 0.93)) {
      final pocketCenter =
          Offset(-bodyW * 0.24, bodyCenter.dy - bodyH * 0.06);
      final pocket = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pocketCenter,
          width: _s * 0.095,
          height: _s * 0.11,
        ),
        Radius.circular(_s * 0.014),
      );
      canvas.drawRRect(
        pocket,
        Paint()..color = _guardDark.withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        pocket,
        Paint()
          ..color = const Color(0xFF1A237E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s * 0.01,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: pocketCenter,
            width: _s * 0.078,
            height: _s * 0.09,
          ),
          Radius.circular(_s * 0.01),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      final flapCenter =
          Offset(pocketCenter.dx, pocketCenter.dy - _s * 0.042);
      final flap = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: flapCenter,
          width: _s * 0.1,
          height: _s * 0.034,
        ),
        Radius.circular(_s * 0.008),
      );
      canvas.drawRRect(flap, Paint()..color = _guardMid);
      canvas.drawRRect(
        flap,
        Paint()
          ..color = const Color(0xFF1A237E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final clip = Offset(flapCenter.dx - _s * 0.012, flapCenter.dy + _s * 0.008);
      canvas.drawCircle(clip, _s * 0.012, Paint()..color = const Color(0xFFFFB300));
      canvas.drawCircle(clip, _s * 0.005, Paint()..color = _guardDark);

      if (_keyOnClip) {
        final handLocal = Offset(
          _handPos.dx - (seat.dx + stepX),
          _handPos.dy - (seat.dy + riseY),
        );
        final swingAmp = _keyFullyClipped ? 1.0 : (1 - _kgApproach) * 0.35;
        final ang = (math.sin(ambientPhase * 2 * math.pi + 1.3) * 0.55 +
                math.sin(ambientPhase * 2 * math.pi * 2.1) * 0.18) *
            swingAmp;
        final restLocal = Offset(
          pocketCenter.dx - _s * 0.008 + math.sin(ang) * _s * 0.022,
          pocketCenter.dy +
              _s * 0.052 +
              (1 - math.cos(ang).abs()) * _s * 0.006,
        );

        late final Offset keyLocal;
        late final double keyAng;
        if (_kg < 0.20) {
          keyLocal = restLocal;
          keyAng = ang * 0.85;
        } else if (_kg < 0.38) {
          final n = Curves.easeOutCubic.transform(_kgContact);
          keyLocal = Offset.lerp(restLocal, handLocal, n * 0.2)!;
          keyAng = -n * 0.15;
        } else {
          final u =
              Curves.easeIn.transform(((_kg - 0.38) / 0.14).clamp(0.0, 1.0));
          keyLocal = Offset.lerp(restLocal, handLocal, 0.2 + u * 0.38)!;
          keyAng = -0.15 - u * 0.35;
        }

        final taut = (_kgContact * 0.4 + _kgUnclip * 0.6).clamp(0.0, 1.0);
        canvas.drawLine(
          clip,
          Offset(keyLocal.dx, keyLocal.dy - _s * 0.028),
          Paint()
            ..color = Color.lerp(
              const Color(0xFFB0BEC5),
              const Color(0xFFFFECB3),
              taut,
            )!
            ..strokeWidth = _s * (0.012 + taut * 0.006)
            ..strokeCap = StrokeCap.round,
        );
        for (var i = 0; i < 3; i++) {
          final t = (i + 1) / 4;
          final bead = Offset.lerp(
            clip,
            Offset(keyLocal.dx, keyLocal.dy - _s * 0.028),
            t,
          )!;
          canvas.drawCircle(
            bead,
            _s * 0.008,
            Paint()..color = const Color(0xFFCFD8DC),
          );
        }
        _paintKeyGlyph(
          canvas,
          localPos: keyLocal,
          angle: keyAng,
          inPocket: true,
        );
      }
    }

    _paintGuardArms(
      canvas,
      bodyW: bodyW,
      bodyH: bodyH,
      bodyCenter: bodyCenter,
      seat: seat,
      stepX: stepX,
      riseY: riseY,
    );

    _paintGuardHead(
      canvas,
      Offset(0, bodyCenter.dy - bodyH * 0.52 - _s * 0.08),
      slump: slump,
    );
    canvas.restore();
    canvas.restore();

    if (guardWake < 0.35 && gameOverProgress <= 0) {
      _paintZzz(canvas);
    } else if (guardWake >= 0.35 && gameOverProgress <= 0) {
      _paintWakeAlert(canvas);
    }
  }

  void _paintGuardLegs(
    Canvas canvas, {
    required double bodyW,
    required double bodyH,
    required double stand,
    required Offset seat,
    required double riseY,
  }) {
    final pant = Paint()
      ..color = _guardPants
      ..strokeWidth = _s * 0.058
      ..strokeCap = StrokeCap.round;
    final boot = Paint()..color = const Color(0xFF3E2723);

    if (stand > 0.2) {
      final floorLocal = _layout.floorY - (seat.dy + riseY);
      for (final side in const [-1.0, 1.0]) {
        final hip = Offset(side * bodyW * 0.16, bodyH * 0.08);
        final foot = Offset(side * bodyW * 0.2, floorLocal);
        final knee = Offset(
          (hip.dx + foot.dx) / 2,
          (hip.dy + foot.dy) / 2,
        );
        canvas.drawLine(hip, knee, pant);
        canvas.drawLine(
          knee,
          foot,
          Paint()
            ..color = _guardDark
            ..strokeWidth = _s * 0.05
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(foot.dx + side * _s * 0.01, foot.dy - _s * 0.01),
              width: _s * 0.07,
              height: _s * 0.03,
            ),
            Radius.circular(_s * 0.01),
          ),
          boot,
        );
      }
    } else {
      final floorLocal = _layout.floorY - seat.dy;
      final leftHip = Offset(-bodyW * 0.08, bodyH * 0.06);
      final rightHip = Offset(bodyW * 0.1, bodyH * 0.06);
      final leftFoot = Offset(-bodyW * 0.85, floorLocal);
      final rightFoot = Offset(-bodyW * 0.55, floorLocal);
      canvas.drawLine(leftHip, leftFoot, pant);
      canvas.drawLine(rightHip, rightFoot, pant);
      for (final foot in [leftFoot, rightFoot]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(foot.dx - _s * 0.01, foot.dy - _s * 0.008),
              width: _s * 0.08,
              height: _s * 0.03,
            ),
            Radius.circular(_s * 0.01),
          ),
          boot,
        );
      }
    }
  }

  void _paintGuardArms(
    Canvas canvas, {
    required double bodyW,
    required double bodyH,
    required Offset bodyCenter,
    required Offset seat,
    required double stepX,
    required double riseY,
  }) {
    final armPaint = Paint()
      ..color = _guardDark
      ..strokeWidth = _s * 0.05
      ..strokeCap = StrokeCap.round;

    if (_goGrab > 0) {
      final grab = _goGrab;
      final wristWorld = _handPos;
      final handTarget = Offset(
        ui.lerpDouble(-bodyW * 0.4, wristWorld.dx - (seat.dx + stepX), grab)!,
        ui.lerpDouble(
          bodyCenter.dy + bodyH * 0.05,
          wristWorld.dy - (seat.dy + riseY),
          grab,
        )!,
      );
      final shoulder = Offset(-bodyW * 0.35, bodyCenter.dy - bodyH * 0.12);
      final elbow = Offset(
        (shoulder.dx + handTarget.dx) / 2 - _s * 0.025,
        math.max(shoulder.dy, handTarget.dy) + _s * 0.04 * (1 - grab * 0.3),
      );
      canvas.drawLine(shoulder, elbow, armPaint);
      canvas.drawLine(
        elbow,
        handTarget,
        Paint()
          ..color = _skin
          ..strokeWidth = _s * 0.04
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(handTarget, _s * 0.04, Paint()..color = _skin);
      if (grab > 0.45) {
        canvas.drawCircle(
          handTarget + Offset(-_s * 0.022, _s * 0.012),
          _s * 0.018,
          Paint()..color = _skin,
        );
        canvas.drawCircle(
          handTarget + Offset(_s * 0.022, _s * 0.012),
          _s * 0.018,
          Paint()..color = _skin,
        );
      }
      if (grab > 0.65) {
        canvas.drawCircle(
          handTarget,
          _s * 0.06,
          Paint()
            ..color = _skin.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s * 0.018,
        );
      }
    } else {
      final scratching =
          (wakePulse > 0.2 && guardWake > 0.25 && guardWake < 0.7) ||
          (guardWake >= 0.4 && guardWake < 0.65 && idlePhase % 1 < 0.18);
      if (scratching) {
        canvas.drawLine(
          Offset(-bodyW * 0.28, bodyCenter.dy),
          Offset(bodyW * 0.12, bodyCenter.dy - bodyH * 0.9),
          armPaint,
        );
        canvas.drawCircle(
          Offset(bodyW * 0.12, bodyCenter.dy - bodyH * 0.9),
          _s * 0.028,
          Paint()..color = _skin,
        );
      } else if (guardWake >= 0.55) {
        canvas.drawLine(
          Offset(-bodyW * 0.4, bodyCenter.dy - bodyH * 0.05),
          Offset(-bodyW * 0.7, bodyCenter.dy + bodyH * 0.25),
          armPaint,
        );
        canvas.drawCircle(
          Offset(-bodyW * 0.7, bodyCenter.dy + bodyH * 0.25),
          _s * 0.028,
          Paint()..color = _skin,
        );
        canvas.drawLine(
          Offset(bodyW * 0.35, bodyCenter.dy),
          Offset(bodyW * 0.55, bodyCenter.dy + bodyH * 0.2),
          armPaint,
        );
        canvas.drawCircle(
          Offset(bodyW * 0.55, bodyCenter.dy + bodyH * 0.2),
          _s * 0.028,
          Paint()..color = _skin,
        );
      } else {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(0, bodyCenter.dy + bodyH * 0.06),
            width: bodyW * 1.0,
            height: bodyH * 0.48,
          ),
          0.2,
          math.pi - 0.4,
          false,
          armPaint..style = PaintingStyle.stroke,
        );
        armPaint.style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(-bodyW * 0.42, bodyCenter.dy + bodyH * 0.22),
          _s * 0.028,
          Paint()..color = _skin,
        );
        canvas.drawCircle(
          Offset(bodyW * 0.42, bodyCenter.dy + bodyH * 0.22),
          _s * 0.028,
          Paint()..color = _skin,
        );
      }
    }
  }

  void _paintWakeAlert(Canvas canvas) {
    final seat = _layout.guardSeat;
    final t = ((guardWake - 0.35) / 0.65).clamp(0.0, 1.0);
    final pulse = 0.65 + 0.35 * math.sin(idlePhase * 2 * math.pi * 3);
    final style = TextStyle(
      color: const Color(0xFFFFCA28).withValues(alpha: 0.85 * t * pulse),
      fontSize: _s * (0.12 + t * 0.06),
      fontWeight: FontWeight.w900,
      height: 1,
    );
    final tp = TextPainter(
      text: TextSpan(text: '!', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(seat.dx + _s * 0.14, seat.dy - _s * 0.78 - t * _s * 0.06),
    );
  }

  void _paintChair(Canvas canvas) {
    final w = _s * 0.34;
    final h = _s * 0.05;
    final chair = Paint()..color = const Color(0xFF6D4C41);
    final woodDark = Paint()..color = const Color(0xFF5D4037);

    // Seat cushion.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, h), width: w, height: h),
        Radius.circular(h * 0.4),
      ),
      chair,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, h - _s * 0.01), width: w * 0.85, height: h * 0.45),
        Radius.circular(h * 0.2),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    final leg = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = _s * 0.035
      ..strokeCap = StrokeCap.round;
    final legDrop = _layout.floorY - _layout.guardSeat.dy;
    canvas.drawLine(Offset(-w * 0.38, h), Offset(-w * 0.42, legDrop), leg);
    canvas.drawLine(Offset(w * 0.38, h), Offset(w * 0.42, legDrop), leg);
    // Backrest with slat detail.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.46, -_s * 0.16),
          width: _s * 0.05,
          height: _s * 0.36,
        ),
        Radius.circular(_s * 0.02),
      ),
      chair,
    );
    for (var i = 0; i < 3; i++) {
      final y = -_s * 0.28 + i * _s * 0.1;
      canvas.drawLine(
        Offset(w * 0.42, y),
        Offset(w * 0.5, y),
        woodDark..strokeWidth = 1.2,
      );
    }
    // Armrest.
    canvas.drawLine(
      Offset(-w * 0.35, -_s * 0.02),
      Offset(-w * 0.55, -_s * 0.12),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = _s * 0.03
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintGuardHead(Canvas canvas, Offset c, {required double slump}) {
    final r = _s * 0.115;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final nod =
        math.sin(idlePhase * 2 * math.pi + 1.1) * 0.05 * (1 - guardWake);
    canvas.rotate(slump * 0.9 + nod);

    // Ears under the cap.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * r * 0.9, r * 0.08),
          width: r * 0.26,
          height: r * 0.34,
        ),
        Paint()..color = _skin,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [_skin, _skinDeep],
          stops: const [0.55, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );

    // Cap with badge.
    final cap = Paint()..color = _guardDark;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 1.04),
      math.pi + 0.15,
      math.pi - 0.3,
      true,
      cap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-r * 0.78, -r * 0.28),
          width: r * 0.8,
          height: r * 0.24,
        ),
        Radius.circular(r * 0.1),
      ),
      cap,
    );
    canvas.drawLine(
      Offset(-r * 0.7, -r * 0.05),
      Offset(r * 0.7, -r * 0.05),
      Paint()
        ..color = const Color(0xFFFFCA28)
        ..strokeWidth = r * 0.08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(0, -r * 0.55),
      r * 0.14,
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawCircle(
      Offset(0, -r * 0.55),
      r * 0.06,
      Paint()..color = _guardDark,
    );

    // Sideburns / short hair.
    final hair = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(side * r * 0.7, -r * 0.05),
        Offset(side * r * 0.78, r * 0.25),
        hair,
      );
    }

    final peek = wakePulse * 0.65;
    // Staged lids: shut → slits → half → open (plus stir peek).
    final openAmount = gameOverProgress > 0
        ? _goWake.clamp(0.15, 1.0)
        : (guardWake <= 0.05
              ? peek * 0.25
              : Curves.easeInOut.transform(
                  ((guardWake - 0.05) / 0.85).clamp(0.0, 1.0),
                ) *
                  0.92 +
                  peek * 0.2)
            .clamp(0.0, 1.0);
    final eyePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Head stir on wrong answer.
    if (wakePulse > 0.15 && gameOverProgress <= 0) {
      canvas.translate(wakePulse * r * 0.08, -wakePulse * r * 0.06);
    }
    for (final side in const [-1.0, 1.0]) {
      final eye = Offset(side * r * -0.32 - r * 0.08, -r * 0.02);
      if (openAmount < 0.1) {
        canvas.drawArc(
          Rect.fromCenter(center: eye, width: r * 0.44, height: r * 0.3),
          0.2,
          math.pi - 0.4,
          false,
          eyePaint,
        );
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(eye.dx + i * r * 0.1, eye.dy + r * 0.04),
            Offset(eye.dx + i * r * 0.1, eye.dy + r * 0.12),
            Paint()
              ..color = const Color(0xFF37474F)
              ..strokeWidth = r * 0.04
              ..strokeCap = StrokeCap.round,
          );
        }
      } else if (openAmount < 0.45) {
        // Squinting / half-awake slit.
        canvas.drawOval(
          Rect.fromCenter(
            center: eye,
            width: r * 0.42,
            height: r * 0.22 * openAmount.clamp(0.35, 1.0),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawLine(
          Offset(eye.dx - r * 0.16, eye.dy),
          Offset(eye.dx + r * 0.16, eye.dy),
          Paint()
            ..color = const Color(0xFF263238)
            ..strokeWidth = r * 0.07
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: eye,
            width: r * 0.4,
            height: r * 0.52 * openAmount,
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          eye + Offset(0, r * 0.02),
          r * 0.12 * openAmount.clamp(0.4, 1.0),
          Paint()..color = const Color(0xFF1B5E20),
        );
        canvas.drawCircle(
          eye + Offset(-r * 0.04, -r * 0.02),
          r * 0.045 * openAmount.clamp(0.4, 1.0),
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        if (gameOverProgress > 0 || openAmount > 0.75) {
          canvas.drawLine(
            Offset(eye.dx - r * 0.18, eye.dy - r * 0.28),
            Offset(eye.dx + r * 0.16, eye.dy - r * 0.18),
            Paint()
              ..color = const Color(0xFF37474F)
              ..strokeWidth = r * 0.1
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Nose.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.18, r * 0.18),
        width: r * 0.2,
        height: r * 0.16,
      ),
      Paint()..color = const Color(0xFFFFB74D),
    );

    // Mustache.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-r * 0.28, r * 0.34),
        width: r * 0.72,
        height: r * 0.34,
      ),
      math.pi + 0.3,
      math.pi - 0.6,
      false,
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (gameOverProgress > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-r * 0.22, r * 0.62),
          width: r * 0.32,
          height: r * 0.38,
        ),
        Paint()..color = const Color(0xFF4E342E),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-r * 0.22, r * 0.64),
          width: r * 0.2,
          height: r * 0.22,
        ),
        Paint()..color = const Color(0xFFE57373),
      );
    } else if (guardWake < 0.55) {
      final puff = 0.5 + 0.5 * math.sin(idlePhase * 2 * math.pi + 0.6);
      canvas.drawCircle(
        Offset(-r * 0.28, r * 0.6),
        r * (0.08 + puff * 0.05),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08,
      );
    } else {
      canvas.drawLine(
        Offset(-r * 0.42, r * 0.58),
        Offset(-r * 0.1, r * 0.55),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = r * 0.09
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  void _paintZzz(Canvas canvas) {
    final seat = _layout.guardSeat;
    final fade = (1 - guardWake / 0.55).clamp(0.0, 1.0);
    final drift = idlePhase;
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.7 * fade * (1 - drift)),
      fontSize: _s * (0.1 + drift * 0.05),
      fontWeight: FontWeight.w800,
    );
    final tp = TextPainter(
      text: TextSpan(text: 'z', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final base = Offset(
      seat.dx + _s * 0.16 + drift * _s * 0.1,
      seat.dy - _s * 0.72 - drift * _s * 0.22,
    );
    tp.paint(canvas, base);
    final tp2 = TextPainter(
      text: TextSpan(
        text: 'Z',
        style: style.copyWith(
          fontSize: _s * (0.07 + drift * 0.04),
          color: Colors.white.withValues(alpha: 0.5 * fade * (1 - drift)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, base + Offset(_s * 0.1, -_s * 0.1));
  }

  // -------------------------------------------------------------------- key

  void _paintKey(Canvas canvas) {
    final pose = _keyStealPose;
    _paintKeyGlyph(
      canvas,
      localPos: pose.$1,
      angle: pose.$2,
      inPocket: false,
    );
  }

  void _paintKeyGlyph(
    Canvas canvas, {
    required Offset localPos,
    required double angle,
    required bool inPocket,
  }) {
    canvas.save();
    canvas.translate(localPos.dx, localPos.dy);
    canvas.rotate(angle);

    final gold = Paint()
      ..shader = RadialGradient(
        colors: [_keyGold, _keyGoldDeep],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: _s * 0.08));
    final goldStroke = Paint()
      ..color = _keyGold
      ..strokeWidth = _s * (inPocket ? 0.02 : 0.024)
      ..style = PaintingStyle.stroke;
    final ringR = _s * (inPocket ? 0.026 : 0.036);

    // Outer ring + inner hole.
    canvas.drawCircle(Offset(0, -ringR), ringR, goldStroke);
    canvas.drawCircle(
      Offset(0, -ringR),
      ringR * 0.45,
      Paint()..color = const Color(0xFF455A64).withValues(alpha: 0.35),
    );
    // Specular glint on the ring.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, -ringR), radius: ringR * 0.85),
      -1.2,
      0.9,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = _s * 0.01
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Full hanging key (clipped to chest pocket) or the grabbed key.
    canvas.drawLine(
      Offset.zero,
      Offset(0, _s * (inPocket ? 0.07 : 0.08)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_keyGold, _keyGoldDeep],
        ).createShader(Rect.fromLTWH(-2, 0, 4, _s * 0.08))
        ..strokeWidth = _s * (inPocket ? 0.02 : 0.024)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -_s * 0.004,
          _s * (inPocket ? 0.042 : 0.05),
          _s * 0.032,
          _s * 0.018,
        ),
        Radius.circular(_s * 0.004),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -_s * 0.004,
          _s * (inPocket ? 0.064 : 0.074),
          _s * 0.024,
          _s * 0.016,
        ),
        Radius.circular(_s * 0.004),
      ),
      gold,
    );
    canvas.drawCircle(
      Offset(-ringR * 0.35, -ringR * 1.25),
      _s * 0.012,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  void _paintLock(Canvas canvas) {
    final t = _goLock;
    final scale = Curves.easeOutBack.transform(t);
    final pos = Offset(
      _guardChestPocket.dx + _s * 0.2,
      _guardChestPocket.dy + _s * 0.12,
    );
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);
    final body = Paint()..color = const Color(0xFF90A4AE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: _s * 0.08,
          height: _s * 0.065,
        ),
        Radius.circular(_s * 0.014),
      ),
      body,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -_s * 0.032),
        width: _s * 0.05,
        height: _s * 0.05,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF78909C)
        ..strokeWidth = _s * 0.016
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  double _blinkAmount({required double offsetSeed}) {
    final t = (idlePhase + offsetSeed) % 1.0;
    if (t < 0.92) return 0;
    return math.sin((t - 0.92) / 0.08 * math.pi);
  }

  @override
  bool shouldRepaint(TrayPrisonFiguresPainter oldDelegate) =>
      oldDelegate.idlePhase != idlePhase ||
      oldDelegate.ambientPhase != ambientPhase ||
      oldDelegate.reachProgress != reachProgress ||
      oldDelegate.guardWake != guardWake ||
      oldDelegate.wakePulse != wakePulse ||
      oldDelegate.keyGrabProgress != keyGrabProgress ||
      oldDelegate.escapeProgress != escapeProgress ||
      oldDelegate.gameOverProgress != gameOverProgress ||
      oldDelegate.fear != fear ||
      oldDelegate.celebrate != celebrate;
}

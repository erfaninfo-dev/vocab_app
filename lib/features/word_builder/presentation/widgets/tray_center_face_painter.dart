import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/tray_water_constants.dart';

/// Animated, detailed face in the letter-tray center.
class TrayCenterFaceLayer extends StatefulWidget {
  const TrayCenterFaceLayer({
    super.key,
    required this.size,
    required this.center,
    required this.radius,
    this.mood = TrayFaceMood.neutral,
    this.waterSubmerge = 0,
    this.waterSurfaceY,
    this.reactionPulse = 0,
    this.wrongAnswerCount = 0,
    this.solvedInLevel = 0,
    this.targetsInLevel = 1,
  });

  final Size size;
  final Offset center;
  final double radius;
  final TrayFaceMood mood;
  final double waterSubmerge;

  /// Screen Y of tub water surface (same coords as [center]).
  final double? waterSurfaceY;
  final double reactionPulse;
  final int wrongAnswerCount;
  final int solvedInLevel;
  final int targetsInLevel;

  @override
  State<TrayCenterFaceLayer> createState() => _TrayCenterFaceLayerState();
}

class _TrayCenterFaceLayerState extends State<TrayCenterFaceLayer>
    with TickerProviderStateMixin {
  late final AnimationController _life;
  late final AnimationController _blink;
  late final AnimationController _sweatFlow;
  final _rng = math.Random();
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _sweatFlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _scheduleBlink();
  }

  void _scheduleBlink({int delayMs = 0}) {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(
      Duration(milliseconds: delayMs + 2200 + _rng.nextInt(2800)),
      _runBlink,
    );
  }

  bool get _keepEyesOpen =>
      widget.mood == TrayFaceMood.stressed ||
      widget.mood == TrayFaceMood.panic ||
      widget.waterSubmerge > 0.001;

  @override
  void didUpdateWidget(covariant TrayCenterFaceLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood && widget.mood == TrayFaceMood.happy) {
      _scheduleBlink(delayMs: 1200);
    }
  }

  Future<void> _runBlink() async {
    if (!mounted) return;
    if (_keepEyesOpen) {
      _scheduleBlink(delayMs: 2800);
      return;
    }
    await _blink.forward();
    if (!mounted) return;
    await _blink.reverse();
    if (mounted) _scheduleBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _life.dispose();
    _blink.dispose();
    _sweatFlow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_life, _blink, _sweatFlow]),
      builder: (context, _) {
        final isDead = widget.mood == TrayFaceMood.dead;
        final keepEyesOpen = _keepEyesOpen;
        final t = isDead ? 0.0 : _life.value;
        return CustomPaint(
          size: widget.size,
          painter: TrayCenterFacePainter(
            center: widget.center,
            radius: widget.radius,
            breath: t,
            sweatFlowPhase: isDead ? 0 : _sweatFlow.value,
            blink: isDead || keepEyesOpen ? 0 : _blink.value,
            sway: isDead ? 0 : math.sin(t * math.pi * 2) * 0.018,
            lookX: isDead ? 0 : math.sin(t * math.pi * 2 * 0.45) * 0.22,
            lookY: isDead ? 0 : math.cos(t * math.pi * 2 * 0.38) * 0.1,
            mood: widget.mood,
            waterSubmerge: widget.waterSubmerge,
            waterSurfaceY: widget.waterSurfaceY,
            reactionPulse: widget.reactionPulse,
            wrongAnswerCount: widget.wrongAnswerCount,
            solvedInLevel: widget.solvedInLevel,
            targetsInLevel: widget.targetsInLevel,
          ),
        );
      },
    );
  }
}

class TrayCenterFacePainter extends CustomPainter {
  TrayCenterFacePainter({
    required this.center,
    required this.radius,
    this.breath = 0,
    this.sweatFlowPhase = 0,
    this.blink = 0,
    this.sway = 0,
    this.lookX = 0,
    this.lookY = 0,
    this.mood = TrayFaceMood.neutral,
    this.waterSubmerge = 0,
    this.waterSurfaceY,
    this.reactionPulse = 0,
    this.wrongAnswerCount = 0,
    this.solvedInLevel = 0,
    this.targetsInLevel = 1,
  });

  final Offset center;
  final double radius;
  final double breath;
  final double sweatFlowPhase;
  final double blink;
  final double sway;
  final double lookX;
  final double lookY;
  final TrayFaceMood mood;
  final double waterSubmerge;
  final double? waterSurfaceY;
  final double reactionPulse;
  final int wrongAnswerCount;
  final int solvedInLevel;
  final int targetsInLevel;

  double get _exaggeration => 1.0 + reactionPulse.clamp(0.0, 1.0) * 0.65;

  bool get _isWorried {
    if (mood == TrayFaceMood.dead || mood == TrayFaceMood.happy) {
      return false;
    }
    if (mood == TrayFaceMood.panic) return true;
    return _waterStep >= 1;
  }

  /// گام ۰…۵ — هر پلهٔ ۰.۲ آب (اشتباه، چکهٔ آرام، …).
  int get _waterStep {
    if (waterSubmerge < TrayWaterConstants.waterPerWrong - 0.001) {
      return 0;
    }
    return (waterSubmerge / TrayWaterConstants.waterPerWrong).ceil().clamp(
      1,
      TrayWaterConstants.maxWrongBeforeOverflow,
    );
  }

  /// 0…1 — لبخند نرم و چشم‌های باز در شروع مرحله (قبل از پلهٔ اول استرس).
  double get _cheerLevel {
    if (mood == TrayFaceMood.dead || mood == TrayFaceMood.panic) return 0;
    if (mood == TrayFaceMood.happy) return 1.0;
    if (_waterStep >= 1) return 0;
    if (waterSubmerge <= 0.001) return 0.64;
    final t = (waterSubmerge / TrayWaterConstants.waterPerWrong).clamp(
      0.0,
      1.0,
    );
    return 0.64 * (1 - t);
  }

  /// 0…1 بر اساس سطح آب.
  double get _waterProgress => waterSubmerge.clamp(0.0, 1.0);

  /// سطح احساس ۰ (خنثی) … ۶ (پانیک) مطابق اینفوگرافیک.
  int get _emotionLevel {
    if (mood == TrayFaceMood.happy) return 0;
    if (mood == TrayFaceMood.dead) return 6;
    if (mood == TrayFaceMood.panic) return 6;
    if (!_isWorried) return 0;
    return _waterStep.clamp(1, 5);
  }

  double get _emotionT =>
      Curves.easeInOut.transform((_emotionLevel / 6).clamp(0.0, 1.0));

  /// 0…1 — باز شدن چشم/دهان با ترس؛ از اولین پلهٔ آب (۰.۲) تا پر شدن.
  double get _fearOpen {
    if (mood == TrayFaceMood.panic || mood == TrayFaceMood.dead) return 1.0;
    if (!_isWorried) return 0.0;
    final w = waterSubmerge.clamp(0.0, 1.0);
    if (w < TrayWaterConstants.waterPerWrong) return 0.0;
    return Curves.easeInOut.transform(
      ((w - TrayWaterConstants.waterPerWrong) /
              (1.0 - TrayWaterConstants.waterPerWrong))
          .clamp(0.0, 1.0),
    );
  }

  /// 0…~0.9 — شدت باز بودن چشم (سقف برای جلوگیری از اغراق).
  double get _eyeOpenAmount {
    if (mood == TrayFaceMood.panic || mood == TrayFaceMood.dead) return 0.88;
    if (!_isWorried) return 0.0;
    final fear = _fearOpen;
    final t = _emotionT;
    return (fear * 0.78 + t * 0.2).clamp(0.0, 0.9);
  }

  /// دهان از همان منطق چشم، کمی عقب‌تر و با سقف پایین‌تر.
  double get _mouthOpenAmount {
    final eyes = _eyeOpenAmount;
    if (eyes <= 0.03) return 0.0;
    final linked = Curves.easeInOut.transform(
      ((eyes - 0.06) / 0.84).clamp(0.0, 1.0),
    );
    return (linked * 0.68).clamp(0.0, 0.68);
  }

  double get _levelFlush {
    const flushes = [0.0, 0.2, 0.4, 0.6, 0.8, 0.95, 1.0];
    return flushes[_emotionLevel.clamp(0, 6)];
  }

  /// 0…1 — شدت استرس برای سایر افکت‌ها.
  double get _stressLevel {
    final moodBoost = switch (mood) {
      TrayFaceMood.panic => 0.12,
      TrayFaceMood.stressed => 0.04,
      TrayFaceMood.dead => 0.0,
      _ => 0.0,
    };
    if (_isWorried) {
      return (_waterProgress + moodBoost + reactionPulse * 0.16).clamp(
        0.0,
        1.0,
      );
    }
    return (_waterProgress * 0.4 + moodBoost).clamp(0.0, 1.0);
  }

  /// 0…1 — هر کلمهٔ درست لبخند را پررنگ‌تر می‌کند.
  double get _joyLevel {
    final fromSolved = targetsInLevel > 0
        ? solvedInLevel / targetsInLevel
        : 0.0;
    final moodBoost = mood == TrayFaceMood.happy ? 0.42 : 0.0;
    return (fromSolved * 0.7 + moodBoost + _cheerLevel + reactionPulse * 0.32)
        .clamp(0.0, 1.0);
  }

  static const Color _skinHi = Color(0xFFFFF0E3);
  static const Color _skinMid = Color(0xFFF2C9A5);
  static const Color _skinWarm = Color(0xFFE8B88A);
  static const Color _skinLo = Color(0xFFD9A67E);
  static const Color _skinDeep = Color(0xFFC48960);
  static const Color _flushHi = Color(0xFFFFCDD2);
  static const Color _flushMid = Color(0xFFFF8A80);
  static const Color _flushWarm = Color(0xFFEF5350);
  static const Color _flushLo = Color(0xFFE53935);
  static const Color _flushDeep = Color(0xFFC62828);

  /// 0…1 — قرمزی پله‌ای؛ happy = پوست عادی.
  double get _flushLevel {
    if (mood == TrayFaceMood.happy) return 0.0;
    if (!_isWorried && _cheerLevel > 0.2) return 0.0;
    if (!_isWorried && mood == TrayFaceMood.neutral) return 0.0;
    if (mood == TrayFaceMood.dead) return 0.88;
    if (mood == TrayFaceMood.panic) return 1.0;
    return (_levelFlush + reactionPulse * 0.06).clamp(0.0, 1.0);
  }

  double get _flushT => Curves.easeIn.transform(_flushLevel);

  Color _skinBlend(Color neutral, Color flushed) =>
      Color.lerp(neutral, flushed, _flushT)!;

  Color get _toneHi => _skinBlend(_skinHi, _flushHi);
  Color get _toneMid => _skinBlend(_skinMid, _flushMid);
  Color get _toneWarm => _skinBlend(_skinWarm, _flushWarm);
  Color get _toneLo => _skinBlend(_skinLo, _flushLo);
  Color get _toneDeep => _skinBlend(_skinDeep, _flushDeep);
  static const Color _hairDark = Color(0xFF2C1810);
  static const Color _hair = Color(0xFF3E2723);
  static const Color _hairHi = Color(0xFF5D4037);
  static const Color _brow = Color(0xFF3E2723);
  static const Color _iris = Color(0xFF4E342E);
  static const Color _irisRing = Color(0xFF6D4C41);
  static const Color _lipTop = Color(0xFFE8A4A4);
  static const Color _lipMid = Color(0xFFD46A6A);
  static const Color _lipBot = Color(0xFFB71C1C);
  static const Color _cheek = Color(0xFFFF8A80);

  /// Soft oval head — wide forehead, gently tapered chin (still fully round).
  Rect _faceOvalRect(Offset c, double r) {
    return Rect.fromCenter(
      center: c + Offset(0, r * 0.02),
      width: r * 1.9,
      height: r * 2.02,
    );
  }

  Path _faceOutline(Offset c, double r) => Path()..addOval(_faceOvalRect(c, r));

  Rect _faceBounds(Offset c, double r) => _faceOvalRect(c, r);

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 10) return;

    final breathScale = 1 + breath * 0.028;
    final r = radius * breathScale;
    final c = center + Offset(sway * r * 2.2, breath * r * 0.012);
    final face = _faceOutline(c, r);
    final bounds = _faceBounds(c, r);
    final oval = _faceOvalRect(c, r);

    _drawEars(canvas, c, r, oval);
    canvas.save();
    canvas.clipPath(face);

    _drawHair(canvas, c, r, bounds, oval);
    _drawFaceBase(canvas, c, r, face, bounds);
    _drawFaceShading(canvas, c, r, bounds);
    _drawStressFlush(canvas, bounds);

    if (mood == TrayFaceMood.dead) {
      _drawDeadFace(canvas, c, r);
      if (waterSubmerge > 0.05) {
        _drawWaterOverlay(canvas, c, r);
      }
    } else {
      _drawCheeks(canvas, c, r);
      if (_isWorried && mood != TrayFaceMood.happy) {
        _drawForeheadCreases(canvas, c, r);
      }
      _drawEyeRegionShadows(canvas, c, r);
      _drawBrows(canvas, c, r);
      _drawEyes(canvas, c, r);
      _drawNose(canvas, c, r);
      _drawMouth(canvas, c, r);
      if (waterSubmerge > 0.08) {
        _drawWaterOverlay(canvas, c, r);
      }
      if (_emotionLevel >= 1) {
        _drawStressMarks(canvas, c, r);
      }
      if (mood == TrayFaceMood.happy || _cheerLevel > 0.42) {
        _drawHappySparkles(canvas, c, r);
      }
    }

    canvas.restore();

    canvas.drawPath(
      face,
      Paint()
        ..color = _brow.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.03).clamp(1.2, 2.5),
    );
  }

  void _drawHair(Canvas canvas, Offset c, double r, Rect bounds, Rect oval) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(oval.center.dx, oval.top + r * 0.12),
        width: oval.width * 1.02,
        height: r * 0.5,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.09),
    );

    final cap = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(oval.center.dx, oval.top + r * 0.22),
          width: oval.width * 1.05,
          height: r * 1.35,
        ),
        math.pi * 1.06,
        math.pi * 0.9,
      );
    canvas.drawPath(
      cap,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_hairHi, _hair, _hairDark],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(bounds),
    );

    final strand = Paint()
      ..color = _hair.withValues(alpha: 0.55)
      ..strokeWidth = r * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final strands = [
      (
        Offset(c.dx - r * 0.42, c.dy - r * 0.62),
        Offset(c.dx - r * 0.18, c.dy - r * 0.78),
        Offset(c.dx + r * 0.02, c.dy - r * 0.68),
      ),
      (
        Offset(c.dx - r * 0.15, c.dy - r * 0.72),
        Offset(c.dx + r * 0.05, c.dy - r * 0.82),
        Offset(c.dx + r * 0.28, c.dy - r * 0.7),
      ),
      (
        Offset(c.dx + r * 0.35, c.dy - r * 0.58),
        Offset(c.dx + r * 0.22, c.dy - r * 0.72),
        Offset(c.dx + r * 0.08, c.dy - r * 0.64),
      ),
      (
        Offset(c.dx - r * 0.28, c.dy - r * 0.55),
        Offset(c.dx - r * 0.08, c.dy - r * 0.62),
        Offset(c.dx + r * 0.12, c.dy - r * 0.58),
      ),
    ];
    for (final s in strands) {
      canvas.drawPath(
        Path()
          ..moveTo(s.$1.dx, s.$1.dy)
          ..quadraticBezierTo(s.$2.dx, s.$2.dy, s.$3.dx, s.$3.dy),
        strand,
      );
    }
  }

  void _drawFaceBase(
    Canvas canvas,
    Offset c,
    double r,
    Path face,
    Rect bounds,
  ) {
    canvas.drawPath(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.42),
          radius: 1.25,
          colors: [_toneHi, _toneMid, _toneWarm, _toneLo, _toneDeep],
          stops: const [0.0, 0.32, 0.58, 0.82, 1.0],
        ).createShader(bounds),
    );
  }

  void _drawStressFlush(Canvas canvas, Rect bounds) {
    final t = _flushT;
    if (t < 0.04) return;
    canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.08),
          radius: 1.15,
          colors: [
            const Color(0xFFFF5252).withValues(alpha: 0.1 * t),
            const Color(0xFFE53935).withValues(alpha: 0.22 * t),
            const Color(0xFFB71C1C).withValues(alpha: 0.38 * t),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
    );
    if (t > 0.65) {
      canvas.drawOval(
        bounds.deflate(bounds.width * 0.08),
        Paint()
          ..color = const Color(
            0xFFD32F2F,
          ).withValues(alpha: (t - 0.65) * 0.55),
      );
    }
  }

  void _drawFaceShading(Canvas canvas, Offset c, double r, Rect bounds) {
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, -r * 0.34),
        width: r * 0.38,
        height: r * 0.2,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1 * (1 - _flushT * 0.75)),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(r * 0.32, r * 0.22),
        width: r * 0.38,
        height: r * 0.5,
      ),
      Paint()
        ..color = _toneDeep.withValues(alpha: 0.18 + _flushT * 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-r * 0.32, r * 0.22),
        width: r * 0.38,
        height: r * 0.5,
      ),
      Paint()
        ..color = _toneDeep.withValues(alpha: 0.16 + _flushT * 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.52),
        width: r * 0.55,
        height: r * 0.28,
      ),
      Paint()
        ..color = _toneDeep.withValues(alpha: 0.14 + _flushT * 0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1),
    );
  }

  void _drawEars(Canvas canvas, Offset c, double r, Rect oval) {
    for (final side in [-1.0, 1.0]) {
      final earC = Offset(
        oval.center.dx + side * oval.width * 0.48,
        oval.center.dy + r * 0.02,
      );
      canvas.drawOval(
        Rect.fromCenter(center: earC, width: r * 0.22, height: r * 0.3),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_toneMid, _toneWarm, _toneLo],
          ).createShader(Rect.fromCircle(center: earC, radius: r * 0.16)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: earC + Offset(-side * r * 0.03, r * 0.02),
          width: r * 0.12,
          height: r * 0.18,
        ),
        Paint()..color = _toneLo.withValues(alpha: 0.5),
      );
    }
  }

  void _drawCheeks(Canvas canvas, Offset c, double r) {
    final blushAlpha = mood == TrayFaceMood.happy
        ? 0.5 + breath * 0.12 + reactionPulse * 0.2
        : _cheerLevel > 0.35
        ? 0.36 + _cheerLevel * 0.28 + breath * 0.12
        : _isWorried
        ? 0.28 + _stressLevel * 0.52 + waterSubmerge * 0.18 + breath * 0.06
        : 0.22 + breath * 0.1;
    final blush = Paint()
      ..color = _cheek.withValues(alpha: blushAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.11);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: c + Offset(side * r * 0.4, r * 0.16),
          width: r * 0.3,
          height: r * 0.17,
        ),
        blush,
      );
    }
  }

  void _drawEyeRegionShadows(Canvas canvas, Offset c, double r) {
    for (final side in [-1.0, 1.0]) {
      final eyeC = c + Offset(side * r * 0.27, -r * 0.02);
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeC + Offset(0, r * 0.05),
          width: r * 0.32,
          height: r * 0.18,
        ),
        Paint()
          ..color = _toneLo.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
      );
      canvas.drawOval(
        Rect.fromCenter(center: eyeC, width: r * 0.27, height: r * 0.16),
        Paint()
          ..color = _toneDeep.withValues(alpha: 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
      );
    }
  }

  void _drawDeadFace(Canvas canvas, Offset c, double r) {
    final line = Paint()
      ..color = _brow.withValues(alpha: 0.88)
      ..strokeWidth = (r * 0.024).clamp(1.8, 3.4)
      ..strokeCap = StrokeCap.round;

    for (final side in [-1.0, 1.0]) {
      final eyeC = c + Offset(side * r * 0.27, -r * 0.02);
      final w = r * 0.1;
      canvas.drawLine(
        eyeC + Offset(-w, -w * 0.65),
        eyeC + Offset(w, w * 0.65),
        line,
      );
      canvas.drawLine(
        eyeC + Offset(-w, w * 0.65),
        eyeC + Offset(w, -w * 0.65),
        line,
      );
    }

    for (final side in [-1.0, 1.0]) {
      final eyeX = c.dx + side * r * 0.27;
      final browY = c.dy - r * 0.11;
      final path = Path()
        ..moveTo(eyeX - side * r * 0.12, browY)
        ..quadraticBezierTo(
          eyeX,
          browY + r * 0.008,
          eyeX + side * r * 0.14,
          browY + r * 0.012,
        );
      canvas.drawPath(path, line..style = PaintingStyle.stroke);
    }

    final mouthC = c + Offset(0, r * 0.36);
    canvas.drawOval(
      Rect.fromCenter(center: mouthC, width: r * 0.22, height: r * 0.15),
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: mouthC + Offset(0, r * 0.03),
        width: r * 0.13,
        height: r * 0.075,
      ),
      Paint()..color = const Color(0xFF1A0E0C),
    );
  }

  void _drawForeheadCreases(Canvas canvas, Offset c, double r) {
    final level = _emotionLevel;
    if (level < 1) return;
    final count = level >= 4 ? 3 : (level >= 2 ? 2 : 1);
    final t = _emotionT;
    final paint = Paint()
      ..color = _brow.withValues(alpha: 0.2 + t * 0.42)
      ..strokeWidth = (0.85 + t * 0.9).clamp(0.8, 2.2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < count; i++) {
      final y = c.dy - r * (0.2 + i * 0.028);
      final halfW = r * (0.08 + i * 0.012 + t * 0.02);
      final path = Path()
        ..moveTo(c.dx - halfW, y)
        ..quadraticBezierTo(c.dx, y - r * (0.006 + t * 0.012), c.dx + halfW, y);
      canvas.drawPath(path, paint);
    }
  }

  void _drawStressMarks(Canvas canvas, Offset c, double r) {
    final level = _emotionLevel;
    final t = _emotionT;
    final ex = _exaggeration;

    final specs = <({Offset o, double w, double h, double travel})>[];
    if (level >= 1) {
      specs.add((
        o: Offset(-r * 0.46, -r * 0.22),
        w: 0.06,
        h: 0.095,
        travel: 0.42,
      ));
    }
    if (level >= 2) {
      specs.add((
        o: Offset(r * 0.44, -r * 0.2),
        w: 0.065,
        h: 0.1,
        travel: 0.44,
      ));
    }
    if (level >= 3) {
      specs.addAll([
        (o: Offset(-r * 0.38, -r * 0.12), w: 0.07, h: 0.11, travel: 0.48),
        (o: Offset(r * 0.5, -r * 0.26), w: 0.075, h: 0.115, travel: 0.5),
      ]);
    }
    if (level >= 4) {
      specs.addAll([
        (o: Offset(-r * 0.52, -r * 0.06), w: 0.08, h: 0.12, travel: 0.52),
        (o: Offset(r * 0.34, -r * 0.08), w: 0.078, h: 0.118, travel: 0.5),
        (o: Offset(0, -r * 0.48), w: 0.065, h: 0.1, travel: 0.38),
      ]);
    }
    if (level >= 5) {
      specs.addAll([
        (o: Offset(-r * 0.2, -r * 0.44), w: 0.07, h: 0.11, travel: 0.4),
        (o: Offset(r * 0.22, -r * 0.42), w: 0.072, h: 0.112, travel: 0.4),
      ]);
    }
    if (level >= 6) {
      specs.add((
        o: Offset(-r * 0.55, -r * 0.24),
        w: 0.085,
        h: 0.13,
        travel: 0.46,
      ));
    }

    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final cycle = (sweatFlowPhase + i * 0.11) % 1.0;
      final fallT = Curves.easeInOut.transform(cycle);
      final travel = r * s.travel;
      final wobble = math.sin((cycle + i * 0.37) * math.pi * 2) * r * 0.018;
      final center = c + s.o + Offset(wobble, travel * fallT);

      final fadeIn = (cycle / 0.14).clamp(0.0, 1.0);
      final fadeOut = cycle > 0.86 ? ((1 - cycle) / 0.14).clamp(0.0, 1.0) : 1.0;
      final alpha = (0.55 + t * 0.35) * fadeIn * fadeOut;

      final rect = Rect.fromCenter(
        center: center,
        width: r * s.w * ex,
        height: r * s.h * ex,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = const Color(0xFF81D4FA).withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.035),
      );
      canvas.drawOval(
        rect.deflate(r * 0.012),
        Paint()
          ..color = const Color(
            0xFFE1F5FE,
          ).withValues(alpha: (0.75 + t * 0.2) * fadeIn * fadeOut),
      );
    }
  }

  void _drawHappySparkles(Canvas canvas, Offset c, double r) {
    final fill = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.9);
    final stroke = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final ex = _exaggeration;
    for (final o in [
      Offset(-r * 0.55, -r * 0.28),
      Offset(r * 0.58, -r * 0.22),
      Offset(r * 0.45, r * 0.05),
    ]) {
      final p = c + o;
      final s = r * 0.045 * ex;
      canvas.drawCircle(p, s, fill);
      canvas.drawLine(p + Offset(-s * 2.2, 0), p + Offset(s * 2.2, 0), stroke);
      canvas.drawLine(p + Offset(0, -s * 2.2), p + Offset(0, s * 2.2), stroke);
    }
  }

  double _submergedTopY(Rect oval) {
    final sub = waterSubmerge.clamp(0.0, 1.0);
    if (waterSurfaceY != null) {
      return waterSurfaceY!.clamp(oval.top, oval.bottom);
    }
    return oval.bottom - oval.height * sub;
  }

  void _drawWaterOverlay(Canvas canvas, Offset c, double r) {
    final sub = waterSubmerge.clamp(0.0, 1.0);
    if (sub <= 0.01) return;

    final oval = _faceOvalRect(c, r);
    final top = _submergedTopY(oval);
    if (top >= oval.bottom - 0.5) return;

    final submerged = Rect.fromLTRB(
      oval.left - r * 0.06,
      top,
      oval.right + r * 0.06,
      oval.bottom + r * 0.04,
    );

    canvas.drawRect(
      submerged,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF81D4FA).withValues(alpha: 0.16 + sub * 0.1),
            const Color(0xFF4FC3F7).withValues(alpha: 0.26 + sub * 0.14),
          ],
        ).createShader(submerged),
    );

    canvas.drawLine(
      Offset(oval.left, top),
      Offset(oval.right, top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28 + sub * 0.2)
        ..strokeWidth = (r * 0.018).clamp(1.0, 2.2),
    );
  }

  void _drawBrowsWorried(Canvas canvas, Offset c, double r) {
    final t = _emotionT;
    final lift = breath * r * 0.004;
    final strokeW = (r * 0.017 + t * r * 0.011).clamp(1.35, 3.0);

    for (final side in [-1.0, 1.0]) {
      final eyeX = c.dx + side * r * 0.27;
      final browY = c.dy - r * (0.158 + t * 0.022) + lift;

      final inner = Offset(
        eyeX - side * r * (0.12 + t * 0.015),
        browY - r * (0.004 + t * 0.01),
      );
      final outer = Offset(
        eyeX + side * r * (0.14 + t * 0.015),
        browY + r * (0.01 + t * 0.055),
      );
      final cp1 = Offset(
        inner.dx + side * r * 0.055,
        inner.dy + r * (0.004 + t * 0.008),
      );
      final cp2 = Offset(
        outer.dx - side * r * 0.055,
        outer.dy - r * (0.003 + t * 0.007),
      );

      final path = Path()
        ..moveTo(inner.dx, inner.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, outer.dx, outer.dy);

      canvas.drawPath(
        path,
        Paint()
          ..color = _brow.withValues(alpha: 0.84 + t * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _drawBrows(Canvas canvas, Offset c, double r) {
    if (_isWorried && mood != TrayFaceMood.happy) {
      _drawBrowsWorried(canvas, c, r);
      return;
    }

    final lift = breath * r * 0.01;
    final frown = mood == TrayFaceMood.happy
        ? _stressLevel * 0.25
        : _stressLevel;
    final smile = _isWorried ? _joyLevel * 0.2 : _joyLevel;
    final panic = mood == TrayFaceMood.panic;

    for (final side in [-1.0, 1.0]) {
      final cx = side * r * 0.27;
      final w = r * 0.22;
      final baseY = c.dy - r * 0.21 + lift + (panic ? -r * 0.06 : 0);

      final innerX =
          c.dx +
          cx -
          side * w * (0.52 - frown * 0.16) +
          side * w * 0.04 * smile;
      final outerX = c.dx + cx + side * w * (0.52 + smile * 0.04);
      final innerY = baseY + w * (0.08 + frown * 0.28 - smile * 0.06);
      final outerY = baseY + w * (0.06 + frown * 0.14 - smile * 0.04);
      final apexY =
          baseY -
          w * (0.42 + smile * 0.22 - frown * 0.32) -
          (panic ? w * 0.08 : 0);
      final apexX = c.dx + cx - side * w * frown * 0.12;

      final path = Path()
        ..moveTo(innerX, innerY)
        ..quadraticBezierTo(apexX, apexY, outerX, outerY);

      final strokeW = (r * 0.028 + frown * r * 0.012).clamp(2.0, 4.2);
      canvas.drawPath(
        path,
        Paint()
          ..color = _brow.withValues(alpha: 0.88 + frown * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      final hairN = 4 + (frown * 3).round();
      for (var i = 0; i < hairN; i++) {
        final t = i / (hairN - 1);
        final p = Offset(
          innerX + (outerX - innerX) * t,
          innerY + (apexY - innerY) * 4 * t * (1 - t),
        );
        canvas.drawLine(
          p,
          p + Offset(side * r * 0.02, -r * (0.035 + frown * 0.02)),
          Paint()
            ..color = _brow.withValues(alpha: 0.4 + frown * 0.2)
            ..strokeWidth = 0.9,
        );
      }
    }
  }

  void _drawEyeWorried(
    Canvas canvas, {
    required Offset eyeC,
    required double r,
    required double open,
  }) {
    final level = _emotionLevel;
    final t = _emotionT;
    final eyes = _eyeOpenAmount;
    final eyeOpen = open * (1.0 + eyes * 0.4);
    final scale = 1.0 + t * 0.16 + eyes * 0.34;
    final w = r * 0.1 * scale;
    final h = r * 0.078 * scale * eyeOpen;

    final eyeRect = Rect.fromCenter(
      center: eyeC,
      width: w * (2.02 + eyes * 0.22),
      height: math.max(h * (1.78 + eyes * 0.28), r * (0.034 + eyes * 0.028)),
    );

    if (eyes >= 0.05 || level >= 2) {
      canvas.drawOval(
        eyeRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFFFAFAFA),
              Color(0xFFEFEBE9),
              Color(0xFFE0DAD6),
            ],
            stops: [0.0, 0.45, 1.0],
          ).createShader(eyeRect),
      );
      canvas.drawOval(
        eyeRect,
        Paint()
          ..color = _brow.withValues(alpha: 0.1 + t * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.85,
      );

      final irisC = eyeC + Offset(0, h * (0.06 + eyes * 0.035));
      final irisR = w * (0.42 - eyes * 0.08 + t * 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: irisC,
          width: irisR * 2,
          height: irisR * (1.55 + t * 0.18 + eyes * 0.22),
        ),
        Paint()
          ..shader = RadialGradient(
            colors: [
              _iris.withValues(alpha: 0.95),
              _iris,
              const Color(0xFF2C1810),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: irisC, radius: irisR)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: irisC + Offset(0, h * 0.04),
          width: irisR * 1.1,
          height: irisR * 0.85,
        ),
        Paint()..color = const Color(0xFF120A08),
      );

      final hiAlpha = 0.5 + t * 0.45;
      canvas.drawCircle(
        irisC + Offset(-w * 0.14, -h * 0.12),
        w * (0.09 + t * 0.04),
        Paint()..color = Colors.white.withValues(alpha: hiAlpha),
      );
      if (level >= 3) {
        canvas.drawCircle(
          irisC + Offset(w * 0.1, h * 0.08),
          w * 0.04,
          Paint()..color = Colors.white.withValues(alpha: 0.45 + t * 0.3),
        );
      }
    } else {
      canvas.drawOval(
        eyeRect,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF4E342E), const Color(0xFF3E2723)],
          ).createShader(eyeRect),
      );
    }

    if (eyes >= 0.04) {
      canvas.drawArc(
        Rect.fromCenter(
          center: eyeC + Offset(0, -h * (0.5 + eyes * 0.1)),
          width: eyeRect.width * (0.95 + eyes * 0.14),
          height: h * (0.75 + t * 0.22 + eyes * 0.38),
        ),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        Paint()
          ..color = _brow.withValues(alpha: 0.18 + t * 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * 0.013 + t * r * 0.015).clamp(1.1, 3.0),
      );
    }
  }

  void _drawEyes(Canvas canvas, Offset c, double r) {
    for (final side in [-1.0, 1.0]) {
      final eyeC = c + Offset(side * r * 0.27, -r * 0.02);
      final w = r * 0.115;
      final h = r * 0.078;

      if (_isWorried && mood != TrayFaceMood.happy) {
        _drawEyeWorried(canvas, eyeC: eyeC, r: r, open: 1.0);
        continue;
      }

      if (blink < 0.92) {
        final open = 1 - blink;
        final eh = h * 2 * open;
        final eyeScale = mood == TrayFaceMood.panic
            ? 1.22 * _exaggeration
            : mood == TrayFaceMood.stressed
            ? 1.08 * _exaggeration
            : mood == TrayFaceMood.happy
            ? 0.92
            : 1.0;
        final eyeRect = Rect.fromCenter(
          center: eyeC,
          width: w * 2.05 * eyeScale,
          height: math.max(eh * eyeScale, 1),
        );

        canvas.drawOval(
          eyeRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFF5F5F5), const Color(0xFFE8E4E0)],
            ).createShader(eyeRect),
        );

        canvas.drawOval(
          eyeRect,
          Paint()
            ..color = _brow.withValues(alpha: 0.14)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9,
        );

        final pupilOff = Offset(lookX * w * 0.32, lookY * h * 0.48);
        final irisC = eyeC + pupilOff + Offset(0, h * 0.07 * open);
        final pupilScale = mood == TrayFaceMood.panic
            ? 1.28 * _exaggeration
            : mood == TrayFaceMood.stressed
            ? 0.72
            : mood == TrayFaceMood.happy
            ? 0.88
            : 1.0;

        if (mood == TrayFaceMood.happy && reactionPulse > 0.2) {
          canvas.drawArc(
            eyeRect,
            math.pi * 0.15,
            math.pi * 0.7,
            false,
            Paint()
              ..color = _brow.withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.022,
          );
        }

        canvas.drawCircle(
          irisC,
          w * 0.52 * open * pupilScale,
          Paint()..color = _irisRing,
        );
        canvas.drawCircle(
          irisC,
          w * 0.44 * open * pupilScale,
          Paint()
            ..shader = RadialGradient(
              colors: [
                _iris.withValues(alpha: 0.95),
                _iris,
                const Color(0xFF2C1810),
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(Rect.fromCircle(center: irisC, radius: w * 0.5)),
        );
        canvas.drawCircle(
          irisC,
          w * 0.26 * open,
          Paint()..color = const Color(0xFF120A08),
        );

        canvas.drawCircle(
          irisC + Offset(-w * 0.14, -h * 0.2),
          w * 0.1,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
        canvas.drawCircle(
          irisC + Offset(w * 0.1, h * 0.16),
          w * 0.045,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );

        canvas.drawArc(
          Rect.fromCenter(center: eyeC, width: w * 2.2, height: h * 1.65),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (r * 0.018).clamp(1.2, 2.2),
        );

        for (var i = -2; i <= 2; i++) {
          final ang = i * 0.28;
          final p1 = eyeC + Offset(math.sin(ang) * w * 0.62, -h * 0.14);
          final p2 = p1 + Offset(math.sin(ang) * 3, -3.2);
          canvas.drawLine(
            p1,
            p2,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.4)
              ..strokeWidth = 1.2
              ..strokeCap = StrokeCap.round,
          );
        }

        canvas.drawArc(
          Rect.fromCenter(
            center: eyeC + Offset(0, -h * 0.12),
            width: w * 2.15,
            height: h * 1.35,
          ),
          math.pi * 1.02,
          math.pi * 0.96,
          false,
          Paint()
            ..color = _toneMid.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (r * 0.014).clamp(1.0, 1.8),
        );
      }

      if (blink > 0.05) {
        final lidH = h * 2.25 * blink;
        canvas.drawOval(
          Rect.fromCenter(
            center: eyeC + Offset(0, -h * 0.04),
            width: w * 2.2,
            height: lidH,
          ),
          Paint()..color = _toneMid,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: eyeC + Offset(0, -h * 0.22),
            width: w * 2.25,
            height: h * 0.85,
          ),
          math.pi * 1.05,
          math.pi * 0.9,
          false,
          Paint()
            ..color = _brow.withValues(alpha: 0.32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }
  }

  void _drawNose(Canvas canvas, Offset c, double r) {
    final tip = c + Offset(0, r * 0.16);
    final s = r * 0.1;

    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: tip + Offset(side * s * 0.38, s * 0.15),
          width: s * 0.22,
          height: s * 0.55,
        ),
        Paint()
          ..color = _toneDeep.withValues(alpha: 0.12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.15),
      );
    }

    canvas.drawCircle(
      c + Offset(0, r * 0.1),
      r * 0.06,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    final bridge = Path()
      ..moveTo(tip.dx, tip.dy - s * 0.95)
      ..lineTo(tip.dx, tip.dy + s * 0.12);
    canvas.drawPath(
      bridge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _toneLo.withValues(alpha: 0.35),
            _toneDeep.withValues(alpha: 0.2),
          ],
        ).createShader(Rect.fromCircle(center: tip, radius: s))
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.11
        ..strokeCap = StrokeCap.round,
    );

    final nose = Path()
      ..moveTo(tip.dx, tip.dy - s * 0.55)
      ..quadraticBezierTo(
        tip.dx - s * 0.44,
        tip.dy + s * 0.04,
        tip.dx - s * 0.24,
        tip.dy + s * 0.58,
      )
      ..quadraticBezierTo(
        tip.dx,
        tip.dy + s * 0.65,
        tip.dx + s * 0.24,
        tip.dy + s * 0.58,
      )
      ..quadraticBezierTo(
        tip.dx + s * 0.44,
        tip.dy + s * 0.04,
        tip.dx,
        tip.dy - s * 0.55,
      )
      ..close();
    canvas.drawPath(
      nose,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _toneMid.withValues(alpha: 0.95),
            _toneWarm,
            _toneLo.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromCircle(center: tip, radius: s)),
    );

    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: tip + Offset(side * s * 0.22, s * 0.4),
          width: s * 0.16,
          height: s * 0.1,
        ),
        Paint()..color = _toneDeep.withValues(alpha: 0.55),
      );
    }
  }

  void _drawMouthWorried(Canvas canvas, Offset c, double r) {
    final t = _emotionT;
    final eyes = _eyeOpenAmount;
    final mouth = _mouthOpenAmount;
    final ex = _exaggeration;
    final mouthC = c + Offset(0, r * (0.31 + t * 0.05 + mouth * 0.02));

    if (mouth < 0.1) {
      final halfW = r * (0.085 + eyes * 0.038) * ex;
      final dip = r * (0.005 + eyes * 0.032);
      canvas.drawPath(
        Path()
          ..moveTo(mouthC.dx - halfW, mouthC.dy)
          ..quadraticBezierTo(
            mouthC.dx,
            mouthC.dy + dip,
            mouthC.dx + halfW,
            mouthC.dy,
          ),
        Paint()
          ..color = _lipBot.withValues(alpha: 0.74 + eyes * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * (0.021 + eyes * 0.008)).clamp(1.6, 3.2)
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final openW = r * (0.048 + mouth * 0.13 + t * 0.02) * ex;
    final openH = r * (0.03 + mouth * 0.1 + t * 0.02) * ex;
    final outer = Rect.fromCenter(
      center: mouthC,
      width: openW * 2.05,
      height: openH * 2.35,
    );

    canvas.drawOval(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF4E342E), Color(0xFF2C1810)],
        ).createShader(outer),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: mouthC + Offset(0, openH * 0.42),
        width: openW * 1.3,
        height: openH * 1.15,
      ),
      Paint()..color = const Color(0xFF0D0706),
    );

    if (mouth >= 0.42) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: mouthC + Offset(0, -openH * 0.3),
            width: openW * 1.15,
            height: openH * 0.34,
          ),
          Radius.circular(openH * 0.12),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.8 + mouth * 0.14),
      );
    }

    canvas.drawOval(
      outer.inflate(r * 0.006),
      Paint()
        ..color = _lipMid.withValues(alpha: 0.22 + t * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.01 + t * r * 0.012).clamp(1.0, 2.8),
    );
  }

  void _drawMouth(Canvas canvas, Offset c, double r) {
    final ex = _exaggeration;
    final frown = _stressLevel;
    final smile = _joyLevel;

    if (_isWorried && smile < 0.35) {
      _drawMouthWorried(canvas, c, r);
      return;
    }

    final mouthY = r * (0.35 + smile * 0.06 - frown * 0.04);
    final mouthC = c + Offset(0, mouthY);
    final lipW = r * (0.22 + smile * 0.08 + frown * 0.02);
    final lipH = r * (0.08 + smile * 0.05 + frown * 0.03) * ex;

    if (smile > 0.2) {
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthC + Offset(0, lipH * 0.55),
          width: lipW * 0.65,
          height: lipH * 0.35,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final lowerLip = Path()
        ..moveTo(mouthC.dx - lipW * 0.94, mouthC.dy + lipH * 0.06)
        ..quadraticBezierTo(
          mouthC.dx,
          mouthC.dy + lipH * (0.85 + smile * 0.25),
          mouthC.dx + lipW * 0.94,
          mouthC.dy + lipH * 0.06,
        )
        ..close();
      canvas.drawPath(
        lowerLip,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lipMid, _lipBot],
          ).createShader(Rect.fromCircle(center: mouthC, radius: lipW)),
      );

      final upperCurve = -lipH * (0.55 + smile * 0.35);
      final upperLip = Path()
        ..moveTo(mouthC.dx - lipW, mouthC.dy + lipH * 0.02)
        ..quadraticBezierTo(
          mouthC.dx,
          mouthC.dy + upperCurve,
          mouthC.dx + lipW,
          mouthC.dy + lipH * 0.02,
        );
      canvas.drawPath(
        upperLip,
        Paint()
          ..color = _lipTop
          ..style = PaintingStyle.stroke
          ..strokeWidth = lipH * (0.38 + smile * 0.12)
          ..strokeCap = StrokeCap.round,
      );

      if (smile > 0.45) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: mouthC + Offset(0, lipH * 0.1),
              width: lipW * (0.3 + smile * 0.12),
              height: lipH * (0.2 + smile * 0.08),
            ),
            Radius.circular(lipH * 0.08),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.7 + smile * 0.2),
        );
      }
    }

    if (smile < 0.55 && frown < 0.55) {
      canvas.drawLine(
        mouthC + Offset(-lipW * 0.55, 0),
        mouthC + Offset(lipW * 0.55, 0),
        Paint()
          ..color = _lipMid.withValues(alpha: 0.85)
          ..strokeWidth = (r * 0.022).clamp(1.5, 2.5)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrayCenterFacePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.breath != breath ||
        oldDelegate.sweatFlowPhase != sweatFlowPhase ||
        oldDelegate.blink != blink ||
        oldDelegate.sway != sway ||
        oldDelegate.lookX != lookX ||
        oldDelegate.lookY != lookY ||
        oldDelegate.mood != mood ||
        oldDelegate.waterSubmerge != waterSubmerge ||
        oldDelegate.waterSurfaceY != waterSurfaceY ||
        oldDelegate.reactionPulse != reactionPulse ||
        oldDelegate.wrongAnswerCount != wrongAnswerCount ||
        oldDelegate.solvedInLevel != solvedInLevel ||
        oldDelegate.targetsInLevel != targetsInLevel;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/arkanoid_ball_speed_controller.dart';
import '../../../domain/arkanoid_ball_speed.dart';

/// Discrete 1–10 ball-speed control with a sawtooth track.
class ArkanoidBallSpeedSlider extends ConsumerWidget {
  const ArkanoidBallSpeedSlider({
    super.key,
    required this.l10n,
    this.height = 36,
  });

  final AppLocalizations l10n;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(arkanoidBallSpeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '${l10n.wordBuilderArkanoidBallSpeed}: $level',
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Icon(
              Icons.speed,
              size: 18,
              color: isDark ? const Color(0xFF81D4FA) : const Color(0xFF0277BD),
            ),
            const SizedBox(width: 6),
            Text(
              '1',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF455A64),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const _SawThumbShape(),
                  trackShape: _SawtoothTrackShape(level: level, isDark: isDark),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                ),
                child: Slider(
                  min: ArkanoidBallSpeedScale.minLevel.toDouble(),
                  max: ArkanoidBallSpeedScale.maxLevel.toDouble(),
                  divisions: ArkanoidBallSpeedScale.maxLevel -
                      ArkanoidBallSpeedScale.minLevel,
                  value: level.toDouble(),
                  label: '$level',
                  onChanged: (v) => ref
                      .read(arkanoidBallSpeedProvider.notifier)
                      .setLevel(v.round()),
                ),
              ),
            ),
            Text(
              '10',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF455A64),
              ),
            ),
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white70),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF5D4037),
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SawThumbShape extends SliderComponentShape {
  const _SawThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(18, 22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final path = Path()
      ..moveTo(center.dx, center.dy - 11)
      ..lineTo(center.dx + 9, center.dy + 8)
      ..lineTo(center.dx - 9, center.dy + 8)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }
}

/// Zigzag / sawtooth track for the speed slider.
class _SawtoothTrackShape extends SliderTrackShape {
  _SawtoothTrackShape({required this.level, required this.isDark});

  final int level;
  final bool isDark;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 10;
    final trackLeft = offset.dx + 8;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 16;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final canvas = context.canvas;
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.width <= 0) return;

    final midY = rect.center.dy;
    final amp = rect.height * 0.42;
    final teeth = 10;
    final step = rect.width / teeth;

    Path buildWave() {
      final p = Path()..moveTo(rect.left, midY + amp);
      for (var i = 0; i < teeth; i++) {
        final x0 = rect.left + i * step;
        final x1 = x0 + step / 2;
        final x2 = x0 + step;
        p.lineTo(x1, midY - amp);
        p.lineTo(x2, midY + amp);
      }
      return p;
    }

    final wave = buildWave();
    canvas.drawPath(
      wave,
      Paint()
        ..color = (isDark ? const Color(0xFF455A64) : const Color(0xFF90A4AE))
            .withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(rect.left, rect.top - 4, thumbCenter.dx, rect.bottom + 4),
    );
    canvas.drawPath(
      wave,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF29B6F6),
          const Color(0xFFFF6F00),
          (level - 1) / 9,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final tickPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF546E7A))
          .withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i <= teeth; i++) {
      final x = rect.left + i * step;
      canvas.drawLine(
        Offset(x, midY + amp + 3),
        Offset(x, midY + amp + 7),
        tickPaint,
      );
    }
  }
}

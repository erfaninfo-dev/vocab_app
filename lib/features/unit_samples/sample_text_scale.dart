import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kSamplesTextScaleMin = 0.85;
const double kSamplesTextScaleMax = 1.55;
const double kSampleBookTextSizeBarHeight = 52;

double clampSamplesTextScale(double value) =>
    value.clamp(kSamplesTextScaleMin, kSamplesTextScaleMax);

final samplesTextScaleProvider =
    NotifierProvider<SamplesTextScaleController, double>(
      SamplesTextScaleController.new,
    );

class SamplesTextScaleController extends Notifier<double> {
  static const _prefsKey = 'unit_samples_text_scale_v1';

  @override
  double build() {
    _hydrate();
    return 1.0;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey);
    if (saved == null) return;
    state = clampSamplesTextScale(saved);
  }

  void previewScale(double value) {
    final next = clampSamplesTextScale(value);
    if (state == next) return;
    state = next;
  }

  Future<void> persistScale([double? value]) async {
    final next = clampSamplesTextScale(value ?? state);
    if (state != next) {
      state = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, next);
  }

  Future<void> setScale(double value) => persistScale(value);
}

/// Horizontal text-size slider for book mode — fixed overlay at bottom of page.
class SampleBookHorizontalTextSizeSlider extends ConsumerStatefulWidget {
  const SampleBookHorizontalTextSizeSlider({
    super.key,
    this.paperColor = const Color(0xFFFAF3E8),
  });

  final Color paperColor;

  @override
  ConsumerState<SampleBookHorizontalTextSizeSlider> createState() =>
      _SampleBookHorizontalTextSizeSliderState();
}

class _SampleBookHorizontalTextSizeSliderState
    extends ConsumerState<SampleBookHorizontalTextSizeSlider> {
  static const _textUpdateInterval = Duration(milliseconds: 48);
  static const _minPreviewDelta = 0.018;

  var _active = false;
  double? _dragScale;
  DateTime? _lastTextUpdate;

  double _scaleFromDx(double dx, double width) {
    final t = (dx / width).clamp(0.0, 1.0);
    return clampSamplesTextScale(
      kSamplesTextScaleMin +
          ((kSamplesTextScaleMax - kSamplesTextScaleMin) * t),
    );
  }

  double _normalizedScale(double scale) =>
      ((clampSamplesTextScale(scale) - kSamplesTextScaleMin) /
              (kSamplesTextScaleMax - kSamplesTextScaleMin))
          .clamp(0.0, 1.0);

  void _previewScaleThrottled(double next) {
    final current = ref.read(samplesTextScaleProvider);
    if ((next - current).abs() < _minPreviewDelta) return;
    final now = DateTime.now();
    if (_lastTextUpdate != null &&
        now.difference(_lastTextUpdate!) < _textUpdateInterval) {
      return;
    }
    _lastTextUpdate = now;
    ref.read(samplesTextScaleProvider.notifier).previewScale(next);
  }

  void _commitDrag(double next) {
    setState(() => _dragScale = next);
    _previewScaleThrottled(next);
  }

  void _finishDrag(double next) {
    _lastTextUpdate = null;
    setState(() {
      _active = false;
      _dragScale = null;
    });
    ref.read(samplesTextScaleProvider.notifier).persistScale(next);
  }

  @override
  Widget build(BuildContext context) {
    final providerScale = ref.watch(samplesTextScaleProvider);
    final scale = _dragScale ?? providerScale;
    final scheme = Theme.of(context).colorScheme;
    final normalized = _normalizedScale(scale);
    final trackColor = const Color(0xFF8D7B68).withValues(alpha: 0.45);
    final thumbColor = scheme.inverseSurface;
    final activeFillColor = thumbColor.withValues(alpha: 0.18);

    return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.paperColor.withValues(alpha: 0),
              widget.paperColor.withValues(alpha: 0.88),
              widget.paperColor,
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.text_decrease_rounded,
                size: 16,
                color: trackColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          setState(() => _active = true);
                          _commitDrag(
                            _scaleFromDx(details.localPosition.dx, width),
                          );
                        },
                        onPanUpdate: (details) => _commitDrag(
                          _scaleFromDx(details.localPosition.dx, width),
                        ),
                        onPanEnd: (_) =>
                            _finishDrag(_dragScale ?? providerScale),
                        onPanCancel: () =>
                            _finishDrag(_dragScale ?? providerScale),
                        onTapDown: (details) {
                          setState(() => _active = true);
                          _commitDrag(
                            _scaleFromDx(details.localPosition.dx, width),
                          );
                        },
                        onTapUp: (_) =>
                            _finishDrag(_dragScale ?? providerScale),
                        onTapCancel: () =>
                            _finishDrag(_dragScale ?? providerScale),
                        child: CustomPaint(
                          painter: _SampleHorizontalTextSizeSliderPainter(
                            normalized: normalized,
                            active: _active,
                            trackColor: trackColor,
                            activeFillColor: activeFillColor,
                            thumbColor: thumbColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.text_increase_rounded,
                size: 20,
                color: trackColor,
              ),
            ],
          ),
        ),
    );
  }
}

class _SampleHorizontalTextSizeSliderPainter extends CustomPainter {
  const _SampleHorizontalTextSizeSliderPainter({
    required this.normalized,
    required this.active,
    required this.trackColor,
    required this.activeFillColor,
    required this.thumbColor,
  });

  final double normalized;
  final bool active;
  final Color trackColor;
  final Color activeFillColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = normalized.clamp(0.0, 1.0);
    final knobX = size.width * progress;
    final centerY = size.height / 2;

    if (active) {
      final easedBody = Curves.easeOutCubic.transform(progress);
      const leftHalfHeight = 0.65;
      final rightHalfHeight = 1.4 + (8.6 * easedBody);
      final path = Path()
        ..moveTo(0, centerY - leftHalfHeight)
        ..cubicTo(
          knobX * 0.34,
          centerY - (leftHalfHeight * 0.74),
          size.width * 0.76,
          centerY - rightHalfHeight,
          size.width,
          centerY - rightHalfHeight,
        )
        ..lineTo(size.width, centerY + rightHalfHeight)
        ..cubicTo(
          size.width * 0.76,
          centerY + rightHalfHeight,
          knobX * 0.34,
          centerY + (leftHalfHeight * 0.74),
          0,
          centerY + leftHalfHeight,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = activeFillColor.withValues(alpha: 0.08 + progress * 0.48),
      );
    } else {
      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        Paint()
          ..color = trackColor
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(Offset(knobX, centerY), 10, Paint()..color = thumbColor);
  }

  @override
  bool shouldRepaint(covariant _SampleHorizontalTextSizeSliderPainter old) {
    return old.normalized != normalized ||
        old.active != active ||
        old.trackColor != trackColor ||
        old.activeFillColor != activeFillColor ||
        old.thumbColor != thumbColor;
  }
}

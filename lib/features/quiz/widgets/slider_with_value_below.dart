import 'dart:math' as math;

import 'package:flutter/material.dart';

/// [Slider] without the floating value bubble above the thumb; shows
/// [displayValue] under the thumb at all times.
class SliderWithValueBelow extends StatelessWidget {
  const SliderWithValueBelow({
    super.key,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.sliderValue,
    this.divisions,
    this.onChanged,
  });

  final double min;
  final double max;
  final int displayValue;
  final double sliderValue;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        );
    final baseTheme = SliderTheme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // Approximate half-thumb travel inset; matches typical Material slider.
        const inset = 14.0;
        final span = math.max(1.0, w - 2 * inset);
        final low = min;
        final high = max;
        final v = sliderValue.clamp(min, max);
        final t = high <= low ? 0.5 : (v - low) / (high - low);
        final fromLeft = inset + t * span;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final thumbX = rtl ? w - fromLeft : fromLeft;

        return SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SliderTheme(
                  data: baseTheme.copyWith(
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    min: min,
                    max: max,
                    divisions: divisions,
                    value: v,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Positioned(
                top: 34,
                left: thumbX - 30,
                width: 60,
                child: Text(
                  '$displayValue',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

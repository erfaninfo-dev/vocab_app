import 'dart:ui';

import 'wb_silhouette.dart';

/// Classic party balloon 🎈 — tall teardrop + tied knot (unit box).
class WbBalloonSilhouette extends WbSilhouette {
  const WbBalloonSilhouette();

  @override
  Path build() {
    // Body: rounded top, taper to knot at bottom.
    final body = Path()
      ..moveTo(0.50, 0.06)
      ..cubicTo(0.78, 0.06, 0.92, 0.28, 0.88, 0.48)
      ..cubicTo(0.84, 0.68, 0.66, 0.78, 0.50, 0.82)
      ..cubicTo(0.34, 0.78, 0.16, 0.68, 0.12, 0.48)
      ..cubicTo(0.08, 0.28, 0.22, 0.06, 0.50, 0.06)
      ..close();
    // Knot diamond under the body.
    body
      ..moveTo(0.50, 0.80)
      ..lineTo(0.58, 0.86)
      ..lineTo(0.50, 0.92)
      ..lineTo(0.42, 0.86)
      ..close();
    return body;
  }
}

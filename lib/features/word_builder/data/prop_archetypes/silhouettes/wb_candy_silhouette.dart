import 'dart:ui';

import 'wb_silhouette.dart';

/// Peppermint swirl candy ball + stick (lollipop) in unit box.
class WbCandySilhouette extends WbSilhouette {
  const WbCandySilhouette();

  @override
  Path build() {
    final path = Path()
      ..addOval(
        Rect.fromCircle(center: const Offset(0.5, 0.38), radius: 0.32),
      );
    // Stick under the ball.
    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.44, 0.66, 0.12, 0.30),
        const Radius.circular(0.05),
      ),
    );
    return path;
  }
}

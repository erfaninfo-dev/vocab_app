import 'dart:ui';

import 'wb_silhouette.dart';

/// Ceramic jug: belly + neck + simple handle.
class WbJugSilhouette extends WbSilhouette {
  const WbJugSilhouette();

  @override
  Path build() {
    final p = Path();
    // Belly
    p.moveTo(0.32, 0.28);
    p.quadraticBezierTo(0.12, 0.55, 0.30, 0.88);
    p.lineTo(0.70, 0.88);
    p.quadraticBezierTo(0.88, 0.55, 0.68, 0.28);
    // Neck + lip
    p.lineTo(0.62, 0.18);
    p.lineTo(0.66, 0.12);
    p.lineTo(0.34, 0.12);
    p.lineTo(0.38, 0.18);
    p.close();
    // Handle (loop)
    p.moveTo(0.70, 0.32);
    p.quadraticBezierTo(0.92, 0.42, 0.78, 0.62);
    p.quadraticBezierTo(0.72, 0.48, 0.70, 0.38);
    p.close();
    return p;
  }
}

/// Glass bottle: body + shoulder + neck + mouth.
class WbBottleSilhouette extends WbSilhouette {
  const WbBottleSilhouette();

  @override
  Path build() {
    final p = Path();
    p.moveTo(0.34, 0.92);
    p.lineTo(0.66, 0.92);
    p.lineTo(0.64, 0.48);
    p.quadraticBezierTo(0.62, 0.36, 0.54, 0.30); // shoulder
    p.lineTo(0.54, 0.12);
    p.lineTo(0.46, 0.12);
    p.lineTo(0.46, 0.30);
    p.quadraticBezierTo(0.38, 0.36, 0.36, 0.48);
    p.close();
    return p;
  }
}

/// Plush bear: head circle + ears + body oval.
class WbBearSilhouette extends WbSilhouette {
  const WbBearSilhouette();

  @override
  Path build() {
    final p = Path()
      ..addOval(const Rect.fromLTWH(0.22, 0.38, 0.56, 0.52)) // body
      ..addOval(const Rect.fromLTWH(0.28, 0.14, 0.44, 0.40)) // head
      ..addOval(const Rect.fromLTWH(0.22, 0.10, 0.16, 0.16)) // L ear
      ..addOval(const Rect.fromLTWH(0.62, 0.10, 0.16, 0.16)); // R ear
    return p;
  }
}

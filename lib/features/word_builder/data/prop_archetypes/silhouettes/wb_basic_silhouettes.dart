import 'dart:ui';

import 'wb_silhouette.dart';

/// Circle / ellipse in the unit box.
class WbEllipseSilhouette extends WbSilhouette {
  const WbEllipseSilhouette({this.rx = 0.42, this.ry = 0.42});

  final double rx;
  final double ry;

  @override
  Path build() => Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.5),
        width: rx * 2,
        height: ry * 2,
      ),
    );
}

/// Soft perspective box (gift / crate / brick / concrete).
class WbBoxSilhouette extends WbSilhouette {
  const WbBoxSilhouette({this.perspective = 0.05});

  final double perspective;

  @override
  Path build() {
    const l = 0.14, r = 0.86, t = 0.16, b = 0.86;
    final p = perspective;
    return Path()
      ..moveTo(l + p, t)
      ..lineTo(r - p, t)
      ..lineTo(r, b)
      ..lineTo(l, b)
      ..close();
  }
}

/// Barrel: bowed sides.
class WbBarrelSilhouette extends WbSilhouette {
  const WbBarrelSilhouette();

  @override
  Path build() {
    final path = Path()
      ..moveTo(0.28, 0.12)
      ..quadraticBezierTo(0.12, 0.5, 0.28, 0.88)
      ..lineTo(0.72, 0.88)
      ..quadraticBezierTo(0.88, 0.5, 0.72, 0.12)
      ..close();
    return path;
  }
}

/// Tire: thick ring approximated as outer oval (inner hole painted later).
class WbTireSilhouette extends WbSilhouette {
  const WbTireSilhouette();

  @override
  Path build() => Path()..addOval(const Rect.fromLTWH(0.06, 0.12, 0.88, 0.76));
}

/// Crystal / gem diamond.
class WbCrystalSilhouette extends WbSilhouette {
  const WbCrystalSilhouette();

  @override
  Path build() => Path()
    ..moveTo(0.50, 0.06)
    ..lineTo(0.82, 0.42)
    ..lineTo(0.50, 0.94)
    ..lineTo(0.18, 0.42)
    ..close();
}

/// Can / drum cylinder (slightly bowed).
class WbCanSilhouette extends WbSilhouette {
  const WbCanSilhouette();

  @override
  Path build() {
    return Path()
      ..moveTo(0.30, 0.14)
      ..lineTo(0.70, 0.14)
      ..quadraticBezierTo(0.78, 0.5, 0.70, 0.86)
      ..lineTo(0.30, 0.86)
      ..quadraticBezierTo(0.22, 0.5, 0.30, 0.14)
      ..close();
  }
}

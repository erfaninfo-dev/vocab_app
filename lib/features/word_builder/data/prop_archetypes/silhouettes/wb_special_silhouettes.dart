import 'dart:math' as math;
import 'dart:ui';

import 'wb_silhouette.dart';

/// Old TV bezel.
class WbTvSilhouette extends WbSilhouette {
  const WbTvSilhouette();

  @override
  Path build() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.08, 0.18, 0.84, 0.64),
        const Radius.circular(0.06),
      ),
    );
}

/// Stone statue bust — no face detail.
class WbStatueSilhouette extends WbSilhouette {
  const WbStatueSilhouette();

  @override
  Path build() {
    final p = Path()
      ..addOval(const Rect.fromLTWH(0.30, 0.08, 0.40, 0.36))
      ..addRect(const Rect.fromLTWH(0.42, 0.40, 0.16, 0.14));
    p
      ..moveTo(0.18, 0.92)
      ..lineTo(0.82, 0.92)
      ..lineTo(0.72, 0.54)
      ..lineTo(0.28, 0.54)
      ..close();
    return p;
  }
}

/// Bronze bell + crown.
class WbBellSilhouette extends WbSilhouette {
  const WbBellSilhouette();

  @override
  Path build() {
    final p = Path()
      ..moveTo(0.50, 0.08)
      ..quadraticBezierTo(0.58, 0.08, 0.58, 0.16)
      ..quadraticBezierTo(0.58, 0.20, 0.50, 0.20)
      ..quadraticBezierTo(0.42, 0.20, 0.42, 0.16)
      ..quadraticBezierTo(0.42, 0.08, 0.50, 0.08);
    p
      ..moveTo(0.28, 0.22)
      ..quadraticBezierTo(0.12, 0.70, 0.18, 0.88)
      ..lineTo(0.82, 0.88)
      ..quadraticBezierTo(0.88, 0.70, 0.72, 0.22)
      ..close();
    return p;
  }
}

/// Neon tube capsule.
class WbTubeSilhouette extends WbSilhouette {
  const WbTubeSilhouette();

  @override
  Path build() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.32, 0.04, 0.36, 0.92),
        const Radius.circular(0.16),
      ),
    );
}

/// Light bulb: globe + screw base.
class WbBulbSilhouette extends WbSilhouette {
  const WbBulbSilhouette();

  @override
  Path build() {
    final p = Path()..addOval(const Rect.fromLTWH(0.18, 0.08, 0.64, 0.58));
    p
      ..moveTo(0.38, 0.62)
      ..lineTo(0.62, 0.62)
      ..lineTo(0.58, 0.92)
      ..lineTo(0.42, 0.92)
      ..close();
    return p;
  }
}

/// Gear with parametric teeth — separate cache by tooth count for erode.
class WbGearSilhouette extends WbSilhouette {
  const WbGearSilhouette({this.teeth = 8});

  final int teeth;

  static final Map<int, Path> _teethCache = {};

  static Path pathForTeeth(int teeth) {
    final n = teeth.clamp(3, 24);
    return _teethCache.putIfAbsent(n, () => WbGearSilhouette(teeth: n).build());
  }

  static void clearTeethCache() => _teethCache.clear();

  @override
  Path build() {
    final n = teeth.clamp(3, 24);
    const cx = 0.5, cy = 0.5;
    const rOuter = 0.46, rInner = 0.34, rHub = 0.14;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final a0 = (i / n) * math.pi * 2 - math.pi / 2;
      final a1 = ((i + 0.32) / n) * math.pi * 2 - math.pi / 2;
      final a2 = ((i + 0.68) / n) * math.pi * 2 - math.pi / 2;
      final a3 = ((i + 1.0) / n) * math.pi * 2 - math.pi / 2;
      final x0 = cx + math.cos(a0) * rInner;
      final y0 = cy + math.sin(a0) * rInner;
      if (i == 0) {
        path.moveTo(x0, y0);
      } else {
        path.lineTo(x0, y0);
      }
      path.lineTo(cx + math.cos(a1) * rOuter, cy + math.sin(a1) * rOuter);
      path.lineTo(cx + math.cos(a2) * rOuter, cy + math.sin(a2) * rOuter);
      path.lineTo(cx + math.cos(a3) * rInner, cy + math.sin(a3) * rInner);
    }
    path.close();
    path.addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: rHub));
    return path;
  }
}

/// Trophy cup.
class WbTrophySilhouette extends WbSilhouette {
  const WbTrophySilhouette();

  @override
  Path build() {
    final p = Path()
      ..moveTo(0.28, 0.18)
      ..lineTo(0.72, 0.18)
      ..quadraticBezierTo(0.78, 0.42, 0.62, 0.52)
      ..lineTo(0.58, 0.62)
      ..lineTo(0.68, 0.88)
      ..lineTo(0.32, 0.88)
      ..lineTo(0.42, 0.62)
      ..lineTo(0.38, 0.52)
      ..quadraticBezierTo(0.22, 0.42, 0.28, 0.18)
      ..close();
    return p;
  }
}

/// Thin glass pane rectangle.
class WbPaneSilhouette extends WbSilhouette {
  const WbPaneSilhouette();

  @override
  Path build() => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.18, 0.08, 0.64, 0.84),
        const Radius.circular(0.04),
      ),
    );
}

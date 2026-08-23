import 'dart:ui';

import '../wb_prop_archetype.dart';

/// Unit-space (0..1) outline for an archetype. Built once, then only transformed.
abstract class WbSilhouette {
  const WbSilhouette();

  /// Path in the unit square `[0,1]×[0,1]`. Mass near `(0.5, 0.5)`.
  Path build();
}

/// Draw a prebuilt unit path into [dest] via translate + scale only.
void paintUnitSilhouette(
  Canvas canvas,
  Path unitPath,
  Rect dest,
  Paint paint,
) {
  canvas.save();
  canvas.translate(dest.left, dest.top);
  canvas.scale(dest.width, dest.height);
  canvas.drawPath(unitPath, paint);
  canvas.restore();
}

/// Whether the prop is too small for a detailed silhouette.
bool useSimplifiedSilhouette({
  required double radiusPx,
  required WbArchetypeSpec spec,
}) =>
    radiusPx < spec.simplifiedBelowRadius;

/// Flat circle fallback for tiny props (unit-space).
final Path kSimplifiedCircleSilhouette = Path()
  ..addOval(const Rect.fromLTWH(0.08, 0.08, 0.84, 0.84));

/// Flat rounded-rect fallback (unit-space).
final Path kSimplifiedBoxSilhouette = Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0.12, 0.18, 0.76, 0.64),
      const Radius.circular(0.08),
    ),
  );

import 'dart:math' as math;
import 'dart:ui';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';

/// Cached unit-space paths for every [WbShardShape] — never rebuild in paint.
abstract final class WbShardPaths {
  static final Map<WbShardShape, Path> _cache = {};

  static Path forShape(WbShardShape shape) =>
      _cache.putIfAbsent(shape, () => _build(shape));

  static void clearCache() => _cache.clear();

  static Path _build(WbShardShape shape) {
    switch (shape) {
      case WbShardShape.shard:
        return Path()
          ..moveTo(0.50, 0.08)
          ..lineTo(0.78, 0.72)
          ..lineTo(0.50, 0.92)
          ..lineTo(0.22, 0.68)
          ..close();
      case WbShardShape.chunk:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.18, 0.18, 0.64, 0.64),
            const Radius.circular(0.08),
          ));
      case WbShardShape.crumb:
        return Path()..addOval(const Rect.fromLTWH(0.28, 0.28, 0.44, 0.44));
      case WbShardShape.dust:
        return Path()..addOval(const Rect.fromLTWH(0.35, 0.35, 0.30, 0.30));
      case WbShardShape.scrap:
        return Path()
          ..moveTo(0.20, 0.30)
          ..lineTo(0.80, 0.22)
          ..lineTo(0.72, 0.78)
          ..lineTo(0.28, 0.70)
          ..close();
      case WbShardShape.sliver:
        return Path()
          ..moveTo(0.48, 0.06)
          ..lineTo(0.58, 0.94)
          ..lineTo(0.42, 0.94)
          ..close();
      case WbShardShape.seed:
        return Path()..addOval(const Rect.fromLTWH(0.38, 0.22, 0.24, 0.56));
      case WbShardShape.coin:
        return Path()..addOval(const Rect.fromLTWH(0.18, 0.18, 0.64, 0.64));
      case WbShardShape.spark:
        final p = Path();
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2;
          p.moveTo(0.5, 0.5);
          p.lineTo(0.5 + math.cos(a) * 0.42, 0.5 + math.sin(a) * 0.42);
        }
        return p;
      case WbShardShape.droplet:
        return Path()
          ..moveTo(0.50, 0.12)
          ..quadraticBezierTo(0.78, 0.45, 0.50, 0.88)
          ..quadraticBezierTo(0.22, 0.45, 0.50, 0.12)
          ..close();
      case WbShardShape.fluff:
        return Path()
          ..addOval(const Rect.fromLTWH(0.22, 0.28, 0.36, 0.36))
          ..addOval(const Rect.fromLTWH(0.42, 0.32, 0.34, 0.34));
      case WbShardShape.ribbon:
        return Path()
          ..moveTo(0.20, 0.35)
          ..quadraticBezierTo(0.50, 0.10, 0.80, 0.35)
          ..quadraticBezierTo(0.50, 0.55, 0.20, 0.70)
          ..close();
      case WbShardShape.streamer:
        return Path()
          ..moveTo(0.42, 0.08)
          ..lineTo(0.58, 0.08)
          ..lineTo(0.52, 0.92)
          ..lineTo(0.48, 0.92)
          ..close();
      case WbShardShape.halfShell:
        return Path()
          ..moveTo(0.18, 0.55)
          ..quadraticBezierTo(0.50, 0.10, 0.82, 0.55)
          ..lineTo(0.18, 0.55)
          ..close();
      case WbShardShape.plate:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.12, 0.32, 0.76, 0.36),
            const Radius.circular(0.06),
          ));
      case WbShardShape.ember:
        return Path()
          ..moveTo(0.50, 0.12)
          ..lineTo(0.68, 0.55)
          ..lineTo(0.50, 0.88)
          ..lineTo(0.32, 0.55)
          ..close();
      case WbShardShape.prism:
        return Path()
          ..moveTo(0.50, 0.10)
          ..lineTo(0.82, 0.78)
          ..lineTo(0.18, 0.78)
          ..close();
      case WbShardShape.glint:
        return Path()
          ..moveTo(0.50, 0.18)
          ..lineTo(0.58, 0.42)
          ..lineTo(0.82, 0.50)
          ..lineTo(0.58, 0.58)
          ..lineTo(0.50, 0.82)
          ..lineTo(0.42, 0.58)
          ..lineTo(0.18, 0.50)
          ..lineTo(0.42, 0.42)
          ..close();
    }
  }
}

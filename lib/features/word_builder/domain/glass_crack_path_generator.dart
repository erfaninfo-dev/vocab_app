import 'dart:math' as math;
import 'dart:ui';

class GlassCrackBranch {
  const GlassCrackBranch({required this.points, required this.width});

  final List<Offset> points;
  final double width;
}

class GlassCrackSegment {
  const GlassCrackSegment({
    required this.seed,
    required this.impactAngle,
    required this.branches,
  });

  final int seed;
  final double impactAngle;
  final List<GlassCrackBranch> branches;
}

abstract final class GlassCrackPathGenerator {
  static GlassCrackSegment generate({
    required int seed,
    required Offset center,
    required double radius,
  }) {
    final random = math.Random(seed);
    final impactAngle = random.nextDouble() * math.pi * 2;
    final impact =
        center +
        Offset(math.cos(impactAngle), math.sin(impactAngle)) * radius * 0.72;

    final branchCount = 2 + random.nextInt(3);
    final branches = <GlassCrackBranch>[];

    for (var b = 0; b < branchCount; b++) {
      final startAngle = impactAngle + (random.nextDouble() - 0.5) * 1.4;
      final length = radius * (0.35 + random.nextDouble() * 0.55);
      final segments = 4 + random.nextInt(4);
      final points = <Offset>[impact];

      var dir = startAngle;
      var cursor = impact;
      for (var i = 0; i < segments; i++) {
        dir += (random.nextDouble() - 0.5) * 0.95;
        final step = length / segments * (0.75 + random.nextDouble() * 0.5);
        cursor = cursor + Offset(math.cos(dir), math.sin(dir)) * step;
        final towardCenter = (center - cursor).distance;
        if (towardCenter < radius * 0.08) break;
        if ((cursor - center).distance > radius * 0.98) {
          cursor =
              center +
              (cursor - center) / (cursor - center).distance * radius * 0.96;
        }
        points.add(cursor);

        if (random.nextDouble() < 0.42 && i > 0 && i < segments - 1) {
          final subLen = radius * (0.08 + random.nextDouble() * 0.18);
          final subDir =
              dir +
              (random.nextBool() ? 1 : -1) *
                  (0.55 + random.nextDouble() * 0.65);
          final subEnd =
              cursor + Offset(math.cos(subDir), math.sin(subDir)) * subLen;
          branches.add(
            GlassCrackBranch(
              points: [cursor, subEnd],
              width: 0.7 + random.nextDouble() * 0.5,
            ),
          );
        }
      }

      branches.insert(
        0,
        GlassCrackBranch(
          points: points,
          width: 1.0 + random.nextDouble() * 0.8,
        ),
      );
    }

    return GlassCrackSegment(
      seed: seed,
      impactAngle: impactAngle,
      branches: branches,
    );
  }

  static Path branchPath(GlassCrackBranch branch, {required double progress}) {
    final path = Path();
    if (branch.points.isEmpty) return path;

    final pts = branch.points;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;

    final total = pts.length - 1;
    final visible = (total * progress.clamp(0.0, 1.0)).floor();
    final partial = (total * progress.clamp(0.0, 1.0)) - visible;

    for (var i = 1; i <= visible && i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    if (visible < total && partial > 0.001) {
      final a = pts[visible];
      final b = pts[visible + 1];
      path.lineTo(
        a.dx + (b.dx - a.dx) * partial,
        a.dy + (b.dy - a.dy) * partial,
      );
    }
    return path;
  }

  static List<GlassCrackSegment> segmentsFromSeeds({
    required List<int> seeds,
    required Offset center,
    required double radius,
  }) {
    return [
      for (final seed in seeds)
        generate(seed: seed, center: center, radius: radius),
    ];
  }
}

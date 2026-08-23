import 'dart:math' as math;
import 'dart:ui';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';
import 'wb_debris_budget.dart';
import 'wb_debris_pool.dart';
import 'wb_fluid_pool.dart';
import 'wb_secondary_body.dart';

/// Spawns debris / secondary / fluid from a shatter recipe under budget rules.
abstract final class WbDebrisSpawner {
  /// Deterministic shard burst into [pool]. Returns number actually spawned.
  static int spawnShards({
    required WbDebrisPool pool,
    required WbShatterRecipe recipe,
    required Offset at,
    required double propRadius,
    required int seed,
    Offset? lastHit,
    double motionScale = 1,
  }) {
    final count = WbDebrisBudget.effectiveShardCount(
      recipe: recipe,
      pool: pool,
      spawnAt: at,
      lastHit: lastHit,
      motionScale: motionScale,
    );
    if (count <= 0) return 0;

    var spawned = 0;
    final shapes = recipe.shapes.isEmpty
        ? const [WbShardShape.shard]
        : recipe.shapes;
    for (var i = 0; i < count; i++) {
      final d = pool.acquire();
      if (d == null) break;
      final spread = recipe.spreadCone;
      final baseAngle = -math.pi / 2;
      final angle =
          baseAngle - spread / 2 + ((i + 1) / (count + 1)) * spread;
      // Mix in seed without Random() alloc — LCG step.
      final r1 = _u01(seed ^ (i * 374761393));
      final r2 = _u01(seed ^ (i * 668265263));
      final r3 = _u01(seed ^ (i * 1274126177));
      final speed = recipe.speedRange.$1 +
          r1 * (recipe.speedRange.$2 - recipe.speedRange.$1);
      final size = recipe.sizeRange.$1 +
          r2 * (recipe.sizeRange.$2 - recipe.sizeRange.$1);
      final life = recipe.lifetime.$1 +
          r3 * (recipe.lifetime.$2 - recipe.lifetime.$1);
      final spin = recipe.spinRange.$1 +
          _u01(seed ^ (i * 97)) * (recipe.spinRange.$2 - recipe.spinRange.$1);

      d.posX = at.dx;
      d.posY = at.dy;
      d.velX = math.cos(angle) * speed;
      d.velY = math.sin(angle) * speed * recipe.gravityScale.clamp(0.3, 2.0);
      d.spin = spin;
      d.angle = angle;
      d.life = life;
      d.maxLife = life;
      d.sizeScale = size * (propRadius / 14).clamp(0.6, 2.2);
      d.shapeIndex = shapes[i % shapes.length].index;
      d.colorIndex = i % 4;
      spawned++;
    }
    return spawned;
  }

  static void spawnSecondaryFromRecipe({
    required WbSecondaryWorld secondary,
    required WbShatterRecipe recipe,
    required Offset at,
    required WbPropArchetype archetype,
    int seed = 0,
  }) {
    final shape = recipe.secondaryShape;
    final n = recipe.secondaryCount;
    if (shape == null || n <= 0) return;

    final kind = switch (shape) {
      WbShardShape.coin => WbSecondaryKind.coin,
      WbShardShape.seed => WbSecondaryKind.seed,
      WbShardShape.droplet => WbSecondaryKind.candy,
      WbShardShape.ember => WbSecondaryKind.fireSpot,
      _ => WbSecondaryKind.candy,
    };

    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * math.pi;
      final speed = 80 + _u01(seed ^ i) * 120;
      secondary.spawn(
        kind: kind,
        at: at,
        vel: Offset(math.cos(a) * speed, math.sin(a) * speed * 0.6),
        radius: kind == WbSecondaryKind.seed ? 4 : 7,
        life: kind == WbSecondaryKind.fireSpot ? 0.9 : 2.0,
        bounceLeft: kind == WbSecondaryKind.coin ? 2 : (kind == WbSecondaryKind.candy ? 1 : 0),
        colorIndex: i % 4,
        effectRadius: kind == WbSecondaryKind.fireSpot ? 18 : 0,
      );
    }
  }

  static void spawnFluidForArchetype({
    required WbFluidPoolSystem fluids,
    required WbPropArchetype archetype,
    required Offset at,
    required double floorY,
  }) {
    final (kind, color, life, r) = switch (archetype) {
      WbPropArchetype.egg => (
          WbFluidKind.yolk,
          const Color(0xFFFFF176),
          2.5,
          16.0,
        ),
      WbPropArchetype.waxBall => (
          WbFluidKind.wax,
          const Color(0xFFFFE082),
          3.0,
          14.0,
        ),
      WbPropArchetype.oilLamp => (
          WbFluidKind.oil,
          const Color(0xFF5D4037),
          1.2,
          18.0,
        ),
      WbPropArchetype.batteryCell => (
          WbFluidKind.acid,
          const Color(0xFF76FF03),
          1.0,
          16.0,
        ),
      WbPropArchetype.watermelon => (
          WbFluidKind.water,
          const Color(0xFFE57373),
          1.1,
          20.0,
        ),
      _ => (null, const Color(0x00000000), 0.0, 0.0),
    };
    if (kind == null) return;
    fluids.spawn(
      kind: kind,
      at: Offset(at.dx, floorY),
      radius: r,
      life: life,
      color: color,
    );
  }

  static double _u01(int seed) {
    var x = seed & 0x7fffffff;
    if (x == 0) x = 1;
    x = (1103515245 * x + 12345) & 0x7fffffff;
    return x / 0x80000000;
  }
}

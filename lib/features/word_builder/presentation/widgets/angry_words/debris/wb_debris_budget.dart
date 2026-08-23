import 'dart:ui';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';
import 'wb_debris_pool.dart';

/// Computes how many shards to spawn under pool / distance / accessibility caps.
abstract final class WbDebrisBudget {
  /// Never starve pops near [lastHit] — far pops lose shards first.
  static int effectiveShardCount({
    required WbShatterRecipe recipe,
    required WbDebrisPool pool,
    required Offset spawnAt,
    Offset? lastHit,
    double motionScale = 1,
    double nearRadius = 160,
  }) {
    final base = recipe.playableShardCount;
    if (base <= 0) return 0;

    final pressure = pool.poolPressure; // 1 empty → 0.3 full
    final distanceFactor = _distanceFactor(spawnAt, lastHit, nearRadius);
    final motion = motionScale.clamp(0.25, 1.0);

    final scaled = base * pressure * distanceFactor * motion;
    // Near hits keep at least half of recipe when pool has any room.
    if (distanceFactor >= 0.99 && pool.freeCount > 0) {
      return scaled.ceil().clamp(1, base);
    }
    if (scaled < 0.5) return 0;
    return scaled.round().clamp(0, base);
  }

  static double _distanceFactor(Offset at, Offset? lastHit, double nearRadius) {
    if (lastHit == null) return 1;
    final d = (at - lastHit).distance;
    if (d <= nearRadius) return 1;
    // Linear falloff to 0.5 beyond 2× nearRadius.
    final t = ((d - nearRadius) / nearRadius).clamp(0.0, 1.0);
    return 1.0 - 0.5 * t;
  }

  /// Sort spawn requests so near-hit props are fulfilled first.
  static void prioritizeNearFirst(
    List<({Offset at, WbShatterRecipe recipe})> requests,
    Offset? lastHit,
  ) {
    if (lastHit == null || requests.length < 2) return;
    requests.sort((a, b) {
      final da = (a.at - lastHit).distanceSquared;
      final db = (b.at - lastHit).distanceSquared;
      return da.compareTo(db);
    });
  }
}

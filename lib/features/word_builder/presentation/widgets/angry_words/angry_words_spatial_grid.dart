import 'dart:ui';

import 'angry_words_physics.dart';

/// Uniform spatial hash for broad-phase bullet↔prop queries (Phase 9).
///
/// Cell size ≈ 2× largest prop diameter so a projectile only checks nearby
/// cells instead of every prop (O(n·m) → ~O(n) under dense walls).
class AngryWordsSpatialGrid {
  AngryWordsSpatialGrid({this.cellSize = 48});

  double cellSize;

  final Map<int, List<AngryWordsPropBubble>> _cells = {};
  double _maxRadius = 22;

  void clear() => _cells.clear();

  int _key(int cx, int cy) => (cx * 73856093) ^ (cy * 19349663);

  void rebuild(List<AngryWordsPropBubble> props) {
    _cells.clear();
    _maxRadius = 8;
    for (final P in props) {
      if (P.removed || P.spawnT < 0.85) continue;
      if (P.radius > _maxRadius) _maxRadius = P.radius;
    }
    // ~2× largest prop diameter.
    cellSize = (_maxRadius * 4).clamp(36.0, 96.0);

    for (final P in props) {
      if (P.removed || P.spawnT < 0.85) continue;
      final cx = (P.pos.dx / cellSize).floor();
      final cy = (P.pos.dy / cellSize).floor();
      final k = _key(cx, cy);
      (_cells[k] ??= <AngryWordsPropBubble>[]).add(P);
    }
  }

  /// Calls [visit] for each live prop whose cell is near [pos] within [radius].
  void forNear(Offset pos, double radius, void Function(AngryWordsPropBubble P) visit) {
    final reach = radius + _maxRadius;
    final minCx = ((pos.dx - reach) / cellSize).floor();
    final maxCx = ((pos.dx + reach) / cellSize).floor();
    final minCy = ((pos.dy - reach) / cellSize).floor();
    final maxCy = ((pos.dy + reach) / cellSize).floor();
    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        final bucket = _cells[_key(cx, cy)];
        if (bucket == null) continue;
        for (final P in bucket) {
          if (P.removed) continue;
          visit(P);
        }
      }
    }
  }
}

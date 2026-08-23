import 'dart:ui';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';

/// One flying debris particle — plain fields only (no nested lists/objects).
class WbDebris {
  WbDebris();

  double posX = 0;
  double posY = 0;
  double velX = 0;
  double velY = 0;
  double spin = 0;
  double angle = 0;
  double life = 0;
  double maxLife = 1;
  double sizeScale = 1;

  /// Index into [WbShardShape.values].
  int shapeIndex = 0;

  /// Index into the debris atlas palette strip (0..3).
  int colorIndex = 0;

  bool alive = false;

  Offset get pos => Offset(posX, posY);
  set pos(Offset o) {
    posX = o.dx;
    posY = o.dy;
  }

  WbShardShape get shape =>
      WbShardShape.values[shapeIndex.clamp(0, WbShardShape.values.length - 1)];

  void reset() {
    posX = posY = velX = velY = spin = angle = life = 0;
    maxLife = 1;
    sizeScale = 1;
    shapeIndex = 0;
    colorIndex = 0;
    alive = false;
  }
}

/// Fixed-capacity debris pool — never allocates in the gameplay loop.
class WbDebrisPool {
  WbDebrisPool({this.capacity = kDefaultCapacity})
      : _items = List<WbDebris>.generate(capacity, (_) => WbDebris());

  static const int kDefaultCapacity = 900;

  final int capacity;
  final List<WbDebris> _items;
  final List<int> _free = [];
  int _alive = 0;

  int get aliveCount => _alive;
  int get freeCount => capacity - _alive;

  /// 1.0 empty → ~0.0 full.
  double get poolPressure {
    if (capacity == 0) return 0;
    final free = freeCount / capacity;
    // Map free∈[0,1] → pressure∈[0.3,1.0] used as spawn multiplier.
    return 0.3 + 0.7 * free;
  }

  Iterable<WbDebris> get aliveItems sync* {
    for (final d in _items) {
      if (d.alive) yield d;
    }
  }

  /// Returns null when the pool is full (caller must drop lowest-priority spawn).
  WbDebris? acquire() {
    if (_free.isNotEmpty) {
      final i = _free.removeLast();
      final d = _items[i];
      d.reset();
      d.alive = true;
      _alive++;
      return d;
    }
    for (var i = 0; i < capacity; i++) {
      if (!_items[i].alive) {
        final d = _items[i];
        d.reset();
        d.alive = true;
        _alive++;
        return d;
      }
    }
    return null;
  }

  void release(WbDebris d) {
    if (!d.alive) return;
    d.alive = false;
    d.reset();
    _alive = (_alive - 1).clamp(0, capacity);
    final i = _items.indexOf(d);
    if (i >= 0) _free.add(i);
  }

  void releaseAll() {
    for (final d in _items) {
      d.alive = false;
      d.reset();
    }
    _free.clear();
    _alive = 0;
  }

  /// Integrate debris; release when life expires. No allocations.
  void step(double dt, {double gravity = 980}) {
    for (var i = 0; i < capacity; i++) {
      final d = _items[i];
      if (!d.alive) continue;
      d.life -= dt;
      if (d.life <= 0) {
        d.alive = false;
        d.reset();
        _alive = (_alive - 1).clamp(0, capacity);
        _free.add(i);
        continue;
      }
      d.velY += gravity * dt * 0.85;
      d.posX += d.velX * dt;
      d.posY += d.velY * dt;
      d.angle += d.spin * dt;
      d.velX *= 0.992;
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';

/// Long-lived secondary bodies (coins, seeds, yolk, pools of fire…).
///
/// Collide with ground; **not** with gun bullets (except yolk nudge — see
/// [WbSecondaryWorld.nudgeYolksWithBullet] which mirrors legacy egg juice).
enum WbSecondaryKind {
  coin,
  candy,
  seed,
  yolk,
  waxPool,
  oilPool,
  acidPool,
  fireSpot,
}

class WbSecondaryBody {
  WbSecondaryBody();

  WbSecondaryKind kind = WbSecondaryKind.seed;
  double posX = 0;
  double posY = 0;
  double velX = 0;
  double velY = 0;
  double radius = 8;
  double life = 2;
  double maxLife = 2;
  double spin = 0;
  double angle = 0;
  int bounceLeft = 0;
  bool onFloor = false;
  bool alive = false;
  int colorIndex = 0;

  /// FireSpot DoT radius multiplier.
  double effectRadius = 0;

  Offset get pos => Offset(posX, posY);
  set pos(Offset o) {
    posX = o.dx;
    posY = o.dy;
  }

  void reset() {
    kind = WbSecondaryKind.seed;
    posX = posY = velX = velY = spin = angle = life = 0;
    maxLife = 2;
    radius = 8;
    bounceLeft = 0;
    onFloor = false;
    alive = false;
    colorIndex = 0;
    effectRadius = 0;
  }
}

/// Fixed pool (~120) for long-lived secondary bodies.
class WbSecondaryPool {
  WbSecondaryPool({this.capacity = kDefaultCapacity})
      : _items = List<WbSecondaryBody>.generate(
          capacity,
          (_) => WbSecondaryBody(),
        );

  static const int kDefaultCapacity = 120;

  final int capacity;
  final List<WbSecondaryBody> _items;
  int _alive = 0;

  int get aliveCount => _alive;

  Iterable<WbSecondaryBody> get aliveItems sync* {
    for (final b in _items) {
      if (b.alive) yield b;
    }
  }

  WbSecondaryBody? acquire() {
    for (var i = 0; i < capacity; i++) {
      if (_items[i].alive) continue;
      final b = _items[i];
      b.reset();
      b.alive = true;
      _alive++;
      return b;
    }
    return null;
  }

  void release(WbSecondaryBody b) {
    if (!b.alive) return;
    b.alive = false;
    b.reset();
    _alive = (_alive - 1).clamp(0, capacity);
  }

  void releaseAll() {
    for (final b in _items) {
      b.alive = false;
      b.reset();
    }
    _alive = 0;
  }
}

/// Steps secondary bodies. Yolk path mirrors [AngryWordsPhysicsWorld] yolk logic.
class WbSecondaryWorld {
  WbSecondaryWorld({
    required this.pool,
    required this.width,
    required this.height,
    this.gravity = 1280,
  });

  final WbSecondaryPool pool;
  double width;
  double height;
  final double gravity;

  double get yolkFloorY => height - 38.0;

  /// Same spill recipe as legacy [AngryWordsPhysicsWorld.spillYolkAt].
  WbSecondaryBody? spillYolkAt(
    Offset at, {
    double fromRadius = 12,
    int seed = 0,
    double simTime = 0,
  }) {
    final rng = math.Random(seed ^ (simTime * 1000).round() ^ at.dx.round());
    final r = (fromRadius * 0.55).clamp(7.0, 14.0);
    final b = pool.acquire();
    if (b == null) return null;
    b.kind = WbSecondaryKind.yolk;
    b.pos = at;
    b.velX = (rng.nextDouble() - 0.5) * 140;
    b.velY = 40 + rng.nextDouble() * 80;
    b.radius = r;
    b.life = 999; // yolk persists until merge/clear (legacy had no TTL)
    b.maxLife = 999;
    b.onFloor = false;
    return b;
  }

  WbSecondaryBody? spawn({
    required WbSecondaryKind kind,
    required Offset at,
    required Offset vel,
    required double radius,
    required double life,
    int bounceLeft = 0,
    int colorIndex = 0,
    double effectRadius = 0,
  }) {
    final b = pool.acquire();
    if (b == null) return null;
    b.kind = kind;
    b.pos = at;
    b.velX = vel.dx;
    b.velY = vel.dy;
    b.radius = radius;
    b.life = life;
    b.maxLife = life;
    b.bounceLeft = bounceLeft;
    b.colorIndex = colorIndex;
    b.effectRadius = effectRadius;
    b.onFloor = false;
    return b;
  }

  void step(double dt, {Offset windVector = Offset.zero}) {
    final floor = yolkFloorY;
    for (final b in pool.aliveItems) {
      b.life -= dt;
      if (b.life <= 0 && b.kind != WbSecondaryKind.yolk) {
        pool.release(b);
        continue;
      }

      switch (b.kind) {
        case WbSecondaryKind.yolk:
          _stepYolk(b, dt, floor, windVector);
        case WbSecondaryKind.coin:
        case WbSecondaryKind.candy:
        case WbSecondaryKind.seed:
          _stepBouncy(b, dt, floor);
        case WbSecondaryKind.waxPool:
        case WbSecondaryKind.oilPool:
        case WbSecondaryKind.acidPool:
          _stepPoolBlob(b, dt, floor);
        case WbSecondaryKind.fireSpot:
          _stepFireSpot(b, dt, floor);
      }
    }
    _mergeYolks(floor);
  }

  void _stepYolk(
    WbSecondaryBody Y,
    double dt,
    double floor,
    Offset windVector,
  ) {
    final g = gravity * 0.92;
    if (!Y.onFloor) {
      Y.velX *= math.exp(-dt * 0.35);
      Y.velY += g * dt;
      Y.posX += Y.velX * dt;
      Y.posY += Y.velY * dt;
      final land = floor - Y.radius * 0.35;
      if (Y.posY >= land) {
        Y.posY = land;
        Y.velX *= 0.72;
        Y.velY = 0;
        Y.onFloor = true;
      }
    } else {
      final windX = windVector.dx * 0.12;
      Y.velX = (Y.velX + windX * dt) * math.exp(-dt * 1.35);
      Y.velY = 0;
      Y.posX += Y.velX * dt;
      Y.posY = floor - Y.radius * 0.35;
    }
    _clampX(Y);
  }

  void _stepBouncy(WbSecondaryBody b, double dt, double floor) {
    b.velY += gravity * dt;
    b.posX += b.velX * dt;
    b.posY += b.velY * dt;
    b.angle += b.spin * dt;
    final land = floor - b.radius;
    if (b.posY >= land) {
      b.posY = land;
      if (b.bounceLeft > 0) {
        b.bounceLeft--;
        b.velY = -b.velY.abs() * 0.55;
        b.velX *= 0.85;
      } else {
        b.velY = 0;
        b.velX *= math.exp(-dt * 2.2);
        b.onFloor = true;
      }
    }
    _clampX(b);
  }

  void _stepPoolBlob(WbSecondaryBody b, double dt, double floor) {
    if (!b.onFloor) {
      b.velY += gravity * 0.6 * dt;
      b.posX += b.velX * dt;
      b.posY += b.velY * dt;
      final land = floor - b.radius * 0.2;
      if (b.posY >= land) {
        b.posY = land;
        b.velY = 0;
        b.velX *= 0.4;
        b.onFloor = true;
      }
    } else {
      // Spread then settle.
      b.radius = math.min(b.radius + dt * 6, b.radius * 1.002 + 0.01);
      b.velX *= math.exp(-dt * 3);
      b.posX += b.velX * dt;
      b.posY = floor - b.radius * 0.2;
    }
    _clampX(b);
  }

  void _stepFireSpot(WbSecondaryBody b, double dt, double floor) {
    b.onFloor = true;
    b.posY = floor - 2;
    b.effectRadius = b.radius * 1.4;
    // Slight flicker via spin unused visually elsewhere.
    b.angle += dt * 8;
  }

  void _clampX(WbSecondaryBody b) {
    final minX = b.radius + 4;
    final maxX = width - b.radius - 4;
    if (b.posX < minX) {
      b.posX = minX;
      b.velX = b.velX.abs() * 0.55;
    } else if (b.posX > maxX) {
      b.posX = maxX;
      b.velX = -b.velX.abs() * 0.55;
    }
  }

  /// Exact merge rules from legacy [_mergeYolks] — no List alloc in hot path.
  void _mergeYolks(double floor) {
    for (var i = 0; i < pool.capacity; i++) {
      final a = pool._items[i];
      if (!a.alive || a.kind != WbSecondaryKind.yolk) continue;
      for (var j = i + 1; j < pool.capacity; j++) {
        final b = pool._items[j];
        if (!b.alive || b.kind != WbSecondaryKind.yolk) continue;
        final dist = (a.pos - b.pos).distance;
        final mergeR = (a.radius + b.radius) * 0.78;
        if (dist > mergeR) continue;
        final areaA = a.radius * a.radius;
        final areaB = b.radius * b.radius;
        final total = areaA + areaB;
        final wA = areaA / total;
        a.posX = a.posX * wA + b.posX * (1 - wA);
        a.posY = a.posY * wA + b.posY * (1 - wA);
        a.velX = a.velX * wA + b.velX * (1 - wA);
        a.velY = a.velY * wA + b.velY * (1 - wA);
        a.radius = math.sqrt(total).clamp(7.0, 36.0);
        a.onFloor = a.onFloor || b.onFloor;
        if (a.onFloor) {
          a.posY = floor - a.radius * 0.35;
          a.velY = 0;
        }
        pool.release(b);
      }
    }
  }

  /// Legacy [_nudgeYolksWithBullet] behavior.
  void nudgeYolksWithBullet(Offset bulletPos, double bulletRadius) {
    for (final Y in pool.aliveItems) {
      if (Y.kind != WbSecondaryKind.yolk) continue;
      final d = (Y.pos - bulletPos).distance;
      if (d > Y.radius + bulletRadius + 4) continue;
      final n = d < 0.1 ? const Offset(1, 0) : (Y.pos - bulletPos) / d;
      Y.velX += n.dx * 220;
      if (!Y.onFloor) Y.velY += n.dy * 80;
      if (Y.onFloor) {
        Y.velX = Y.velX.clamp(-420.0, 420.0);
        Y.velY = 0;
      }
    }
  }

  /// Fire spots deal 1 damage/sec to nearby props — caller applies to HP.
  Iterable<({Offset at, double radius})> activeFireAuras() sync* {
    for (final b in pool.aliveItems) {
      if (b.kind != WbSecondaryKind.fireSpot) continue;
      yield (at: b.pos, radius: b.effectRadius > 0 ? b.effectRadius : b.radius * 1.4);
    }
  }
}

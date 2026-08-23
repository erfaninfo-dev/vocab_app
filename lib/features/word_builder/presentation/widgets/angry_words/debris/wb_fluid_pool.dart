import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

/// Soft ground stains (wax / oil / acid / water / yolk puddle mark).
enum WbFluidKind { wax, oil, acid, water, yolk }

class WbFluidSpot {
  WbFluidSpot();

  WbFluidKind kind = WbFluidKind.water;
  double posX = 0;
  double posY = 0;
  double radius = 12;
  double life = 1;
  double maxLife = 1;
  bool alive = false;
  int colorArgb = 0x88FFEB3B;

  Offset get pos => Offset(posX, posY);

  void reset() {
    kind = WbFluidKind.water;
    posX = posY = radius = life = 0;
    maxLife = 1;
    alive = false;
    colorArgb = 0x88FFEB3B;
  }
}

/// Max 20 concurrent fluid stains; nearby spots merge radii.
class WbFluidPoolSystem {
  WbFluidPoolSystem({this.capacity = kDefaultCapacity})
      : _items = List<WbFluidSpot>.generate(capacity, (_) => WbFluidSpot());

  static const int kDefaultCapacity = 20;
  static const double mergeDistance = 28;

  final int capacity;
  final List<WbFluidSpot> _items;
  int _alive = 0;

  int get aliveCount => _alive;

  Iterable<WbFluidSpot> get aliveItems sync* {
    for (final s in _items) {
      if (s.alive) yield s;
    }
  }

  WbFluidSpot? spawn({
    required WbFluidKind kind,
    required Offset at,
    required double radius,
    required double life,
    required Color color,
  }) {
    // Try merge into nearby live spot of same kind.
    for (final s in _items) {
      if (!s.alive || s.kind != kind) continue;
      if ((s.pos - at).distance > mergeDistance) continue;
      final area = s.radius * s.radius + radius * radius;
      s.radius = math.sqrt(area).clamp(s.radius, 64);
      s.posX = (s.posX + at.dx) * 0.5;
      s.posY = (s.posY + at.dy) * 0.5;
      s.life = math.max(s.life, life);
      s.maxLife = math.max(s.maxLife, life);
      return s;
    }

    for (var i = 0; i < capacity; i++) {
      if (_items[i].alive) continue;
      final s = _items[i];
      s.reset();
      s.alive = true;
      s.kind = kind;
      s.posX = at.dx;
      s.posY = at.dy;
      s.radius = radius;
      s.life = life;
      s.maxLife = life;
      s.colorArgb = color.toARGB32();
      _alive++;
      return s;
    }
    // Evict oldest (lowest life ratio).
    WbFluidSpot? victim;
    var worst = 2.0;
    for (final s in _items) {
      if (!s.alive) continue;
      final t = s.life / s.maxLife;
      if (t < worst) {
        worst = t;
        victim = s;
      }
    }
    if (victim == null) return null;
    victim
      ..kind = kind
      ..posX = at.dx
      ..posY = at.dy
      ..radius = radius
      ..life = life
      ..maxLife = life
      ..colorArgb = color.toARGB32();
    return victim;
  }

  void step(double dt) {
    for (var i = 0; i < capacity; i++) {
      final s = _items[i];
      if (!s.alive) continue;
      s.life -= dt;
      if (s.kind == WbFluidKind.acid) {
        // Bubble: tiny radius pulse encoded via life oscillation unused —
        // painter can use sin(life) for bubbles.
        s.radius += math.sin(s.life * 12) * 0.02;
      }
      if (s.life <= 0) {
        s.alive = false;
        s.reset();
        _alive = (_alive - 1).clamp(0, capacity);
      }
    }
    _mergePass();
  }

  void _mergePass() {
    for (var i = 0; i < capacity; i++) {
      final a = _items[i];
      if (!a.alive) continue;
      for (var j = i + 1; j < capacity; j++) {
        final b = _items[j];
        if (!b.alive || b.kind != a.kind) continue;
        if ((a.pos - b.pos).distance > mergeDistance) continue;
        final area = a.radius * a.radius + b.radius * b.radius;
        a.radius = math.sqrt(area).clamp(8.0, 64.0);
        a.posX = (a.posX + b.posX) * 0.5;
        a.posY = (a.posY + b.posY) * 0.5;
        a.life = math.max(a.life, b.life);
        a.maxLife = math.max(a.maxLife, b.maxLife);
        b.alive = false;
        b.reset();
        _alive = (_alive - 1).clamp(0, capacity);
      }
    }
  }

  void releaseAll() {
    for (final s in _items) {
      s.alive = false;
      s.reset();
    }
    _alive = 0;
  }
}

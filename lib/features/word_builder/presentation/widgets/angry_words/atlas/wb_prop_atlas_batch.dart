import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'wb_prop_atlas.dart';

/// Reusable buffers for one [Canvas.drawRawAtlas] call per frame.
///
/// Allocate once (capacity ≥ max props). Call [beginFrame] then [add] / [addLod]
/// then [draw]. Never `new` the lists each frame.
class WbPropAtlasBatch {
  WbPropAtlasBatch({int initialCapacity = 160}) {
    _ensureCapacity(initialCapacity);
  }

  late Float32List _transforms;
  late Float32List _rects;
  late Int32List _colors;
  int _count = 0;
  int _capacity = 0;

  int get count => _count;

  void beginFrame() => _count = 0;

  void _ensureCapacity(int n) {
    if (n <= _capacity) return;
    final next = math.max(n, _capacity == 0 ? 32 : _capacity * 2);
    final t = Float32List(next * 4);
    final r = Float32List(next * 4);
    final c = Int32List(next);
    if (_capacity > 0) {
      t.setRange(0, _count * 4, _transforms);
      r.setRange(0, _count * 4, _rects);
      c.setRange(0, _count, _colors);
    }
    _transforms = t;
    _rects = r;
    _colors = c;
    _capacity = next;
  }

  /// Packs one sprite. [tint] uses [BlendMode.modulate] at draw time.
  void add({
    required Rect src,
    required double cx,
    required double cy,
    required double scale,
    double rotation = 0,
    Color tint = const Color(0xFFFFFFFF),
  }) {
    _ensureCapacity(_count + 1);
    final i = _count;
    final rst = RSTransform.fromComponents(
      rotation: rotation,
      scale: scale,
      anchorX: src.width * 0.5,
      anchorY: src.height * 0.5,
      translateX: cx,
      translateY: cy,
    );
    final ti = i * 4;
    _transforms[ti] = rst.scos;
    _transforms[ti + 1] = rst.ssin;
    _transforms[ti + 2] = rst.tx;
    _transforms[ti + 3] = rst.ty;

    final ri = i * 4;
    _rects[ri] = src.left;
    _rects[ri + 1] = src.top;
    _rects[ri + 2] = src.right;
    _rects[ri + 3] = src.bottom;

    _colors[i] = tint.toARGB32();
    _count = i + 1;
  }

  void addLod({
    required WbPropAtlas atlas,
    required double cx,
    required double cy,
    required double diameter,
    Color tint = const Color(0xFFFFFFFF),
  }) {
    final src = atlas.lodRect;
    final scale = diameter / src.width;
    add(src: src, cx: cx, cy: cy, scale: scale, tint: tint);
  }

  void addPropSlot({
    required WbPropAtlas atlas,
    required WbAtlasSlotKey key,
    required double cx,
    required double cy,
    required double diameter,
    double rotation = 0,
    Color tint = const Color(0xFFFFFFFF),
  }) {
    final src = atlas.rectFor(key);
    if (src == null) {
      addLod(
        atlas: atlas,
        cx: cx,
        cy: cy,
        diameter: diameter,
        tint: tint,
      );
      return;
    }
    final scale = diameter / src.width;
    add(
      src: src,
      cx: cx,
      cy: cy,
      scale: scale,
      rotation: rotation,
      tint: tint,
    );
  }

  /// Single draw call for all queued props.
  void draw(
    Canvas canvas,
    ui.Image atlas, {
    BlendMode blendMode = BlendMode.modulate,
    Rect? cullRect,
  }) {
    if (_count == 0) return;
    // drawRawAtlas needs exact-length views matching count.
    final transforms = Float32List.sublistView(_transforms, 0, _count * 4);
    final rects = Float32List.sublistView(_rects, 0, _count * 4);
    final colors = Int32List.sublistView(_colors, 0, _count);
    canvas.drawRawAtlas(
      atlas,
      transforms,
      rects,
      colors,
      blendMode,
      cullRect,
      Paint()..isAntiAlias = true,
    );
  }
}

/// Tint helpers for freeze / flash / burn without leaving the atlas path.
abstract final class WbPropAtlasTint {
  static Color modulate({
    required double hitFlash,
    required double freezeT,
    required double burnT,
    double spawnAlpha = 1,
  }) {
    var r = 1.0, g = 1.0, b = 1.0, a = spawnAlpha.clamp(0.0, 1.0);
    if (hitFlash > 0.05) {
      r = math.min(1.0, r + hitFlash * 0.55);
      g = math.min(1.0, g + hitFlash * 0.55);
      b = math.min(1.0, b + hitFlash * 0.45);
    }
    if (freezeT > 0.05) {
      r *= 0.75;
      g *= 0.88;
      b = math.min(1.0, b + 0.25);
    }
    if (burnT > 0.05) {
      r = math.min(1.0, r + 0.35);
      g *= 0.7;
      b *= 0.55;
    }
    return Color.fromARGB(
      (a * 255).round().clamp(0, 255),
      (r * 255).round().clamp(0, 255),
      (g * 255).round().clamp(0, 255),
      (b * 255).round().clamp(0, 255),
    );
  }
}

/// Far-from-impact props use the LOD circle slot (cheaper visually + same atlas).
bool wbPropUseLod({
  required Offset propPos,
  required Offset? lastHit,
  double lodRadius = 160,
}) {
  if (lastHit == null) return false;
  return (propPos - lastHit).distanceSquared > lodRadius * lodRadius;
}

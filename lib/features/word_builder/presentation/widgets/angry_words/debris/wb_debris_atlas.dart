import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';
import 'wb_debris_pool.dart';
import 'wb_shard_paths.dart';

/// 18 shapes × 4 palette colors in one small atlas → one [drawRawAtlas] for debris.
class WbDebrisAtlas {
  WbDebrisAtlas._(this.image, this.rects, this.cellSize);

  final ui.Image image;
  final Map<(WbShardShape, int), Rect> rects;
  final int cellSize;

  static const palette = <Color>[
    Color(0xFFFFF8E1),
    Color(0xFFFF8A65),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
  ];

  Rect? rectFor(WbShardShape shape, int colorIndex) =>
      rects[(shape, colorIndex.clamp(0, palette.length - 1))];

  void dispose() => image.dispose();

  static Future<WbDebrisAtlas> build({int cellSize = 32}) async {
    final shapes = WbShardShape.values;
    const colors = 4;
    final total = shapes.length * colors;
    final cols = 12;
    final rows = (total / cols).ceil();
    final width = cols * cellSize;
    final height = rows * cellSize;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final map = <(WbShardShape, int), Rect>{};
    var index = 0;

    for (final shape in shapes) {
      final unit = WbShardPaths.forShape(shape);
      for (var c = 0; c < colors; c++) {
        final col = index % cols;
        final row = index ~/ cols;
        final cell = Rect.fromLTWH(
          col * cellSize.toDouble(),
          row * cellSize.toDouble(),
          cellSize.toDouble(),
          cellSize.toDouble(),
        );
        map[(shape, c)] = cell;
        final dest = cell.deflate(cellSize * 0.08);
        canvas.save();
        canvas.translate(dest.left, dest.top);
        canvas.scale(dest.width, dest.height);
        final fill = Paint()
          ..color = palette[c]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        // Spark is stroke-like.
        if (shape == WbShardShape.spark) {
          fill
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.08;
        }
        canvas.drawPath(unit, fill);
        canvas.restore();
        index++;
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return WbDebrisAtlas._(image, map, cellSize);
  }
}

/// Reused buffers for debris [drawRawAtlas].
class WbDebrisAtlasBatch {
  WbDebrisAtlasBatch({int initialCapacity = 900}) {
    _ensure(initialCapacity);
  }

  late Float32List _transforms;
  late Float32List _rects;
  late Int32List _colors;
  int _count = 0;
  int _cap = 0;

  int get count => _count;

  void beginFrame() => _count = 0;

  void _ensure(int n) {
    if (n <= _cap) return;
    final next = math.max(n, _cap == 0 ? 64 : _cap * 2);
    final t = Float32List(next * 4);
    final r = Float32List(next * 4);
    final c = Int32List(next);
    if (_cap > 0) {
      t.setRange(0, _count * 4, _transforms);
      r.setRange(0, _count * 4, _rects);
      c.setRange(0, _count, _colors);
    }
    _transforms = t;
    _rects = r;
    _colors = c;
    _cap = next;
  }

  void addFromPool(WbDebrisPool pool, WbDebrisAtlas atlas) {
    beginFrame();
    for (final d in pool.aliveItems) {
      final src = atlas.rectFor(d.shape, d.colorIndex);
      if (src == null) continue;
      _ensure(_count + 1);
      final scale = (d.sizeScale * atlas.cellSize * 0.55) / src.width;
      final lifeT = (d.life / d.maxLife).clamp(0.0, 1.0);
      final alpha = (lifeT * 255).round().clamp(0, 255);
      final rst = RSTransform.fromComponents(
        rotation: d.angle,
        scale: scale,
        anchorX: src.width * 0.5,
        anchorY: src.height * 0.5,
        translateX: d.posX,
        translateY: d.posY,
      );
      final ti = _count * 4;
      _transforms[ti] = rst.scos;
      _transforms[ti + 1] = rst.ssin;
      _transforms[ti + 2] = rst.tx;
      _transforms[ti + 3] = rst.ty;
      _rects[ti] = src.left;
      _rects[ti + 1] = src.top;
      _rects[ti + 2] = src.right;
      _rects[ti + 3] = src.bottom;
      _colors[_count] = (alpha << 24) | 0x00FFFFFF;
      _count++;
    }
  }

  void draw(Canvas canvas, ui.Image atlas) {
    if (_count == 0) return;
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_transforms, 0, _count * 4),
      Float32List.sublistView(_rects, 0, _count * 4),
      Int32List.sublistView(_colors, 0, _count),
      BlendMode.modulate,
      null,
      Paint()..isAntiAlias = true,
    );
  }
}

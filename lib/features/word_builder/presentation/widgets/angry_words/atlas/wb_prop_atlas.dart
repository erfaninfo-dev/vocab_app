import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../../data/prop_archetypes/silhouettes/wb_crack_overlay.dart';
import '../../../../data/prop_archetypes/silhouettes/wb_silhouette.dart';
import '../../../../data/prop_archetypes/silhouettes/wb_silhouettes_registry.dart';
import '../../../../data/prop_archetypes/wb_prop_archetype.dart';

/// Slot address inside a [WbPropAtlas].
class WbAtlasSlotKey {
  const WbAtlasSlotKey({
    required this.archetypeIndex,
    required this.damageStage,
    required this.variant,
  });

  /// 0 = primary, 1 = filler (order passed to [WbPropAtlas.build]).
  final int archetypeIndex;
  final int damageStage;
  final int variant;

  @override
  bool operator ==(Object other) =>
      other is WbAtlasSlotKey &&
      other.archetypeIndex == archetypeIndex &&
      other.damageStage == damageStage &&
      other.variant == variant;

  @override
  int get hashCode => Object.hash(archetypeIndex, damageStage, variant);
}

/// Pre-rasterized prop skins for one stage (primary + filler × stages × variants).
///
/// Built once at stage prep via [PictureRecorder] → [ui.Image]. Never rebuild
/// inside `paint()`. Glow / dynamic cracks stay out of the atlas.
class WbPropAtlas {
  WbPropAtlas._({
    required this.image,
    required this.slotRects,
    required this.cellSize,
    required this.archetypes,
    required this.damageStageCount,
    required this.variantCount,
    required this.lodRect,
  });

  final ui.Image image;

  /// Source rects keyed by [WbAtlasSlotKey].
  final Map<WbAtlasSlotKey, Rect> slotRects;

  final int cellSize;
  final List<WbPropArchetype> archetypes;
  final int damageStageCount;
  final int variantCount;

  /// Reserved simple-circle cell for LOD / tiny props.
  final Rect lodRect;

  int get slotCount => slotRects.length;

  Rect? rectFor(WbAtlasSlotKey key) => slotRects[key];

  void dispose() => image.dispose();

  /// Example: 2 archetypes × 3 stages × 3 variants = 18 (+1 LOD) in 512².
  static Future<WbPropAtlas> build({
    required List<WbPropArchetype> archetypes,
    int damageStageCount = 3,
    int variantCount = 3,
    int atlasSize = 512,
    int cellSize = 64,
  }) async {
    assert(archetypes.isNotEmpty && archetypes.length <= 4);
    assert(damageStageCount >= 1 && variantCount >= 1);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bg = Paint()..color = const Color(0x00000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, atlasSize.toDouble(), atlasSize.toDouble()),
      bg,
    );

    final cols = atlasSize ~/ cellSize;
    var cellIndex = 0;
    final slots = <WbAtlasSlotKey, Rect>{};

    Rect nextCell() {
      final col = cellIndex % cols;
      final row = cellIndex ~/ cols;
      cellIndex++;
      return Rect.fromLTWH(
        col * cellSize.toDouble(),
        row * cellSize.toDouble(),
        cellSize.toDouble(),
        cellSize.toDouble(),
      );
    }

    // LOD circle first.
    final lodRect = nextCell();
    _paintLodCell(canvas, lodRect);

    for (var ai = 0; ai < archetypes.length; ai++) {
      final id = archetypes[ai];
      final spec = kWbArchetypes[id]!;
      final unitPath = silhouetteFor(id);
      for (var stage = 0; stage < damageStageCount; stage++) {
        for (var v = 0; v < variantCount; v++) {
          final cell = nextCell();
          final key = WbAtlasSlotKey(
            archetypeIndex: ai,
            damageStage: stage,
            variant: v,
          );
          slots[key] = cell;
          _paintArchetypeCell(
            canvas: canvas,
            cell: cell,
            unitPath: unitPath,
            spec: spec,
            damageStage: stage,
            variant: v,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(atlasSize, atlasSize);
    picture.dispose();

    return WbPropAtlas._(
      image: image,
      slotRects: slots,
      cellSize: cellSize,
      archetypes: List.unmodifiable(archetypes),
      damageStageCount: damageStageCount,
      variantCount: variantCount,
      lodRect: lodRect,
    );
  }

  static void _paintLodCell(Canvas canvas, Rect cell) {
    final pad = cell.width * 0.08;
    final dest = cell.deflate(pad);
    paintUnitSilhouette(
      canvas,
      kSimplifiedCircleSilhouette,
      dest,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  static void _paintArchetypeCell({
    required Canvas canvas,
    required Rect cell,
    required Path unitPath,
    required WbArchetypeSpec spec,
    required int damageStage,
    required int variant,
  }) {
    final pad = cell.width * 0.06;
    final dest = cell.deflate(pad);
    final base = spec.palette.isNotEmpty
        ? spec.palette[variant % spec.palette.length]
        : const Color(0xFFBDBDBD);
    final fill = Paint()
      ..color = base
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Slight per-variant rotation baked into the atlas cell.
    final cx = dest.center.dx;
    final cy = dest.center.dy;
    canvas.translate(cx, cy);
    canvas.rotate((variant - 1) * 0.12);
    canvas.translate(-cx, -cy);
    paintUnitSilhouette(canvas, unitPath, dest, fill);

    // Static crack stages baked for that damage index (not cascade/spiderweb).
    if (damageStage > 0 && spec.crackStages > 0) {
      final crackPath = damageStage >= 2
          ? WbCrackOverlay.dualCrack()
          : WbCrackOverlay.simpleCrack();
      final stroke = WbCrackOverlay.crackStrokePaint(
        base,
        strokeWidthPx: math.max(1.5, cell.width * 0.03),
      );
      canvas.save();
      canvas.translate(dest.left, dest.top);
      canvas.scale(dest.width, dest.height);
      // Stroke width was in px; undo scale for stable look.
      stroke.strokeWidth = math.max(1.5, cell.width * 0.03) / dest.width;
      canvas.drawPath(crackPath, stroke);
      canvas.restore();
    }
    canvas.restore();
  }
}

import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../../../data/prop_archetypes/silhouettes/wb_crack_overlay.dart';
import '../../../../data/prop_archetypes/silhouettes/wb_silhouette.dart';
import '../../../../data/prop_archetypes/silhouettes/wb_silhouettes_registry.dart';
import '../../../../data/prop_archetypes/wb_prop_archetype.dart';
import 'wb_letter_atlas.dart';
import 'wb_prop_atlas.dart';
import 'wb_prop_atlas_batch.dart';

/// Stage visual pack: prebuilt atlases + reusable batch buffers.
///
/// Create in stage init (async). Dispose when leaving the stage.
class WbStageAtlasPack {
  WbStageAtlasPack({
    required this.propAtlas,
    required this.letterAtlas,
    required this.primary,
    required this.filler,
    WbPropAtlasBatch? propBatch,
    WbPropAtlasBatch? letterBatch,
  })  : propBatch = propBatch ?? WbPropAtlasBatch(),
        letterBatch = letterBatch ?? WbPropAtlasBatch();

  final WbPropAtlas propAtlas;
  final WbLetterAtlas letterAtlas;
  final WbPropArchetype primary;
  final WbPropArchetype filler;
  final WbPropAtlasBatch propBatch;
  final WbPropAtlasBatch letterBatch;

  int archetypeIndexOf(WbPropArchetype id) {
    if (id == primary) return 0;
    if (id == filler) return 1;
    // Unknown → treat as filler slot family.
    return filler == id ? 1 : 0;
  }

  void dispose() {
    propAtlas.dispose();
    letterAtlas.dispose();
  }

  static Future<WbStageAtlasPack> create({
    required WbPropArchetype primary,
    required WbPropArchetype filler,
  }) async {
    final prop = await WbPropAtlas.build(archetypes: [primary, filler]);
    final letters = await WbLetterAtlas.build();
    return WbStageAtlasPack(
      propAtlas: prop,
      letterAtlas: letters,
      primary: primary,
      filler: filler,
    );
  }
}

/// Damage stage index clamped to atlas slots (0..damageStageCount-1).
int wbAtlasDamageStage({
  required int hp,
  required int maxHp,
  required int crackStages,
  required int atlasStages,
}) {
  if (maxHp <= 1 || crackStages <= 0) return 0;
  final lost = (maxHp - hp).clamp(0, maxHp);
  if (lost <= 0) return 0;
  final stage = lost.clamp(1, crackStages);
  return stage.clamp(0, atlasStages - 1);
}

/// Draw glow only for [WbArchetypeSpec.glows] props (saveLayer, few at a time).
void paintPropGlowOverlay({
  required Canvas canvas,
  required Offset center,
  required double radius,
  required Color color,
  required double pulse,
}) {
  final r = radius * (1.15 + 0.08 * pulse);
  canvas.saveLayer(
    Rect.fromCircle(center: center, radius: r + 8),
    Paint(),
  );
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.restore();
}

/// Dynamic crack paths (cascade / spiderweb) — only damaged props.
void paintDynamicCrackOverlay({
  required Canvas canvas,
  required Rect dest,
  required WbBreakBehavior behavior,
  required List<Offset> hitPointsUnit,
  required Color bodyColor,
}) {
  if (hitPointsUnit.isEmpty) return;
  final Path path;
  switch (behavior) {
    case WbBreakBehavior.spiderweb:
      path = WbCrackOverlay.spiderweb(center: hitPointsUnit.last);
    case WbBreakBehavior.crackCascade:
      path = WbCrackOverlay.cascade(hitPointsUnit);
    default:
      return;
  }
  final stroke = WbCrackOverlay.crackStrokePaint(bodyColor);
  // Convert screen stroke to unit space after scale.
  canvas.save();
  canvas.translate(dest.left, dest.top);
  canvas.scale(dest.width, dest.height);
  stroke.strokeWidth = stroke.strokeWidth / dest.width;
  canvas.drawPath(path, stroke);
  canvas.restore();
}

/// Resolve which unit path to use when atlas is unavailable (debug / fallback).
Path fallbackSilhouettePath(WbPropArchetype id, double radiusPx, WbArchetypeSpec spec) {
  if (useSimplifiedSilhouette(radiusPx: radiusPx, spec: spec)) {
    return kSimplifiedCircleSilhouette;
  }
  return silhouetteFor(id);
}

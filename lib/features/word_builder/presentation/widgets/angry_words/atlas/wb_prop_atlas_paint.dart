import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../../data/prop_archetypes/wb_prop_archetype.dart';
import '../angry_words_cargo_plaque.dart';
import '../angry_words_loadout.dart';
import '../angry_words_physics.dart';
import 'wb_prop_atlas.dart';
import 'wb_prop_atlas_batch.dart';
import 'wb_stage_atlas_pack.dart';

/// Fills [pack.propBatch] / letter batch and issues **one** [drawRawAtlas] each.
///
/// Call from the board painter when [WbStageAtlasPack] is ready. Glow and
/// dynamic cracks are painted afterward only for the subset that needs them.
void paintPropsWithAtlas({
  required Canvas canvas,
  required Iterable<AngryWordsPropBubble> props,
  required WbStageAtlasPack pack,
  required double simTime,
  Offset? lastHit,
  double lodRadius = 160,
  bool animateCrackGrowth = true,
}) {
  final batch = pack.propBatch;
  final letters = pack.letterBatch;
  batch.beginFrame();
  letters.beginFrame();

  final glowQueue = <({Offset c, double r, Color color, double pulse})>[];
  final crackQueue = <({Rect dest, WbBreakBehavior behavior, Color body})>[];
  final plaqueQueue = <({Offset c, double r, Color tint, double pulse, bool plaque, String char})>[];

  for (final P in props) {
    if (P.removed || !P.isSpawnVisible) continue;
    if (P.skinEmoji != null) continue; // emoji path stays bespoke

    final spawn = Curves.easeOutBack.transform(P.spawnT.clamp(0.0, 1.0));
    final pulse =
        1.0 + 0.04 * math.sin(simTime * 4.2 + P.phase);
    final r = P.radius * pulse * (0.2 + 0.8 * spawn);
    final diameter = r * 2;

    final arch = P.archetype ??
        _pickArchetype(P.material, pack.primary, pack.filler);
    final archIndex = pack.archetypeIndexOf(arch);
    final spec = kWbArchetypes[arch]!;
    var damageStage = wbAtlasDamageStage(
      hp: P.hp,
      maxHp: P.maxHp,
      crackStages: spec.crackStages,
      atlasStages: pack.propAtlas.damageStageCount,
    );
    if (!animateCrackGrowth &&
        P.hp < P.maxHp &&
        spec.crackStages > 0) {
      damageStage = math.min(
        spec.crackStages,
        pack.propAtlas.damageStageCount - 1,
      );
    }
    final variant = P.palette % pack.propAtlas.variantCount;
    final tint = WbPropAtlasTint.modulate(
      hitFlash: P.hitFlash,
      freezeT: P.freezeT,
      burnT: 0,
      spawnAlpha: spawn.clamp(0.0, 1.0),
    );

    final useLod = diameter < spec.simplifiedBelowRadius * 2 ||
        wbPropUseLod(
          propPos: P.pos,
          lastHit: lastHit,
          lodRadius: lodRadius,
        );

    if (useLod) {
      batch.addLod(
        atlas: pack.propAtlas,
        cx: P.pos.dx,
        cy: P.pos.dy,
        diameter: diameter,
        tint: tint,
      );
    } else {
      batch.addPropSlot(
        atlas: pack.propAtlas,
        key: WbAtlasSlotKey(
          archetypeIndex: archIndex,
          damageStage: damageStage,
          variant: variant,
        ),
        cx: P.pos.dx,
        cy: P.pos.dy,
        diameter: diameter,
        rotation: 0,
        tint: tint,
      );
    }

    final letter = P.cargo?.char;
    if (letter != null && letter.isNotEmpty) {
      plaqueQueue.add((
        c: P.pos,
        r: r,
        tint: const Color(0xFFFFD54F),
        pulse: 0.35 + 0.2 * math.sin(simTime * 5 + P.phase),
        plaque: spec.needsLetterPlaque,
        char: letter,
      ));
      final src = pack.letterAtlas.rectFor(letter);
      if (src != null && !spec.needsLetterPlaque) {
        letters.add(
          src: src,
          cx: P.pos.dx,
          cy: P.pos.dy,
          scale: (r * 1.15) / src.width,
          tint: const Color(0xFFFFFFFF),
        );
      }
    }

    if (spec.glows) {
      glowQueue.add((
        c: P.pos,
        r: r,
        color: spec.palette.isNotEmpty ? spec.palette.first : tint,
        pulse: math.sin(simTime * 6 + P.phase),
      ));
    }

    final behavior = spec.behavior;
    if ((behavior == WbBreakBehavior.crackCascade ||
            behavior == WbBreakBehavior.spiderweb) &&
        P.hp < P.maxHp) {
      crackQueue.add((
        dest: Rect.fromCircle(center: P.pos, radius: r),
        behavior: behavior,
        body: spec.palette.isNotEmpty ? spec.palette.first : tint,
      ));
    }
  }

  batch.draw(canvas, pack.propAtlas.image);

  for (final p in plaqueQueue) {
    AngryWordsCargoPlaque.paintBacking(
      canvas: canvas,
      center: p.c,
      radius: p.r,
      cargoTint: p.tint,
      pulse: p.pulse,
      usePlaque: p.plaque,
    );
    if (p.plaque) {
      AngryWordsCargoPlaque.paintGlyph(
        canvas: canvas,
        center: p.c,
        radius: p.r,
        char: p.char,
      );
    }
  }

  letters.draw(canvas, pack.letterAtlas.image);

  for (final g in glowQueue) {
    paintPropGlowOverlay(
      canvas: canvas,
      center: g.c,
      radius: g.r,
      color: g.color,
      pulse: g.pulse,
    );
  }
  for (final c in crackQueue) {
    paintDynamicCrackOverlay(
      canvas: canvas,
      dest: c.dest,
      behavior: c.behavior,
      hitPointsUnit: const [Offset(0.5, 0.5)],
      bodyColor: c.body,
    );
  }
}

WbPropArchetype _pickArchetype(
  AngryWordsPropMaterial material,
  WbPropArchetype primary,
  WbPropArchetype filler,
) {
  final primaryMat = kWbArchetypes[primary]!.material;
  if (material == primaryMat) return primary;
  return filler;
}

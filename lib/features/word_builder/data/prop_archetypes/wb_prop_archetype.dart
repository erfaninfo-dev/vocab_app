import 'package:flutter/material.dart';

import '../../presentation/widgets/angry_words/angry_words_loadout.dart';

/// Visual identity for a breakable wall item (Angry Words).
///
/// Physics stays on [AngryWordsPropMaterial] (17 materials). Archetypes only
/// describe silhouette, break juice, palette, and sound keys — wired in later
/// STEPs. Do not add members to [AngryWordsPropMaterial] for new items.
enum WbPropArchetype {
  balloon,
  candyBall,
  plushBear,
  giftBox,
  woodCrate,
  paperLantern,
  piggyBank,
  sodaCan,
  egg,
  sprayCan,
  pinata,
  watermelon,
  soapBubble,
  discoBall,
  confettiBall,
  woodBarrel,
  brick,
  tinCan,
  oilDrum,
  sandstone,
  woodTarget,
  ceramicJug,
  glassBottle,
  iceBlock,
  waxBall,
  magmaOrb,
  coconut,
  pumpkin,
  glassPane,
  lightBulb,
  steelPlate,
  magnetSphere,
  crystal,
  oldTv,
  emojiVariety,
  emojiAnimal,
  neonOrb,
  neonTube,
  metalGear,
  batteryCell,
  fireworkShell,
  powderKeg,
  oilLamp,
  concreteBlock,
  rubberTire,
  goldTrophy,
  stoneStatue,
  bronzeBell,
  obsidianGem,
  graniteBlock,
}

/// How the prop dies visually / juicily (behavior implemented in later STEPs).
enum WbBreakBehavior {
  pop,
  shatter,
  crumble,
  splitInHalf,
  caveIn,
  melt,
  burstFluid,
  spillContents,
  dentThenRupture,
  erode,
  crackCascade,
  spiderweb,
  chainExplode,
  ringDecay,
  topple,
  lightDeath,
  magnetize,
  refract,
  fluidFire,
  absorbBounce,
}

/// Debris shape tokens for shatter recipes (rendering later).
enum WbShardShape {
  shard,
  chunk,
  crumb,
  dust,
  scrap,
  sliver,
  seed,
  coin,
  spark,
  droplet,
  fluff,
  ribbon,
  streamer,
  halfShell,
  plate,
  ember,
  prism,
  glint,
}

/// Data-only debris recipe (no simulation code here).
@immutable
class WbShatterRecipe {
  const WbShatterRecipe({
    required this.shardCount,
    required this.shapes,
    required this.sizeRange,
    required this.speedRange,
    required this.spreadCone,
    required this.gravityScale,
    required this.drag,
    required this.lifetime,
    required this.spinRange,
    required this.dustAmount,
    required this.secondaryCount,
    this.secondaryShape,
    required this.screenShake,
  });

  final int shardCount;
  final List<WbShardShape> shapes;

  /// Relative to prop radius.
  final (double, double) sizeRange;

  /// px/s.
  final (double, double) speedRange;

  /// Radians; `2 * pi` = full surround.
  final double spreadCone;
  final double gravityScale;
  final double drag;

  /// Seconds.
  final (double, double) lifetime;

  /// rad/s.
  final (double, double) spinRange;
  final double dustAmount;
  final int secondaryCount;
  final WbShardShape? secondaryShape;
  final double screenShake;
}

/// Full archetype identity — visual / audio / break metadata only.
@immutable
class WbArchetypeSpec {
  const WbArchetypeSpec({
    required this.id,
    required this.labelFa,
    required this.labelEn,
    required this.material,
    required this.hpOverride,
    required this.crackStages,
    required this.behavior,
    required this.recipe,
    required this.palette,
    required this.soundFamily,
    required this.soundPitch,
    required this.aspectRatio,
    required this.glows,
    required this.holdsCargoWell,
  });

  final WbPropArchetype id;
  final String labelFa;
  final String labelEn;

  /// Borrowed physics material — must stay one of the existing 17.
  final AngryWordsPropMaterial material;

  /// `0` → use [AngryWordsLoadout.rollHpFor] for [material].
  final int hpOverride;
  final int crackStages;
  final WbBreakBehavior behavior;
  final WbShatterRecipe recipe;
  final List<Color> palette;
  final String soundFamily;
  final double soundPitch;
  final double aspectRatio;
  final bool glows;
  final bool holdsCargoWell;
}

/// Registry filled in STEP 2. Empty here so gameplay is unchanged in STEP 1.
const Map<WbPropArchetype, WbArchetypeSpec> kWbArchetypes = {};

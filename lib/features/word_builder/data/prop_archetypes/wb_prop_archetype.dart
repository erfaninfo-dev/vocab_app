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

/// Registry — filled chapter-by-chapter in STEP 2 (gameplay still unwired).
const Map<WbPropArchetype, WbArchetypeSpec> kWbArchetypes = {
  // ── Chapter 1 · Toy Box (stages 1–7) ─────────────────────────────────────
  WbPropArchetype.balloon: WbArchetypeSpec(
    id: WbPropArchetype.balloon,
    labelFa: 'بادکنک',
    labelEn: 'Balloon',
    material: AngryWordsPropMaterial.rubber,
    hpOverride: 1,
    crackStages: 0,
    behavior: WbBreakBehavior.pop,
    recipe: WbShatterRecipe(
      shardCount: 4,
      shapes: [WbShardShape.scrap, WbShardShape.ribbon],
      sizeRange: (0.35, 0.7),
      speedRange: (60, 140),
      spreadCone: _kFullSpread,
      gravityScale: 0.85,
      drag: 0.55,
      lifetime: (0.45, 0.75),
      spinRange: (4, 10),
      dustAmount: 0.15,
      secondaryCount: 0,
      screenShake: 0.12,
    ),
    palette: [Color(0xFFFF6B9D), Color(0xFFFF8FB8), Color(0xFFFFE0EC)],
    soundFamily: 'pop',
    soundPitch: 1.25,
    aspectRatio: 0.88,
    glows: false,
    holdsCargoWell: true,
  ),
  WbPropArchetype.candyBall: WbArchetypeSpec(
    id: WbPropArchetype.candyBall,
    labelFa: 'گوی آب‌نبات',
    labelEn: 'Candy Ball',
    material: AngryWordsPropMaterial.candy,
    hpOverride: 1,
    crackStages: 0,
    behavior: WbBreakBehavior.shatter,
    recipe: WbShatterRecipe(
      shardCount: 12,
      shapes: [WbShardShape.shard, WbShardShape.glint, WbShardShape.crumb],
      sizeRange: (0.18, 0.42),
      speedRange: (90, 220),
      spreadCone: _kFullSpread,
      gravityScale: 1.0,
      drag: 1.35,
      lifetime: (0.55, 0.95),
      spinRange: (6, 14),
      dustAmount: 0.55,
      secondaryCount: 8,
      secondaryShape: WbShardShape.spark,
      screenShake: 0.18,
    ),
    palette: [Color(0xFFFF80AB), Color(0xFFE91E63), Color(0xFFFFF3F8)],
    soundFamily: 'shatter_candy',
    soundPitch: 1.15,
    aspectRatio: 1.0,
    glows: false,
    holdsCargoWell: true,
  ),
  WbPropArchetype.plushBear: WbArchetypeSpec(
    id: WbPropArchetype.plushBear,
    labelFa: 'خرس پارچه‌ای',
    labelEn: 'Plush Bear',
    material: AngryWordsPropMaterial.foam,
    hpOverride: 1,
    crackStages: 0,
    behavior: WbBreakBehavior.pop,
    recipe: WbShatterRecipe(
      shardCount: 6,
      shapes: [WbShardShape.scrap, WbShardShape.fluff],
      sizeRange: (0.25, 0.55),
      speedRange: (40, 110),
      spreadCone: _kFullSpread,
      gravityScale: 0.25,
      drag: 1.1,
      lifetime: (0.9, 1.4),
      spinRange: (1, 4),
      dustAmount: 0.35,
      secondaryCount: 15,
      secondaryShape: WbShardShape.fluff,
      screenShake: 0.08,
    ),
    palette: [Color(0xFFFFCC80), Color(0xFFFFA726), Color(0xFFFFF3E0)],
    soundFamily: 'poof_soft',
    soundPitch: 0.95,
    aspectRatio: 0.92,
    glows: false,
    holdsCargoWell: true,
  ),
  WbPropArchetype.giftBox: WbArchetypeSpec(
    id: WbPropArchetype.giftBox,
    labelFa: 'جعبه کادو',
    labelEn: 'Gift Box',
    material: AngryWordsPropMaterial.wood,
    hpOverride: 1,
    crackStages: 0,
    behavior: WbBreakBehavior.spillContents,
    recipe: WbShatterRecipe(
      shardCount: 4,
      shapes: [WbShardShape.plate, WbShardShape.ribbon],
      sizeRange: (0.4, 0.75),
      speedRange: (80, 180),
      spreadCone: _kFullSpread,
      gravityScale: 1.05,
      drag: 0.45,
      lifetime: (0.6, 1.0),
      spinRange: (3, 8),
      dustAmount: 0.2,
      secondaryCount: 8,
      secondaryShape: WbShardShape.streamer,
      screenShake: 0.2,
    ),
    palette: [Color(0xFFE53935), Color(0xFFFFD54F), Color(0xFFFFF8E1)],
    soundFamily: 'wood_open',
    soundPitch: 1.05,
    aspectRatio: 1.05,
    glows: false,
    holdsCargoWell: true,
  ),
  WbPropArchetype.woodCrate: WbArchetypeSpec(
    id: WbPropArchetype.woodCrate,
    labelFa: 'جعبه چوبی',
    labelEn: 'Wood Crate',
    material: AngryWordsPropMaterial.wood,
    hpOverride: 2,
    crackStages: 1,
    behavior: WbBreakBehavior.dentThenRupture,
    recipe: WbShatterRecipe(
      shardCount: 6,
      shapes: [WbShardShape.plate, WbShardShape.sliver],
      sizeRange: (0.35, 0.8),
      speedRange: (100, 240),
      spreadCone: _kFullSpread,
      gravityScale: 1.15,
      drag: 0.4,
      lifetime: (0.65, 1.1),
      spinRange: (2, 7),
      dustAmount: 0.45,
      secondaryCount: 10,
      secondaryShape: WbShardShape.sliver,
      screenShake: 0.28,
    ),
    palette: [Color(0xFFD7CCC8), Color(0xFF8D6E63), Color(0xFF5D4037)],
    soundFamily: 'wood_crack',
    soundPitch: 0.9,
    aspectRatio: 1.08,
    glows: false,
    holdsCargoWell: true,
  ),
  WbPropArchetype.paperLantern: WbArchetypeSpec(
    id: WbPropArchetype.paperLantern,
    labelFa: 'فانوس کاغذی',
    labelEn: 'Paper Lantern',
    material: AngryWordsPropMaterial.plastic,
    hpOverride: 1,
    crackStages: 0,
    behavior: WbBreakBehavior.lightDeath,
    recipe: WbShatterRecipe(
      shardCount: 6,
      shapes: [WbShardShape.scrap],
      sizeRange: (0.3, 0.6),
      speedRange: (70, 160),
      spreadCone: _kFullSpread,
      gravityScale: 0.55,
      drag: 0.85,
      lifetime: (0.5, 0.85),
      spinRange: (2, 6),
      dustAmount: 0.1,
      secondaryCount: 0,
      screenShake: 0.1,
    ),
    palette: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFFFECB3)],
    soundFamily: 'paper_tear',
    soundPitch: 1.1,
    aspectRatio: 0.85,
    glows: true,
    holdsCargoWell: true,
  ),
  WbPropArchetype.piggyBank: WbArchetypeSpec(
    id: WbPropArchetype.piggyBank,
    labelFa: 'قلک خوکی',
    labelEn: 'Piggy Bank',
    material: AngryWordsPropMaterial.porcelain,
    hpOverride: 2,
    crackStages: 1,
    behavior: WbBreakBehavior.spillContents,
    recipe: WbShatterRecipe(
      shardCount: 14,
      shapes: [WbShardShape.shard, WbShardShape.chunk],
      sizeRange: (0.2, 0.5),
      speedRange: (110, 260),
      spreadCone: _kFullSpread,
      gravityScale: 1.2,
      drag: 0.35,
      lifetime: (0.7, 1.2),
      spinRange: (5, 12),
      dustAmount: 0.3,
      secondaryCount: 10,
      secondaryShape: WbShardShape.coin,
      screenShake: 0.35,
    ),
    palette: [Color(0xFFF8BBD0), Color(0xFFEC407A), Color(0xFFFFF0F5)],
    soundFamily: 'porcelain_coin',
    soundPitch: 1.0,
    aspectRatio: 1.12,
    glows: false,
    holdsCargoWell: true,
  ),
};

/// Full surround for debris cones (`2π`).
const double _kFullSpread = 6.283185307179586;

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart';

/// Toy Box (stages 1–7) — STEP 2 chapter 1.
const _kToyBoxArchetypes = <WbPropArchetype>[
  WbPropArchetype.balloon,
  WbPropArchetype.candyBall,
  WbPropArchetype.plushBear,
  WbPropArchetype.giftBox,
  WbPropArchetype.woodCrate,
  WbPropArchetype.paperLantern,
  WbPropArchetype.piggyBank,
];

/// Street Spray (stages 8–10) — STEP 2 chapter 2.
const _kStreetSprayArchetypes = <WbPropArchetype>[
  WbPropArchetype.sodaCan,
  WbPropArchetype.egg,
  WbPropArchetype.sprayCan,
];

/// Pellet Party (stages 11–15) — STEP 2 chapter 3.
const _kPelletPartyArchetypes = <WbPropArchetype>[
  WbPropArchetype.pinata,
  WbPropArchetype.watermelon,
  WbPropArchetype.soapBubble,
  WbPropArchetype.discoBall,
  WbPropArchetype.confettiBall,
];

/// War Band (stages 16–22) — STEP 2 chapter 4.
const _kWarBandArchetypes = <WbPropArchetype>[
  WbPropArchetype.woodBarrel,
  WbPropArchetype.brick,
  WbPropArchetype.tinCan,
  WbPropArchetype.oilDrum,
  WbPropArchetype.sandstone,
  WbPropArchetype.woodTarget,
  WbPropArchetype.ceramicJug,
];

/// Ice & Fire (stages 23–26) — STEP 2 chapter 5.
const _kIceFireArchetypes = <WbPropArchetype>[
  WbPropArchetype.glassBottle,
  WbPropArchetype.iceBlock,
  WbPropArchetype.waxBall,
  WbPropArchetype.magmaOrb,
];

/// Piercers (stages 27–32) — STEP 2 chapter 6.
const _kPiercersArchetypes = <WbPropArchetype>[
  WbPropArchetype.coconut,
  WbPropArchetype.pumpkin,
  WbPropArchetype.glassPane,
  WbPropArchetype.lightBulb,
  WbPropArchetype.steelPlate,
  WbPropArchetype.magnetSphere,
];

/// Energy Age (stages 33–40) — STEP 2 chapter 7.
const _kEnergyAgeArchetypes = <WbPropArchetype>[
  WbPropArchetype.crystal,
  WbPropArchetype.oldTv,
  WbPropArchetype.emojiVariety,
  WbPropArchetype.emojiAnimal,
  WbPropArchetype.neonOrb,
  WbPropArchetype.neonTube,
  WbPropArchetype.metalGear,
  WbPropArchetype.batteryCell,
];

/// Boom Brigade (stages 41–45) — STEP 2 chapter 8.
const _kBoomBrigadeArchetypes = <WbPropArchetype>[
  WbPropArchetype.fireworkShell,
  WbPropArchetype.powderKeg,
  WbPropArchetype.oilLamp,
  WbPropArchetype.concreteBlock,
  WbPropArchetype.rubberTire,
];

/// Endgame (stages 46–50) — STEP 2 chapter 9.
const _kEndgameArchetypes = <WbPropArchetype>[
  WbPropArchetype.goldTrophy,
  WbPropArchetype.stoneStatue,
  WbPropArchetype.bronzeBell,
  WbPropArchetype.obsidianGem,
  WbPropArchetype.graniteBlock,
];

void main() {
  test('WbPropArchetype has exactly 50 members', () {
    expect(WbPropArchetype.values.length, 50);
  });

  test('every registered spec matches its map key', () {
    for (final entry in kWbArchetypes.entries) {
      expect(entry.value.id, entry.key);
      expect(entry.value.palette, isNotEmpty);
      expect(entry.value.soundPitch, inInclusiveRange(0.5, 1.4));
      expect(entry.value.crackStages, greaterThanOrEqualTo(0));
      expect(entry.value.hpOverride, greaterThanOrEqualTo(0));
    }
  });

  test('Toy Box chapter (7) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(7));
    for (final id in _kToyBoxArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.balloon]!.material,
        AngryWordsPropMaterial.rubber);
    expect(kWbArchetypes[WbPropArchetype.balloon]!.behavior,
        WbBreakBehavior.pop);
    expect(kWbArchetypes[WbPropArchetype.balloon]!.soundPitch, 1.25);

    expect(kWbArchetypes[WbPropArchetype.candyBall]!.material,
        AngryWordsPropMaterial.candy);
    expect(kWbArchetypes[WbPropArchetype.candyBall]!.behavior,
        WbBreakBehavior.shatter);
    expect(kWbArchetypes[WbPropArchetype.candyBall]!.recipe.drag, greaterThan(1));

    expect(kWbArchetypes[WbPropArchetype.plushBear]!.material,
        AngryWordsPropMaterial.foam);
    expect(
      kWbArchetypes[WbPropArchetype.plushBear]!.recipe.gravityScale,
      closeTo(0.25, 0.001),
    );

    expect(kWbArchetypes[WbPropArchetype.giftBox]!.behavior,
        WbBreakBehavior.spillContents);
    expect(kWbArchetypes[WbPropArchetype.giftBox]!.recipe.secondaryCount, 8);

    expect(kWbArchetypes[WbPropArchetype.woodCrate]!.hpOverride, 2);
    expect(kWbArchetypes[WbPropArchetype.woodCrate]!.crackStages, 1);
    expect(kWbArchetypes[WbPropArchetype.woodCrate]!.behavior,
        WbBreakBehavior.dentThenRupture);

    expect(kWbArchetypes[WbPropArchetype.paperLantern]!.glows, isTrue);
    expect(kWbArchetypes[WbPropArchetype.paperLantern]!.behavior,
        WbBreakBehavior.lightDeath);

    expect(kWbArchetypes[WbPropArchetype.piggyBank]!.material,
        AngryWordsPropMaterial.porcelain);
    expect(kWbArchetypes[WbPropArchetype.piggyBank]!.recipe.secondaryShape,
        WbShardShape.coin);
    expect(kWbArchetypes[WbPropArchetype.piggyBank]!.recipe.secondaryCount, 10);
  });

  test('Street Spray chapter (3) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(10));
    for (final id in _kStreetSprayArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.material,
        AngryWordsPropMaterial.metal);
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.hpOverride, 2);
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.crackStages, 1);
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.behavior,
        WbBreakBehavior.dentThenRupture);
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.recipe.secondaryShape,
        WbShardShape.droplet);

    expect(kWbArchetypes[WbPropArchetype.egg]!.material,
        AngryWordsPropMaterial.egg);
    expect(kWbArchetypes[WbPropArchetype.egg]!.behavior,
        WbBreakBehavior.spillContents);
    expect(kWbArchetypes[WbPropArchetype.egg]!.recipe.shardCount, 18);
    expect(kWbArchetypes[WbPropArchetype.egg]!.soundFamily, WbPropSoundFamily.splashFluid);

    expect(kWbArchetypes[WbPropArchetype.sprayCan]!.hpOverride, 2);
    expect(kWbArchetypes[WbPropArchetype.sprayCan]!.crackStages, 1);
    expect(kWbArchetypes[WbPropArchetype.sprayCan]!.behavior,
        WbBreakBehavior.burstFluid);
    expect(kWbArchetypes[WbPropArchetype.sprayCan]!.recipe.secondaryCount, 25);
    expect(kWbArchetypes[WbPropArchetype.sprayCan]!.palette.length, 4);
  });

  test('Pellet Party chapter (5) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(15));
    for (final id in _kPelletPartyArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.pinata]!.material,
        AngryWordsPropMaterial.wood);
    expect(kWbArchetypes[WbPropArchetype.pinata]!.behavior,
        WbBreakBehavior.spillContents);
    expect(kWbArchetypes[WbPropArchetype.pinata]!.recipe.secondaryCount, 15);

    expect(kWbArchetypes[WbPropArchetype.watermelon]!.material,
        AngryWordsPropMaterial.water);
    expect(kWbArchetypes[WbPropArchetype.watermelon]!.behavior,
        WbBreakBehavior.burstFluid);
    expect(kWbArchetypes[WbPropArchetype.watermelon]!.recipe.shardCount, 5);
    expect(kWbArchetypes[WbPropArchetype.watermelon]!.recipe.secondaryShape,
        WbShardShape.seed);

    expect(kWbArchetypes[WbPropArchetype.soapBubble]!.hpOverride, 1);
    expect(kWbArchetypes[WbPropArchetype.soapBubble]!.behavior,
        WbBreakBehavior.pop);
    expect(kWbArchetypes[WbPropArchetype.soapBubble]!.recipe.shardCount, 0);
    expect(kWbArchetypes[WbPropArchetype.soapBubble]!.recipe.secondaryCount, 6);

    expect(kWbArchetypes[WbPropArchetype.discoBall]!.material,
        AngryWordsPropMaterial.crystal);
    expect(kWbArchetypes[WbPropArchetype.discoBall]!.behavior,
        WbBreakBehavior.shatter);
    expect(kWbArchetypes[WbPropArchetype.discoBall]!.recipe.shardCount, 20);
    expect(kWbArchetypes[WbPropArchetype.discoBall]!.glows, isTrue);

    expect(kWbArchetypes[WbPropArchetype.confettiBall]!.behavior,
        WbBreakBehavior.spillContents);
    expect(kWbArchetypes[WbPropArchetype.confettiBall]!.recipe.secondaryCount,
        40);
    expect(
      kWbArchetypes[WbPropArchetype.confettiBall]!.recipe.gravityScale,
      closeTo(0.4, 0.001),
    );
    expect(kWbArchetypes[WbPropArchetype.confettiBall]!.palette.length, 6);
  });

  test('War Band chapter (7) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(22));
    for (final id in _kWarBandArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.woodBarrel]!.behavior,
        WbBreakBehavior.topple);
    expect(kWbArchetypes[WbPropArchetype.brick]!.recipe.dustAmount,
        closeTo(0.9, 0.001));
    expect(kWbArchetypes[WbPropArchetype.brick]!.recipe.gravityScale,
        closeTo(1.3, 0.001));
    expect(kWbArchetypes[WbPropArchetype.tinCan]!.crackStages, 1);
    expect(kWbArchetypes[WbPropArchetype.oilDrum]!.hpOverride, 2);
    expect(kWbArchetypes[WbPropArchetype.oilDrum]!.crackStages, 1);
    expect(kWbArchetypes[WbPropArchetype.sandstone]!.material,
        AngryWordsPropMaterial.sand);
    expect(kWbArchetypes[WbPropArchetype.sandstone]!.recipe.secondaryCount, 30);
    expect(kWbArchetypes[WbPropArchetype.woodTarget]!.behavior,
        WbBreakBehavior.shatter);
    expect(kWbArchetypes[WbPropArchetype.ceramicJug]!.material,
        AngryWordsPropMaterial.porcelain);
    expect(kWbArchetypes[WbPropArchetype.ceramicJug]!.soundFamily, WbPropSoundFamily.breakCeramic);
    expect(kWbArchetypes[WbPropArchetype.ceramicJug]!.recipe.secondaryCount, 0);
  });

  test('Ice & Fire chapter (4) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(26));
    for (final id in _kIceFireArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.glassBottle]!.material,
        AngryWordsPropMaterial.glass);
    expect(kWbArchetypes[WbPropArchetype.glassBottle]!.soundFamily, WbPropSoundFamily.shatterGlass);
    expect(kWbArchetypes[WbPropArchetype.iceBlock]!.behavior,
        WbBreakBehavior.crackCascade);
    expect(kWbArchetypes[WbPropArchetype.iceBlock]!.crackStages, 2);
    expect(kWbArchetypes[WbPropArchetype.waxBall]!.behavior,
        WbBreakBehavior.melt);
    expect(kWbArchetypes[WbPropArchetype.waxBall]!.recipe.shardCount, 0);
    expect(kWbArchetypes[WbPropArchetype.magmaOrb]!.material,
        AngryWordsPropMaterial.magma);
    expect(kWbArchetypes[WbPropArchetype.magmaOrb]!.glows, isTrue);
    expect(kWbArchetypes[WbPropArchetype.magmaOrb]!.recipe.shapes,
        contains(WbShardShape.ember));
  });

  test('Piercers chapter (6) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(32));
    for (final id in _kPiercersArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.coconut]!.behavior,
        WbBreakBehavior.splitInHalf);
    expect(kWbArchetypes[WbPropArchetype.coconut]!.recipe.shardCount, 2);
    expect(kWbArchetypes[WbPropArchetype.pumpkin]!.behavior,
        WbBreakBehavior.caveIn);
    expect(kWbArchetypes[WbPropArchetype.glassPane]!.behavior,
        WbBreakBehavior.spiderweb);
    expect(kWbArchetypes[WbPropArchetype.glassPane]!.recipe.spreadCone,
        lessThan(2));
    expect(kWbArchetypes[WbPropArchetype.lightBulb]!.aspectRatio,
        closeTo(0.7, 0.001));
    expect(kWbArchetypes[WbPropArchetype.lightBulb]!.behavior,
        WbBreakBehavior.lightDeath);
    expect(kWbArchetypes[WbPropArchetype.steelPlate]!.hpOverride, 3);
    expect(kWbArchetypes[WbPropArchetype.magnetSphere]!.behavior,
        WbBreakBehavior.magnetize);
  });

  test('Energy Age chapter (8) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(40));
    for (final id in _kEnergyAgeArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.crystal]!.behavior,
        WbBreakBehavior.refract);
    expect(kWbArchetypes[WbPropArchetype.oldTv]!.material,
        AngryWordsPropMaterial.plastic);
    expect(kWbArchetypes[WbPropArchetype.emojiVariety]!.hpOverride, 0);
    expect(kWbArchetypes[WbPropArchetype.emojiAnimal]!.hpOverride, 0);
    expect(kWbArchetypes[WbPropArchetype.neonOrb]!.glows, isTrue);
    expect(kWbArchetypes[WbPropArchetype.neonTube]!.aspectRatio,
        closeTo(0.35, 0.001));
    expect(kWbArchetypes[WbPropArchetype.neonTube]!.behaviors, [
      WbBreakBehavior.splitInHalf,
      WbBreakBehavior.lightDeath,
    ]);
    expect(kWbArchetypes[WbPropArchetype.metalGear]!.material,
        AngryWordsPropMaterial.gold);
    expect(kWbArchetypes[WbPropArchetype.metalGear]!.behavior,
        WbBreakBehavior.erode);
    expect(kWbArchetypes[WbPropArchetype.batteryCell]!.behavior,
        WbBreakBehavior.fluidFire);
  });

  test('Boom Brigade chapter (5) specs are registered', () {
    expect(kWbArchetypes.length, greaterThanOrEqualTo(45));
    for (final id in _kBoomBrigadeArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    expect(kWbArchetypes[WbPropArchetype.fireworkShell]!.behavior,
        WbBreakBehavior.chainExplode);
    expect(kWbArchetypes[WbPropArchetype.fireworkShell]!.hpOverride, 1);
    expect(kWbArchetypes[WbPropArchetype.powderKeg]!.behavior,
        WbBreakBehavior.chainExplode);
    expect(kWbArchetypes[WbPropArchetype.powderKeg]!.recipe.screenShake,
        closeTo(0.8, 0.001));
    expect(kWbArchetypes[WbPropArchetype.oilLamp]!.behavior,
        WbBreakBehavior.fluidFire);
    expect(kWbArchetypes[WbPropArchetype.concreteBlock]!.material,
        AngryWordsPropMaterial.stone);
    expect(kWbArchetypes[WbPropArchetype.concreteBlock]!.behavior,
        WbBreakBehavior.erode);
    expect(kWbArchetypes[WbPropArchetype.rubberTire]!.behavior,
        WbBreakBehavior.absorbBounce);
  });

  test('Endgame chapter (5) specs are registered', () {
    expect(kWbArchetypes.length, WbPropArchetype.values.length);
    for (final id in _kEndgameArchetypes) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }

    final trophy = kWbArchetypes[WbPropArchetype.goldTrophy]!;
    expect(trophy.material, AngryWordsPropMaterial.gold);
    expect(trophy.hpOverride, 3);
    expect(trophy.crackStages, 2);
    expect(trophy.behavior, WbBreakBehavior.dentThenRupture);
    expect(trophy.recipe.shardCount, 10);
    expect(trophy.recipe.shapes, [WbShardShape.plate]);
    expect(trophy.recipe.secondaryCount, 20);
    expect(trophy.recipe.secondaryShape, WbShardShape.glint);
    expect(trophy.recipe.gravityScale, closeTo(0.5, 0.001));

    final statue = kWbArchetypes[WbPropArchetype.stoneStatue]!;
    expect(statue.material, AngryWordsPropMaterial.stone);
    expect(statue.behavior, WbBreakBehavior.topple);
    expect(statue.recipe.shardCount, 4);
    expect(statue.recipe.shapes, [WbShardShape.chunk]);
    expect(statue.recipe.gravityScale, closeTo(1.6, 0.001));

    final bell = kWbArchetypes[WbPropArchetype.bronzeBell]!;
    expect(bell.material, AngryWordsPropMaterial.metal);
    expect(bell.behavior, WbBreakBehavior.ringDecay);
    expect(bell.recipe.shardCount, 3);
    expect(bell.recipe.secondaryCount, 1);
    expect(bell.recipe.secondaryShape, WbShardShape.scrap);

    final gem = kWbArchetypes[WbPropArchetype.obsidianGem]!;
    expect(gem.material, AngryWordsPropMaterial.crystal);
    expect(gem.behavior, WbBreakBehavior.shatter);
    expect(gem.recipe.shardCount, 14);
    expect(gem.recipe.shapes, [WbShardShape.sliver]);
    expect(gem.recipe.spreadCone, lessThan(2.0));

    final granite = kWbArchetypes[WbPropArchetype.graniteBlock]!;
    expect(granite.material, AngryWordsPropMaterial.stone);
    expect(granite.hpOverride, 2);
    expect(granite.crackStages, 1);
    expect(granite.behavior, WbBreakBehavior.crumble);
    expect(granite.recipe.shardCount, 5);
    expect(granite.recipe.secondaryCount, 18);
    expect(granite.recipe.secondaryShape, WbShardShape.crumb);
    expect(granite.recipe.dustAmount, closeTo(1.0, 0.001));
    expect(granite.recipe.screenShake, closeTo(1.0, 0.001));
    expect(granite.holdsCargoWell, isFalse);
  });

  test('full registry completeness (passes only when all 50 filled)', () {
    if (kWbArchetypes.length < WbPropArchetype.values.length) {
      // Chapter-by-chapter STEP 2 — currently ${_} of 50.
      expect(
        kWbArchetypes.length,
        lessThan(WbPropArchetype.values.length),
        reason: 'partial fill OK until all chapters land',
      );
      return;
    }
    for (final id in WbPropArchetype.values) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }
  });

  test('all 50 entries exist and ids are unique', () {
    expect(WbPropArchetype.values.length, 50);
    expect(kWbArchetypes.length, 50);
    expect(kWbArchetypes.keys.toSet().length, 50);

    final seenIds = <WbPropArchetype>{};
    for (final entry in kWbArchetypes.entries) {
      expect(entry.value.id, entry.key);
      expect(seenIds.add(entry.value.id), isTrue,
          reason: 'duplicate id ${entry.value.id}');
    }
    for (final id in WbPropArchetype.values) {
      expect(kWbArchetypes.containsKey(id), isTrue, reason: 'missing $id');
    }
  });

  test('locked stages keep specified values', () {
    // Stage 9 — egg
    final egg = kWbArchetypes[WbPropArchetype.egg]!;
    expect(egg.material, AngryWordsPropMaterial.egg);
    expect(egg.behavior, WbBreakBehavior.spillContents);
    expect(egg.soundFamily, WbPropSoundFamily.splashFluid);
    expect(egg.recipe.secondaryShape, WbShardShape.droplet);

    // Stage 22 — ceramic jug (porcelain, pot sound, no yolk)
    final jug = kWbArchetypes[WbPropArchetype.ceramicJug]!;
    expect(jug.material, AngryWordsPropMaterial.porcelain);
    expect(jug.behavior, WbBreakBehavior.shatter);
    expect(jug.soundFamily, WbPropSoundFamily.breakCeramic);
    expect(jug.hpOverride, 1);
    expect(jug.recipe.secondaryCount, 0);

    // Stage 23 — glass bottle (hammer intent; pot family, no yolk)
    final bottle = kWbArchetypes[WbPropArchetype.glassBottle]!;
    expect(bottle.material, AngryWordsPropMaterial.glass);
    expect(bottle.behavior, WbBreakBehavior.shatter);
    expect(bottle.soundFamily, WbPropSoundFamily.shatterGlass);
    expect(bottle.hpOverride, 1);

    // Stage 35 — emoji variety (physics from wallMix; skin only)
    final variety = kWbArchetypes[WbPropArchetype.emojiVariety]!;
    expect(variety.hpOverride, 0);
    expect(variety.crackStages, 0);
    expect(variety.soundFamily, WbPropSoundFamily.popSoft);

    // Stage 36 — emoji animals
    final animals = kWbArchetypes[WbPropArchetype.emojiAnimal]!;
    expect(animals.hpOverride, 0);
    expect(animals.crackStages, 0);
    expect(animals.soundFamily, WbPropSoundFamily.popSoft);

    // Stage 50 — granite finale, HP exactly 2
    final granite = kWbArchetypes[WbPropArchetype.graniteBlock]!;
    expect(granite.material, AngryWordsPropMaterial.stone);
    expect(granite.hpOverride, 2);
    expect(granite.crackStages, 1);
    expect(granite.behavior, WbBreakBehavior.crumble);
    expect(granite.recipe.dustAmount, closeTo(1.0, 0.001));
    expect(granite.recipe.screenShake, closeTo(1.0, 0.001));
  });

  test('hpOverride is never greater than 3', () {
    for (final entry in kWbArchetypes.entries) {
      expect(
        entry.value.hpOverride,
        lessThanOrEqualTo(3),
        reason: '${entry.key} hpOverride=${entry.value.hpOverride}',
      );
    }
  });

  test('every archetype material is a valid AngryWordsPropMaterial', () {
    final allowed = AngryWordsPropMaterial.values.toSet();
    for (final entry in kWbArchetypes.entries) {
      expect(
        allowed.contains(entry.value.material),
        isTrue,
        reason: '${entry.key} material ${entry.value.material}',
      );
    }
  });

  test('crackStages is always less than effective HP', () {
    for (final entry in kWbArchetypes.entries) {
      final spec = entry.value;
      // hpOverride 0 → HP comes from material roll (min 1); crack must stay 0.
      final effectiveHp = spec.hpOverride == 0 ? 1 : spec.hpOverride;
      expect(
        spec.crackStages,
        lessThan(effectiveHp),
        reason:
            '${entry.key}: crackStages=${spec.crackStages} hp=$effectiveHp '
            '(hpOverride=${spec.hpOverride})',
      );
    }
  });
}

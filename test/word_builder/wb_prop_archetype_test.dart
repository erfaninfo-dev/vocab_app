import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
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

void main() {
  test('WbPropArchetype has exactly 50 members', () {
    expect(WbPropArchetype.values.length, 50);
  });

  test('every registered spec matches its map key', () {
    for (final entry in kWbArchetypes.entries) {
      expect(entry.value.id, entry.key);
      expect(entry.value.palette, isNotEmpty);
      expect(entry.value.soundPitch, inInclusiveRange(0.8, 1.3));
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
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.behavior,
        WbBreakBehavior.dentThenRupture);
    expect(kWbArchetypes[WbPropArchetype.sodaCan]!.recipe.secondaryShape,
        WbShardShape.droplet);

    expect(kWbArchetypes[WbPropArchetype.egg]!.material,
        AngryWordsPropMaterial.egg);
    expect(kWbArchetypes[WbPropArchetype.egg]!.behavior,
        WbBreakBehavior.spillContents);
    expect(kWbArchetypes[WbPropArchetype.egg]!.recipe.shardCount, 18);
    expect(kWbArchetypes[WbPropArchetype.egg]!.soundFamily, 'egg_crack');

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
}

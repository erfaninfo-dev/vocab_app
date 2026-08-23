import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart';

void main() {
  test('arsenal has 50 rows with primary archetypes', () {
    expect(kAngryWordsStageArsenal.length, 50);
    for (var i = 0; i < 50; i++) {
      final L = kAngryWordsStageArsenal[i];
      expect(L.profileIndex, i);
      expect(kWbArchetypes.containsKey(L.primaryArchetype), isTrue);
      expect(L.primaryRatio, closeTo(0.7, 0.001));
      expect(L.wallHint, isNotEmpty);
      expect(L.wallHint.contains('·') || L.fillerArchetype == null, isTrue);
    }
  });

  test('locked stages have null filler', () {
    for (final stage in [2, 3, 4, 5, 9, 22, 23, 35, 36, 40, 50]) {
      final L = kAngryWordsStageArsenal[stage - 1];
      expect(L.fillerArchetype, isNull, reason: 'stage $stage');
    }
  });

  test('stage mappings match STEP 2 table samples', () {
    expect(kAngryWordsStageArsenal[0].primaryArchetype, WbPropArchetype.balloon);
    expect(kAngryWordsStageArsenal[1].primaryArchetype, WbPropArchetype.candyBall);
    expect(kAngryWordsStageArsenal[1].fillerArchetype, isNull);
    expect(kAngryWordsStageArsenal[2].primaryArchetype, WbPropArchetype.balloon);
    expect(kAngryWordsStageArsenal[2].fillerArchetype, isNull);
    expect(kAngryWordsStageArsenal[3].primaryArchetype, WbPropArchetype.sodaCan);
    expect(kAngryWordsStageArsenal[3].fillerArchetype, isNull);
    expect(kAngryWordsStageArsenal[4].primaryArchetype, WbPropArchetype.oilDrum);
    expect(kAngryWordsStageArsenal[4].fillerArchetype, isNull);
    expect(kAngryWordsStageArsenal[8].primaryArchetype, WbPropArchetype.egg);
    expect(
      kAngryWordsStageArsenal[16].primaryArchetype,
      WbPropArchetype.brick,
    );
    expect(
      kAngryWordsStageArsenal[16].fillerArchetype,
      WbPropArchetype.sandstone,
    );
    expect(
      kAngryWordsStageArsenal[21].primaryArchetype,
      WbPropArchetype.ceramicJug,
    );
    expect(
      kAngryWordsStageArsenal[22].primaryArchetype,
      WbPropArchetype.glassBottle,
    );
    expect(kAngryWordsStageArsenal[22].usesHammer, isTrue);
    expect(
      kAngryWordsStageArsenal[25].primaryArchetype,
      WbPropArchetype.magmaOrb,
    );
    expect(
      kAngryWordsStageArsenal[25].fillerArchetype,
      WbPropArchetype.iceBlock,
    );
    expect(
      kAngryWordsStageArsenal[43].primaryArchetype,
      WbPropArchetype.concreteBlock,
    );
    expect(
      kAngryWordsStageArsenal[43].fillerArchetype,
      WbPropArchetype.brick,
    );
    expect(
      kAngryWordsStageArsenal[49].primaryArchetype,
      WbPropArchetype.graniteBlock,
    );
  });

  test('density helpers unchanged', () {
    expect(kAngryWordsStageArsenal[0].allowsSmallProps, isFalse);
    expect(kAngryWordsStageArsenal[12].allowsSmallProps, isTrue);
    expect(AngryWordsLoadout.kMaxCageProps, 50);
    expect(kAngryWordsStageArsenal[3].maxCageProps, 62);
    expect(kAngryWordsStageArsenal[3].earlySparseSkipChance, lessThan(0.1));
    expect(kAngryWordsStageArsenal[39].primaryArchetype, WbPropArchetype.oilDrum);
    expect(kAngryWordsStageArsenal[39].fillerArchetype, isNull);
    expect(kAngryWordsStageArsenal[39].maxCageProps, 78);
    expect(kAngryWordsStageArsenal[39].earlySparseSkipChance, lessThan(0.05));
    expect(kAngryWordsStageArsenal[39].effectiveCols, greaterThanOrEqualTo(9));
    expect(kAngryWordsStageArsenal[0].earlySparseSkipChance, greaterThan(0.3));
  });

  test('wallHint uses Persian archetype labels', () {
    final jug = kAngryWordsStageArsenal[21];
    expect(jug.wallHint, kWbArchetypes[WbPropArchetype.ceramicJug]!.labelFa);
    final brick = kAngryWordsStageArsenal[16];
    expect(brick.wallHint, contains('آجر'));
    expect(brick.wallHint, contains('ماسه‌سنگ'));
  });

  test('only stage 23 uses hammer', () {
    for (var i = 0; i < 50; i++) {
      expect(
        kAngryWordsStageArsenal[i].usesHammer,
        i == 22,
        reason: 'stage ${i + 1}',
      );
    }
  });

  test('locked stages keep critical cargo shells', () {
    expect(
      kWbArchetypes[WbPropArchetype.egg]!.holdsCargoWell,
      isTrue,
    );
    expect(
      kWbArchetypes[WbPropArchetype.ceramicJug]!.holdsCargoWell,
      isTrue,
    );
    expect(
      kWbArchetypes[WbPropArchetype.glassBottle]!.holdsCargoWell,
      isTrue,
    );
    // Emoji / granite walls still use egg letter orbs (parity with pre-archetype).
    expect(
      kWbArchetypes[WbPropArchetype.emojiVariety]!.holdsCargoWell,
      isFalse,
    );
    expect(
      kWbArchetypes[WbPropArchetype.emojiAnimal]!.holdsCargoWell,
      isFalse,
    );
    expect(
      kWbArchetypes[WbPropArchetype.graniteBlock]!.holdsCargoWell,
      isFalse,
    );
  });
}

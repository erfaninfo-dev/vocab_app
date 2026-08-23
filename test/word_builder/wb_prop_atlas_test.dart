import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/atlas/wb_letter_atlas.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/atlas/wb_prop_atlas.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/atlas/wb_prop_atlas_batch.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/atlas/wb_stage_atlas_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WbPropAtlas builds 2×3×3 slots plus LOD in 512 image', () async {
    final atlas = await WbPropAtlas.build(
      archetypes: [
        WbPropArchetype.fireworkShell,
        WbPropArchetype.graniteBlock,
      ],
    );
    addTearDown(atlas.dispose);

    expect(atlas.image.width, 512);
    expect(atlas.image.height, 512);
    // 2 archetypes × 3 stages × 3 variants
    expect(atlas.slotCount, 18);
    expect(atlas.lodRect.width, greaterThan(0));
    expect(
      atlas.rectFor(
        const WbAtlasSlotKey(
          archetypeIndex: 1,
          damageStage: 2,
          variant: 2,
        ),
      ),
      isNotNull,
    );
  });

  test('WbPropAtlasBatch reuses buffers across frames', () async {
    final atlas = await WbPropAtlas.build(
      archetypes: [WbPropArchetype.balloon, WbPropArchetype.candyBall],
    );
    addTearDown(atlas.dispose);

    final batch = WbPropAtlasBatch(initialCapacity: 8);
    batch.beginFrame();
    for (var i = 0; i < 150; i++) {
      batch.addLod(
        atlas: atlas,
        cx: i * 2.0,
        cy: 10,
        diameter: 20,
      );
    }
    expect(batch.count, 150);

    batch.beginFrame();
    expect(batch.count, 0);
    batch.addLod(atlas: atlas, cx: 0, cy: 0, diameter: 16);
    expect(batch.count, 1);
  });

  test('wbPropUseLod is false near hit and true far away', () {
    expect(
      wbPropUseLod(
        propPos: const Offset(10, 10),
        lastHit: const Offset(12, 12),
        lodRadius: 220,
      ),
      isFalse,
    );
    expect(
      wbPropUseLod(
        propPos: const Offset(0, 0),
        lastHit: const Offset(500, 0),
        lodRadius: 220,
      ),
      isTrue,
    );
  });

  test('WbLetterAtlas has A–Z', () async {
    final letters = await WbLetterAtlas.build();
    addTearDown(letters.dispose);
    expect(letters.rectFor('a'), isNotNull);
    expect(letters.rectFor('Z'), isNotNull);
    expect(letters.rects.length, 26);
  });

  test('WbStageAtlasPack.create wires primary/filler indices', () async {
    final pack = await WbStageAtlasPack.create(
      primary: WbPropArchetype.oldTv,
      filler: WbPropArchetype.crystal,
    );
    addTearDown(pack.dispose);
    expect(pack.archetypeIndexOf(WbPropArchetype.oldTv), 0);
    expect(pack.archetypeIndexOf(WbPropArchetype.crystal), 1);
  });
}

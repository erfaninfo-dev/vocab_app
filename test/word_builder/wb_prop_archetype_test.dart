import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';

void main() {
  test('WbPropArchetype has exactly 50 members', () {
    expect(WbPropArchetype.values.length, 50);
  });

  test('kWbArchetypes is empty until STEP 2 fills specs', () {
    expect(kWbArchetypes, isEmpty);
  });

  test('kWbArchetypes covers every archetype when populated', () {
    if (kWbArchetypes.isEmpty) {
      // STEP 1 scaffold — STEP 2 must remove this early-return by filling the map.
      return;
    }
    expect(kWbArchetypes.length, WbPropArchetype.values.length);
    for (final id in WbPropArchetype.values) {
      expect(
        kWbArchetypes.containsKey(id),
        isTrue,
        reason: 'missing spec for $id',
      );
      expect(kWbArchetypes[id]!.id, id);
    }
  });
}

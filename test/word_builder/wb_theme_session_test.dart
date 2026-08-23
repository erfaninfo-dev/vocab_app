import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/data/models/vocab_entry.dart';
import 'package:ielts_vocab_app/features/word_builder/data/word_builder_theme_categories.dart';
import 'package:ielts_vocab_app/features/word_builder/data/word_builder_vocab.dart';
import 'package:ielts_vocab_app/features/word_builder/word_builder_campaign_constants.dart';
import 'package:ielts_vocab_app/features/word_builder/word_builder_theme_session_key.dart';

List<VocabEntry> _fakeThemeEntries(int count, int categoryIndex) {
  final base = -(2000000 + categoryIndex * 1000);
  return [
    for (var i = 0; i < count; i++)
      VocabEntry(
        rowId: base - i,
        bookId: 'theme_test',
        word: String.fromCharCode(97 + (i ~/ 26)) +
            String.fromCharCode(97 + (i % 26)),
        type: '',
        meaningEn: '',
        meaningFa: 'fa$i',
        meaningKur: 'ku$i',
        exampleEn: '',
        exampleFa: '',
        exampleKur: '',
        unit: 0,
        section: null,
      ),
  ];
}

void main() {
  test('theme session key builds stage levels from bundled animals', () {
    final index = decodeWordBuilderThemeSessionKey(
      encodeWordBuilderThemeSessionKey(0),
    );
    expect(index, 0);

    final category = kWordBuilderThemeCategories[index!];
    final entries = wordBuilderThemeCategoryEntries(category, index);
    expect(entries, isNotEmpty);

    final levels = buildThemeCategoryStageLevels(
      entries: entries,
      categoryIndex: index,
      categoryLabel: 'theme_${category.id}',
      random: Random(1),
    );
    expect(levels, isNotEmpty);
    expect(levels.first.targetWords.length, 3);

    final wordCount = entries
        .map(wordBuilderGameLemma)
        .where((w) => w != null && w.isNotEmpty)
        .length;
    final expectedStages =
        (wordCount + kWordBuilderCampaignWordsPerStage - 1) ~/
        kWordBuilderCampaignWordsPerStage;
    expect(levels.length, expectedStages);
  });

  test('121 theme words produce 41 stages with three then one on last', () {
    const categoryIndex = 2;
    final entries = _fakeThemeEntries(121, categoryIndex);
    final levels = buildThemeCategoryStageLevels(
      entries: entries,
      categoryIndex: categoryIndex,
      categoryLabel: 'theme_animals',
      random: Random(3),
    );

    expect(levels.length, 41);
    expect(levels.first.targetWords.length, 3);
    expect(levels.last.targetWords.length, 1);

    var totalTargets = 0;
    for (final level in levels) {
      expect(level.targetWords.length, lessThanOrEqualTo(3));
      totalTargets += level.targetWords.length;
    }
    expect(totalTargets, 121);
  });
}

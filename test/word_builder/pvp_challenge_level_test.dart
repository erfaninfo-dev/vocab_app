import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/data/models/game_word_category.dart';
import 'package:ielts_vocab_app/data/models/pvp_challenge.dart';
import 'package:ielts_vocab_app/features/word_builder/data/pvp_challenge_level.dart';
import 'package:ielts_vocab_app/features/word_builder/domain/word_builder_game_logic.dart';

void main() {
  test('buildPvpChallengeLevel uses anchor words and shared letters', () {
    const match = PvpMatch(
      id: 42,
      status: PvpMatchStatus.accepted,
      durationSec: 3600,
      category: PvpCategorySummary(
        id: 1,
        slug: 'animals',
        nameEn: 'Animals',
        nameFa: 'حیوانات',
        nameCkb: '',
        icon: 'pets_rounded',
      ),
      letters: ['c', 'a', 't', 'd', 'o', 'g'],
      anchorWords: ['cat', 'dog'],
      expiresAt: '',
      createdAt: '',
      isDraw: false,
      players: [],
      viewer: PvpViewerState(
        userId: 1,
        canAccept: false,
        canDecline: false,
        canPlay: true,
        hideLetters: false,
        isChallenger: true,
        isOpponent: false,
      ),
    );
    const categories = [
      GameWordCategory(
        id: 1,
        slug: 'animals',
        nameEn: 'Animals',
        nameFa: 'حیوانات',
        nameCkb: '',
        icon: 'pets_rounded',
        sortOrder: 0,
        words: [
          GameCategoryWord(
            word: 'cat',
            meaningFa: 'گربه',
            meaningKur: '',
          ),
          GameCategoryWord(
            word: 'dog',
            meaningFa: 'سگ',
            meaningKur: '',
          ),
        ],
      ),
    ];

    final level = buildPvpChallengeLevel(match: match, categories: categories);
    expect(level.targetWords.map((t) => t.word), ['cat', 'dog']);
    expect(level.letters, ['c', 'a', 't', 'd', 'o', 'g']);
    expect(level.targetWords.first.translationFa, 'گربه');
    expect(canSpellFromPool('cat', letterCounts(level.letters)), isTrue);
  });
}

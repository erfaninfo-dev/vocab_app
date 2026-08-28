import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/domain/pvp_scoring.dart';
import 'package:ielts_vocab_app/features/word_builder/domain/word_builder_game_logic.dart';

void main() {
  test('pvpScoreForWord counts letters', () {
    expect(pvpScoreForWord('cat'), 3);
    expect(pvpScoreForWord('travel'), 6);
  });

  test('pvpIsValidLocalWord respects pool and dictionary', () {
    final pool = pvpLetterPoolFromLetters(['c', 'a', 't', 'r', 'e']);
    final dict = {'cat', 'rate', 'care'};
  expect(
      pvpIsValidLocalWord(
        word: 'cat',
        dictionaryLower: dict,
        letterPool: pool,
        alreadyFound: {},
      ),
      isTrue,
    );
    expect(
      pvpIsValidLocalWord(
        word: 'cat',
        dictionaryLower: dict,
        letterPool: pool,
        alreadyFound: {'cat'},
      ),
      isFalse,
    );
    expect(
      pvpIsValidLocalWord(
        word: 'zzz',
        dictionaryLower: dict,
        letterPool: pool,
        alreadyFound: {},
      ),
      isFalse,
    );
  });

  test('canSpellFromPool matches PHP multiset rules', () {
    final pool = poolMaxPerLetterAcrossWords(['cat', 'dog', 'tiger']);
    final expanded = expandPoolLetters(pool);
    expect(expanded, contains('c'));
    expect(canSpellFromPool('cat', pool), isTrue);
    expect(canSpellFromPool('zzz', pool), isFalse);
  });
}

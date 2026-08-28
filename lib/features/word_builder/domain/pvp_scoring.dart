import '../../../data/models/game_word_category.dart';
import '../domain/word_builder_game_logic.dart';

const int kPvpMinWordLength = 3;

int pvpScoreForWord(String word) => normalizeWord(word).length;

int pvpTotalScore(Iterable<String> words) {
  var total = 0;
  for (final w in words) {
    total += pvpScoreForWord(w);
  }
  return total;
}

bool pvpIsValidLocalWord({
  required String word,
  required Set<String> dictionaryLower,
  required Map<String, int> letterPool,
  required Set<String> alreadyFound,
}) {
  final w = normalizeWord(word);
  if (w.length < kPvpMinWordLength) return false;
  if (!RegExp(r'^[a-z]+$').hasMatch(w)) return false;
  if (alreadyFound.contains(w)) return false;
  if (!dictionaryLower.contains(w)) return false;
  return canSpellFromPool(w, letterPool);
}

Map<String, int> pvpLetterPoolFromLetters(List<String> letters) {
  return letterCounts(letters.map((e) => e.toLowerCase()));
}

Set<String> pvpDictionaryForCategoryId(
  int categoryId,
  List<GameWordCategory> categories,
) {
  for (final c in categories) {
    if (c.id == categoryId) {
      return {
        for (final w in c.words) normalizeWord(w.word),
      };
    }
  }
  return {};
}

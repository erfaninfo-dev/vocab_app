import '../../../data/models/game_word_category.dart';
import '../../../data/models/pvp_challenge.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../pvp_challenge_session_key.dart';

WordBuilderTargetWord pvpTargetFromCategoryWord(GameCategoryWord word) {
  final normalized = normalizeWord(word.word);
  return WordBuilderTargetWord(
    word: normalized,
    translationFa: word.meaningFa,
    translationKur: word.meaningKur,
    pronunciation: '',
    exampleEn: word.exampleEn ?? '',
    meaningEn: word.meaningEn,
    exampleFa: word.exampleFa ?? '',
    exampleKur: word.exampleKur ?? '',
  );
}

WordBuilderLevel buildPvpChallengeLevel({
  required PvpMatch match,
  required List<GameWordCategory> categories,
}) {
  GameWordCategory? category;
  for (final c in categories) {
    if (c.id == match.category.id) {
      category = c;
      break;
    }
  }

  final byLemma = <String, GameCategoryWord>{};
  if (category != null) {
    for (final w in category.words) {
      final lemma = normalizeWord(w.word);
      if (lemma.isEmpty) continue;
      byLemma.putIfAbsent(lemma, () => w);
    }
  }

  final targets = <WordBuilderTargetWord>[];
  for (final anchor in match.anchorWords) {
    final lemma = normalizeWord(anchor);
    if (lemma.isEmpty) continue;
    final source = byLemma[lemma];
    if (source != null) {
      targets.add(pvpTargetFromCategoryWord(source));
    } else {
      targets.add(
        WordBuilderTargetWord(
          word: lemma,
          translationFa: '',
          translationKur: '',
          pronunciation: '',
          exampleEn: '',
        ),
      );
    }
  }

  targets.sort((a, b) => a.word.length.compareTo(b.word.length));

  final letters = match.letters.isNotEmpty
      ? List<String>.from(match.letters)
      : expandPoolLetters(
          poolMaxPerLetterAcrossWords(targets.map((t) => t.word)),
        );

  return WordBuilderLevel(
    levelId: pvpChallengeLevelId(match.id),
    difficulty: WordBuilderDifficulty.intermediate,
    category: match.category.slug.isNotEmpty
        ? match.category.slug
        : 'pvp_${match.id}',
    letters: letters,
    targetWords: targets,
  );
}

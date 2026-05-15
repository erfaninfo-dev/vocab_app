import 'dart:math';

import '../../../data/models/vocab_entry.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_constants.dart';

/// English lemma for Word Builder: only when [VocabEntry.word] is **entirely**
/// letters `a`–`z` / `A`–`Z` (length 2…7). Rejects `"21st"`, `"pre-order"`, etc.
String? wordBuilderGameLemma(VocabEntry e) {
  final t = e.word.trim();
  if (t.length < 2 || t.length > 7) return null;
  for (final r in t.runes) {
    final u = String.fromCharCode(r).codeUnitAt(0);
    final isLetter =
        (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
    if (!isLetter) return null;
  }
  return normalizeWord(t);
}

WordBuilderTargetWord targetFromVocab(VocabEntry e, String displayWord) {
  return WordBuilderTargetWord(
    word: displayWord,
    translationFa: e.meaningFa.trim(),
    translationKur: e.meaningKur.trim(),
    pronunciation: '',
    exampleEn: e.exampleEn.trim(),
    meaningEn: e.meaningEn.trim(),
    type: e.type.trim(),
    exampleFa: e.exampleFa.trim(),
    exampleKur: e.exampleKur.trim(),
    rowId: e.rowId,
    bookId: e.bookId,
    unit: e.unit,
    section: e.section,
  );
}

List<int> _wordLengthsForDifficulty(WordBuilderDifficulty d) {
  switch (d) {
    case WordBuilderDifficulty.beginner:
      return const [2, 3, 3];
    case WordBuilderDifficulty.intermediate:
      return const [3, 4, 4];
    case WordBuilderDifficulty.advanced:
      return const [4, 5, 5];
  }
}

int? _maxTileCap(WordBuilderDifficulty d) {
  switch (d) {
    case WordBuilderDifficulty.beginner:
      return 6;
    case WordBuilderDifficulty.intermediate:
      return 10;
    case WordBuilderDifficulty.advanced:
      return 12;
  }
}

int _minTileCount(WordBuilderDifficulty d) {
  switch (d) {
    case WordBuilderDifficulty.beginner:
      return 3;
    case WordBuilderDifficulty.intermediate:
    case WordBuilderDifficulty.advanced:
      return 4;
  }
}

int? _maxTileCapFor(WordBuilderDifficulty d, List<int> lens) {
  if (d == WordBuilderDifficulty.beginner &&
      lens.length == 3 &&
      lens[0] == 3 &&
      lens[1] == 3 &&
      lens[2] == 3) {
    return 9;
  }
  return _maxTileCap(d);
}

List<int> _beginnerLens(Map<int, List<VocabEntry>> byLen) {
  if ((byLen[2] ?? []).isNotEmpty) return const [2, 3, 3];
  return const [3, 3, 3];
}

String _lemmaKey(VocabEntry e) => wordBuilderGameLemma(e) ?? '';

(VocabEntry, VocabEntry, VocabEntry)? _tryPickTriple({
  required Map<int, List<VocabEntry>> byLen,
  required List<int> lens,
  required WordBuilderDifficulty difficulty,
  required Random random,
  required Set<String> usedHeads,
  int attempts = 600,
  bool ignoreTileCap = false,
}) {
  final la = lens[0];
  final lb = lens[1];
  final lc = lens[2];
  final laList = byLen[la];
  final lbList = byLen[lb];
  final lcList = byLen[lc];
  if (laList == null || lbList == null || lcList == null) return null;
  if (laList.isEmpty || lbList.isEmpty || lcList.isEmpty) return null;

  final cap = ignoreTileCap ? null : _maxTileCapFor(difficulty, lens);
  final minTiles = _minTileCount(difficulty);

  for (var attempt = 0; attempt < attempts; attempt++) {
    final ea = laList[random.nextInt(laList.length)];
    final eb = lbList[random.nextInt(lbList.length)];
    final ec = lcList[random.nextInt(lcList.length)];
    final ha = _lemmaKey(ea);
    final hb = _lemmaKey(eb);
    final hc = _lemmaKey(ec);
    if (ha.isEmpty || hb.isEmpty || hc.isEmpty) continue;
    if (ha == hb || ha == hc || hb == hc) continue;
    if (usedHeads.contains(ha) ||
        usedHeads.contains(hb) ||
        usedHeads.contains(hc)) {
      continue;
    }
    final pool = poolMaxPerLetterAcrossWords([ha, hb, hc]);
    final n = pool.values.fold<int>(0, (a, b) => a + b);
    if (n < minTiles) continue;
    if (!ignoreTileCap && cap != null && n > cap) continue;
    return (ea, eb, ec);
  }
  return null;
}

List<WordBuilderLevel> buildWordBuilderLevelsFromEntries(
  List<VocabEntry> raw,
  Random random, {
  required String categoryLabel,
  int maxLevelsPerWordLength = kWordBuilderLevelsPerLengthBand,
}) {
  final byHead = <String, List<VocabEntry>>{};
  for (final e in raw) {
    final w = wordBuilderGameLemma(e);
    if (w == null) continue;
    byHead.putIfAbsent(w, () => []).add(e);
  }
  final byKey = <String, VocabEntry>{};
  for (final e in byHead.entries) {
    final k = e.key;
    final list = e.value;
    VocabEntry? pick;
    for (final x in list) {
      if (wordBuilderGameLemma(x) == k) {
        pick = x;
        break;
      }
    }
    if (pick == null) {
      list.sort(
        (a, b) => a.word.trim().length.compareTo(b.word.trim().length),
      );
      pick = list.first;
    }
    byKey[k] = pick;
  }
  if (byKey.isEmpty) return const [];

  final byLen = <int, List<VocabEntry>>{};
  for (final e in byKey.values) {
    final h = wordBuilderGameLemma(e);
    if (h == null) continue;
    byLen.putIfAbsent(h.length, () => []).add(e);
  }
  for (final list in byLen.values) {
    list.shuffle(random);
  }

  final levels = <WordBuilderLevel>[];
  var levelId = 1;
  final usedHeads = <String>{};

  const tierOrder = <WordBuilderDifficulty>[
    WordBuilderDifficulty.beginner,
    WordBuilderDifficulty.intermediate,
    WordBuilderDifficulty.advanced,
  ];

  for (final difficulty in tierOrder) {
    final lens = difficulty == WordBuilderDifficulty.beginner
        ? _beginnerLens(byLen)
        : _wordLengthsForDifficulty(difficulty);
    for (var round = 0; round < maxLevelsPerWordLength; round++) {
      final triple = _tryPickTriple(
        byLen: byLen,
        lens: lens,
        difficulty: difficulty,
        random: random,
        usedHeads: usedHeads,
      );
      if (triple == null) break;
      final (ea, eb, ec) = triple;
      final ordered = [ea, eb, ec]..sort((a, b) {
        final la = wordBuilderGameLemma(a)!.length;
        final lb = wordBuilderGameLemma(b)!.length;
        return la.compareTo(lb);
      });

      final targets = <WordBuilderTargetWord>[];
      for (final e in ordered) {
        final w = wordBuilderGameLemma(e)!;
        final display = normalizeWord(e.word.trim());
        targets.add(targetFromVocab(e, display));
        usedHeads.add(w);
      }

      final wordsLower =
          targets.map((t) => normalizeWord(t.word)).toList(growable: false);
      final letters =
          expandPoolLetters(poolMaxPerLetterAcrossWords(wordsLower));

      levels.add(
        WordBuilderLevel(
          levelId: levelId++,
          difficulty: difficulty,
          category: categoryLabel,
          letters: letters,
          targetWords: targets,
        ),
      );
    }
  }

  return levels;
}

bool _campaignSortedLemmaLengthsValid(
  WordBuilderDifficulty d,
  int la,
  int lb,
  int lc,
) {
  if (la > lb || lb > lc) return false;
  switch (d) {
    case WordBuilderDifficulty.beginner:
      return (la == 2 && lb == 3 && lc == 3) || (la == 3 && lb == 3 && lc == 3);
    case WordBuilderDifficulty.intermediate:
      return la == 3 && lb == 4 && lc == 4;
    case WordBuilderDifficulty.advanced:
      return la == 4 && lb == 5 && lc == 5;
  }
}

WordBuilderLevel buildCampaignStageLevel({
  required List<VocabEntry> entries,
  required WordBuilderDifficulty difficulty,
  required String categoryLabel,
  required int stage1Based,
  Random? random,
}) {
  final rnd = random ?? Random();
  final usable = <VocabEntry>[];
  final seenLemma = <String>{};
  for (final e in entries) {
    final h = wordBuilderGameLemma(e);
    if (h == null || h.isEmpty) continue;
    if (seenLemma.contains(h)) continue;
    seenLemma.add(h);
    usable.add(e);
  }

  if (usable.length == 3) {
    usable.sort((a, b) => wordBuilderGameLemma(a)!.length
        .compareTo(wordBuilderGameLemma(b)!.length));
    final la = wordBuilderGameLemma(usable[0])!.length;
    final lb = wordBuilderGameLemma(usable[1])!.length;
    final lc = wordBuilderGameLemma(usable[2])!.length;
    if (_campaignSortedLemmaLengthsValid(difficulty, la, lb, lc)) {
      final ha = wordBuilderGameLemma(usable[0])!;
      final hb = wordBuilderGameLemma(usable[1])!;
      final hc = wordBuilderGameLemma(usable[2])!;
      if (ha != hb && ha != hc && hb != hc) {
        final pool = poolMaxPerLetterAcrossWords([ha, hb, hc]);
        final n = pool.values.fold<int>(0, (a, b) => a + b);
        final minTiles = _minTileCount(difficulty);
        if (n >= minTiles) {
          final targets = <WordBuilderTargetWord>[];
          for (final e in usable) {
            final display = normalizeWord(e.word.trim());
            targets.add(targetFromVocab(e, display));
          }
          final wordsLower =
              targets.map((t) => normalizeWord(t.word)).toList(growable: false);
          final letters =
              expandPoolLetters(poolMaxPerLetterAcrossWords(wordsLower));
          return WordBuilderLevel(
            levelId: 900000000 + difficulty.index * 20 + stage1Based,
            difficulty: difficulty,
            category: categoryLabel,
            letters: letters,
            targetWords: targets,
          );
        }
      }
    }
  }

  final byLen = <int, List<VocabEntry>>{};
  final seen = <String>{};
  for (final e in entries) {
    final h = wordBuilderGameLemma(e);
    if (h == null) continue;
    final k = h;
    if (seen.contains(k)) continue;
    seen.add(k);
    byLen.putIfAbsent(h.length, () => []).add(e);
  }
  for (final list in byLen.values) {
    list.shuffle(rnd);
  }

  final lens = difficulty == WordBuilderDifficulty.beginner
      ? _beginnerLens(byLen)
      : _wordLengthsForDifficulty(difficulty);
  final triple = _tryPickTriple(
    byLen: byLen,
    lens: lens,
    difficulty: difficulty,
    random: rnd,
    usedHeads: {},
    attempts: 900,
    ignoreTileCap: entries.length == 3,
  );

  if (triple == null) {
    return WordBuilderLevel(
      levelId: 900000000 + difficulty.index * 20 + stage1Based,
      difficulty: difficulty,
      category: categoryLabel,
      letters: const [],
      targetWords: const [],
    );
  }

  final (ea, eb, ec) = triple;
  final ordered = [ea, eb, ec]..sort((a, b) {
    final la = wordBuilderGameLemma(a)!.length;
    final lb = wordBuilderGameLemma(b)!.length;
    return la.compareTo(lb);
  });

  final targets = <WordBuilderTargetWord>[];
  for (final e in ordered) {
    final display = normalizeWord(e.word.trim());
    targets.add(targetFromVocab(e, display));
  }
  final wordsLower =
      targets.map((t) => normalizeWord(t.word)).toList(growable: false);
  final letters = expandPoolLetters(poolMaxPerLetterAcrossWords(wordsLower));

  return WordBuilderLevel(
    levelId: 900000000 + difficulty.index * 20 + stage1Based,
    difficulty: difficulty,
    category: categoryLabel,
    letters: letters,
    targetWords: targets,
  );
}

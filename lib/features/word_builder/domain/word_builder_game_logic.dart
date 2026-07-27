import 'dart:math';

import 'word_builder_models.dart';

String normalizeWord(String w) => w.trim().toLowerCase();

Map<String, int> letterCounts(Iterable<String> chars) {
  final m = <String, int>{};
  for (final c in chars) {
    if (c.isEmpty) continue;
    final k = c.toLowerCase();
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

Map<String, int> multisetForWords(Iterable<String> wordsLower) {
  final m = <String, int>{};
  for (final w in wordsLower) {
    for (final r in w.runes) {
      final ch = String.fromCharCode(r).toLowerCase();
      if (ch.isEmpty) continue;
      m[ch] = (m[ch] ?? 0) + 1;
    }
  }
  return m;
}

Map<String, int> poolMaxPerLetterAcrossWords(Iterable<String> wordsLower) {
  final maps = <Map<String, int>>[
    for (final w in wordsLower) multisetForWords({w}),
  ];
  if (maps.isEmpty) return {};
  final keys = maps.expand((m) => m.keys).toSet();
  final out = <String, int>{};
  for (final k in keys) {
    var mx = 0;
    for (final m in maps) {
      final v = m[k] ?? 0;
      if (v > mx) mx = v;
    }
    out[k] = mx;
  }
  return out;
}

List<String> expandPoolLetters(Map<String, int> pool) {
  final keys = pool.keys.toList()..sort();
  final out = <String>[];
  for (final k in keys) {
    for (var i = 0; i < (pool[k] ?? 0); i++) {
      out.add(k);
    }
  }
  return out;
}

Map<String, int> multisetUnsolvedTargets(
  WordBuilderLevel level,
  Set<String> solvedLower,
) {
  final remaining = <String>[];
  for (final t in level.targetWords) {
    final lw = normalizeWord(t.word);
    if (!solvedLower.contains(lw)) {
      remaining.add(lw);
    }
  }
  return multisetForWords(remaining);
}

bool canSpellFromPool(String wordLower, Map<String, int> poolCounts) {
  final need = <String, int>{};
  for (final r in wordLower.runes) {
    final ch = String.fromCharCode(r).toLowerCase();
    need[ch] = (need[ch] ?? 0) + 1;
  }
  for (final e in need.entries) {
    if ((poolCounts[e.key] ?? 0) < e.value) return false;
  }
  return true;
}

bool isTargetWord(String wordLower, WordBuilderLevel level) {
  for (final t in level.targetWords) {
    if (normalizeWord(t.word) == wordLower) return true;
  }
  return false;
}

List<LetterInstance> buildLetterInstances(List<String> letters) {
  final out = <LetterInstance>[];
  var id = 0;
  for (final raw in letters) {
    for (final r in raw.runes) {
      final ch = String.fromCharCode(r);
      if (ch.trim().isEmpty) continue;
      out.add(LetterInstance(id: id++, char: ch.toLowerCase()));
    }
  }
  return out;
}

List<LetterInstance> shuffleInstances(
  List<LetterInstance> items,
  Random random,
) {
  final copy = List<LetterInstance>.of(items);
  copy.shuffle(random);
  return copy;
}

Map<String, int> rackMultiset(Iterable<LetterInstance> rack) =>
    letterCounts(rack.map((e) => e.char));

bool validateSubmit({
  required String built,
  required List<LetterInstance> rack,
  required WordBuilderLevel level,
  required Set<String> solvedLower,
}) {
  final fromRack = normalizeWord(rack.map((e) => e.char).join());
  final w = normalizeWord(built);
  if (fromRack != w) return false;
  if (w.length < 2) return false;
  if (solvedLower.contains(w)) return false;
  if (!isTargetWord(w, level)) return false;
  final pool = letterCounts(level.letters);
  return canSpellFromPool(w, pool);
}

bool removeOneExcessLetterFromRack(
  List<LetterInstance> rack,
  Map<String, int> allowedMultiset,
) {
  if (rack.isEmpty) return false;
  final rackCounts = rackMultiset(rack);
  for (var i = rack.length - 1; i >= 0; i--) {
    final ch = rack[i].char;
    final allowed = allowedMultiset[ch] ?? 0;
    final used = rackCounts[ch] ?? 0;
    if (used > allowed) {
      rack.removeAt(i);
      rackCounts[ch] = (rackCounts[ch] ?? 1) - 1;
      return true;
    }
  }
  return false;
}

Set<String> sanitizeSolvedForLevel(
  WordBuilderLevel level,
  Set<String> solvedLower,
) {
  final allowed = level.targetWords.map((t) => normalizeWord(t.word)).toSet();
  return {
    for (final s in solvedLower)
      if (allowed.contains(s)) s,
  };
}

bool isLevelComplete(WordBuilderLevel level, Set<String> solvedLower) {
  for (final t in level.targetWords) {
    if (!solvedLower.contains(normalizeWord(t.word))) return false;
  }
  return true;
}

int solvedTargetCount(WordBuilderLevel level, Set<String> solvedLower) {
  var n = 0;
  for (final t in level.targetWords) {
    if (solvedLower.contains(normalizeWord(t.word))) n++;
  }
  return n;
}

WordBuilderTargetWord? firstUnsolvedTarget(
  WordBuilderLevel level,
  Set<String> solvedLower,
) {
  for (final t in level.targetWords) {
    if (!solvedLower.contains(normalizeWord(t.word))) return t;
  }
  return null;
}

List<WordBuilderTargetWord> unsolvedTargets(
  WordBuilderLevel level,
  Set<String> solvedLower,
) {
  return [
    for (final t in level.targetWords)
      if (!solvedLower.contains(normalizeWord(t.word))) t,
  ];
}

int maxUnsolvedTargetLength(WordBuilderLevel level, Set<String> solvedLower) {
  var max = 0;
  for (final t in unsolvedTargets(level, solvedLower)) {
    final len = normalizeWord(t.word).length;
    if (len > max) max = len;
  }
  return max;
}

bool anyUnsolvedTargetHasLength(
  WordBuilderLevel level,
  Set<String> solvedLower,
  int length,
) {
  for (final t in unsolvedTargets(level, solvedLower)) {
    if (normalizeWord(t.word).length == length) return true;
  }
  return false;
}

bool pathCanExtendToLongerUnsolvedTarget(
  WordBuilderLevel level,
  Set<String> solvedLower,
  String builtLower,
) {
  final prefix = normalizeWord(builtLower);
  if (prefix.isEmpty) return false;
  for (final t in unsolvedTargets(level, solvedLower)) {
    final w = normalizeWord(t.word);
    if (w.length > prefix.length && w.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

/// True when [builtLower] is a prefix of at least one unsolved target word.
bool isValidUnsolvedTargetPrefix(
  WordBuilderLevel level,
  Set<String> solvedLower,
  String builtLower,
) {
  final prefix = normalizeWord(builtLower);
  if (prefix.isEmpty) return false;
  for (final t in unsolvedTargets(level, solvedLower)) {
    if (normalizeWord(t.word).startsWith(prefix)) return true;
  }
  return false;
}

/// Next letter hint for Ghost letter UI (shortest matching unsolved target).
String? ghostNextLetterForUnsolvedPrefix(
  WordBuilderLevel level,
  Set<String> solvedLower,
  String built,
) {
  final prefix = normalizeWord(built);
  String? bestWord;
  for (final t in unsolvedTargets(level, solvedLower)) {
    final w = normalizeWord(t.word);
    if (!w.startsWith(prefix) || w.length <= prefix.length) continue;
    if (bestWord == null || w.length < bestWord.length) {
      bestWord = w;
    }
  }
  if (bestWord == null) return null;
  return bestWord[prefix.length].toUpperCase();
}

/// True when appending [nextChar] keeps a valid prefix / completes a target
/// for the active unsolved word order (خانه فعال).
bool isValidNextLetterForActiveSlots(
  WordBuilderLevel level,
  Set<String> solvedLower,
  String currentBuilt,
  String nextChar,
) {
  if (nextChar.trim().isEmpty) return false;
  final built = normalizeWord('$currentBuilt$nextChar');
  if (findUnsolvedTargetMatchingBuilt(level, solvedLower, built) != null) {
    return true;
  }
  return isValidUnsolvedTargetPrefix(level, solvedLower, built);
}

WordBuilderTargetWord? findUnsolvedTargetMatchingBuilt(
  WordBuilderLevel level,
  Set<String> solvedLower,
  String builtLower,
) {
  final built = normalizeWord(builtLower);
  if (built.isEmpty) return null;
  for (final t in level.targetWords) {
    final w = normalizeWord(t.word);
    if (solvedLower.contains(w)) continue;
    if (w == built) return t;
  }
  return null;
}

List<String> activeTargetLetterChars(WordBuilderLevel level) {
  return List<String>.of(level.letters);
}

int? pickHiddenIndexForReveal(
  String wordLower,
  Set<int> alreadyRevealed,
  Random random,
) {
  if (wordLower.isEmpty) return null;
  final hidden = <int>[];
  for (var i = 0; i < wordLower.length; i++) {
    if (!alreadyRevealed.contains(i)) hidden.add(i);
  }
  if (hidden.isEmpty) return null;
  return hidden[random.nextInt(hidden.length)];
}

import 'dart:math' as math;

import '../../data/models/vocab_entry.dart';
import 'sample_text_highlight_rendering.dart';

List<EnWordToken> tokenizeEnglishWords(String s) {
  final out = <EnWordToken>[];
  final re = RegExp(r"[A-Za-z]+(?:['\u2019\u2018\u02BC][A-Za-z]+)?");
  for (final m in re.allMatches(s)) {
    out.add(EnWordToken(start: m.start, end: m.end, text: m.group(0)!));
  }
  return out;
}

/// Normalize an English token/phrase for matching.
///
/// - Lower-cases the input.
/// - Treats anything that is not a letter or apostrophe (e.g. hyphens, slashes,
///   punctuation) as a word boundary, so "part-time" and "part time" match.
/// - Collapses runs of whitespace into single spaces.
String normalizeForLookup(String s) {
  final unified = s
      .replaceAll('\u2019', "'")
      .replaceAll('\u2018', "'")
      .replaceAll('\u02BC', "'");
  return unified
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z']+"), ' ')
      .trim()
      .replaceAll(RegExp(r"\s+"), ' ');
}

bool isCommonCollocationTail(String word) {
  switch (word) {
    case 'in':
    case 'on':
    case 'at':
    case 'to':
    case 'for':
    case 'of':
    case 'with':
    case 'about':
    case 'from':
    case 'into':
    case 'over':
    case 'under':
    case 'after':
    case 'before':
    case 'between':
    case 'through':
      return true;
    default:
      return false;
  }
}

String? bestTappedPhrase({
  required List<EnWordToken> tokens,
  required int startTokenIndex,
}) {
  if (startTokenIndex < 0 || startTokenIndex >= tokens.length) return null;
  final head = normalizeForLookup(tokens[startTokenIndex].text);
  if (head.isEmpty) return null;

  if (startTokenIndex + 1 < tokens.length) {
    final next = normalizeForLookup(tokens[startTokenIndex + 1].text);
    if (isCommonCollocationTail(next)) {
      return '$head $next';
    }
  }
  return head;
}

Set<String> englishLemmaCandidates(
  String word, {
  required Set<String> catalogTokens,
  required bool allowDerivations,
}) {
  final w = normalizeForLookup(word);
  if (w.isEmpty) return const {};

  final out = <String>{w};
  void add(String s) {
    final t = normalizeForLookup(s);
    if (t.isNotEmpty) out.add(t);
  }

  if (w.endsWith("'s") && w.length > 2) add(w.substring(0, w.length - 2));

  // Plurals.
  if (w.endsWith('ies') && w.length > 3) {
    add('${w.substring(0, w.length - 3)}y');
  }
  if (w.endsWith('es') && w.length > 2) add(w.substring(0, w.length - 2));
  if (w.endsWith('s') && w.length > 1) add(w.substring(0, w.length - 1));

  // -ing.
  if (w.endsWith('ing') && w.length > 4) {
    final base = w.substring(0, w.length - 3);
    add(base);
    if (!base.endsWith('e')) add('${base}e');
    if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
      add(base.substring(0, base.length - 1));
    }
  }

  // -ed.
  if (w.endsWith('ed') && w.length > 3) {
    final base = w.substring(0, w.length - 2);
    add(base);
    if (w.endsWith('ied') && w.length > 3) {
      add('${w.substring(0, w.length - 3)}y');
    }
    if (!base.endsWith('e')) add('${base}e');
    if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
      add(base.substring(0, base.length - 1));
    }
  }

  // Helpful "other form" candidates (for related suggestions).
  if (!w.endsWith('ing')) add('${w}ing');
  if (!w.endsWith('ed')) add('${w}ed');
  if (!w.endsWith('s')) add('${w}s');

  // Conservative derivations (only if present in catalog).
  if (allowDerivations) {
    for (final suf in const ['ly', 'ful', 'fully', 'ingly']) {
      final d = normalizeForLookup('$w$suf');
      if (d.isNotEmpty && catalogTokens.contains(d)) out.add(d);
    }
  }

  return out;
}

List<VocabEntry> lookupCatalogMatches({
  required List<EnWordToken> tokens,
  required int startTokenIndex,
  required List<VocabEntry> catalog,
  required int preferredBookId,
  required int preferredUnit,
}) {
  if (startTokenIndex < 0 || startTokenIndex >= tokens.length) {
    return const [];
  }

  final tappedWord = normalizeForLookup(tokens[startTokenIndex].text);
  if (tappedWord.isEmpty) return const [];
  final tappedPhrase = bestTappedPhrase(
    tokens: tokens,
    startTokenIndex: startTokenIndex,
  );
  final catalogTokens = <String>{};
  for (final e in catalog) {
    final t = normalizeForLookup(e.word);
    if (t.isEmpty) continue;
    catalogTokens.addAll(t.split(' '));
  }
  final allowDerivations = tappedWord.length >= 5;
  final tappedWordCandidates = englishLemmaCandidates(
    tappedWord,
    catalogTokens: catalogTokens,
    allowDerivations: allowDerivations,
  );
  final tappedPhraseHeadCandidates = tappedPhrase == null
      ? const <String>{}
      : englishLemmaCandidates(
          tappedPhrase.split(' ').first,
          catalogTokens: catalogTokens,
          allowDerivations: allowDerivations,
        );

  int rank(VocabEntry e) {
    final bid = int.tryParse(e.bookId) ?? -1;
    if (bid != preferredBookId) return 2;
    if (e.unit == preferredUnit) return 0;
    return 1;
  }

  int compareEntries(VocabEntry a, VocabEntry b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    final ab = int.tryParse(a.bookId) ?? -1;
    final bb = int.tryParse(b.bookId) ?? -1;
    if (ab != bb) return ab.compareTo(bb);
    if (a.unit != b.unit) return a.unit.compareTo(b.unit);
    return a.rowId.compareTo(b.rowId);
  }

  final tierCollocationSameUnit = <VocabEntry>[];
  final tierPhrase = <VocabEntry>[];
  final tierExactWord = <VocabEntry>[];
  final tierRelated = <VocabEntry>[];
  final seen = <String>{};

  void addTo(List<VocabEntry> bucket, VocabEntry e) {
    if (seen.add(e.id)) bucket.add(e);
  }

  // Tier 0 â€” exact collocation (word + preposition) in the same unit, if present.
  if (tappedPhrase != null && tappedPhrase.contains(' ')) {
    for (final e in catalog) {
      final bid = int.tryParse(e.bookId) ?? -1;
      if (bid != preferredBookId) continue;
      if (e.unit != preferredUnit) continue;
      if (normalizeForLookup(e.word) == tappedPhrase) {
        addTo(tierCollocationSameUnit, e);
      }
    }
  }

  // Tier 1 â€” exact phrase match (prefer longest) starting at the tapped token.
  // Keeps multi-word entries (e.g. "look forward to") prominent when the user
  // taps the entry's first word.
  final maxLen = math.min(6, tokens.length - startTokenIndex);
  for (var len = maxLen; len >= 1; len--) {
    final phraseKey = normalizeForLookup(
      tokens
          .sublist(startTokenIndex, startTokenIndex + len)
          .map((t) => t.text)
          .join(' '),
    );
    if (phraseKey.isEmpty) continue;
    final exact = catalog
        .where((e) => normalizeForLookup(e.word) == phraseKey)
        .toList();
    if (exact.isEmpty) continue;
    for (final e in exact) {
      // Keep single-word exact match in its own tier.
      if (len == 1) {
        addTo(tierExactWord, e);
      } else {
        addTo(tierPhrase, e);
      }
    }
    break;
  }

  // Tier 2 â€” related matches by explicit morphology/derivation candidates.
  // This is what surfaces "part-time", "time zone", "free time", â€¦ when the
  // user taps "time", regardless of where the tapped word sits in the entry.
  for (final e in catalog) {
    if (seen.contains(e.id)) continue;
    final entryTokens = normalizeForLookup(e.word).split(' ');
    final hit =
        entryTokens.any(tappedWordCandidates.contains) ||
        entryTokens.any(tappedPhraseHeadCandidates.contains);
    if (hit) {
      addTo(tierRelated, e);
    }
  }

  if (tierCollocationSameUnit.isEmpty &&
      tierPhrase.isEmpty &&
      tierExactWord.isEmpty &&
      tierRelated.isEmpty) {
    return const [];
  }
  tierCollocationSameUnit.sort(compareEntries);
  tierPhrase.sort(compareEntries);
  tierExactWord.sort(compareEntries);
  tierRelated.sort(compareEntries);
  return [
    ...tierCollocationSameUnit,
    ...tierPhrase,
    ...tierExactWord,
    ...tierRelated,
  ];
}

import 'dart:math';

import '../../../data/models/book_model.dart';
import '../../../data/models/vocab_entry.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import 'word_builder_vocab.dart';

/// `ielts` | `general` per public catalog book id.
Map<int, String> _bookTrackById(List<Book> books) {
  final out = <int, String>{};
  for (final b in books) {
    if (!b.isPublic || b.isStudent) continue;
    out[b.id] = b.isGeneralTrack ? 'general' : 'ielts';
  }
  return out;
}

void _splitCatalog(
  List<VocabEntry> catalog,
  Map<int, String> trackByBookId,
  List<VocabEntry> outGeneral,
  List<VocabEntry> outIelts,
) {
  for (final e in catalog) {
    final id = int.tryParse(e.bookId.trim());
    if (id == null) continue;
    switch (trackByBookId[id]) {
      case 'general':
        outGeneral.add(e);
      case 'ielts':
        outIelts.add(e);
      default:
        // Unknown / legacy book id — treat as IELTS tab (same default as [Book.track]).
        outIelts.add(e);
    }
  }
}

String? _normalizedHead(VocabEntry e) => wordBuilderGameLemma(e);

List<VocabEntry> _dedupePool(Iterable<VocabEntry> raw) {
  final seen = <String>{};
  final sorted = List<VocabEntry>.of(raw)
    ..sort((a, b) => a.rowId.compareTo(b.rowId));
  final out = <VocabEntry>[];
  for (final e in sorted) {
    final k = _normalizedHead(e);
    if (k == null || k.isEmpty) continue;
    if (seen.contains(k)) continue;
    seen.add(k);
    out.add(e);
  }
  return out;
}

List<VocabEntry> _unusedLemmaPool(
  Iterable<VocabEntry> raw,
  Set<String> usedHeads, {
  int minLen = 2,
  int maxLen = 7,
}) {
  return _dedupePool(raw.where((e) {
    final h = wordBuilderGameLemma(e);
    if (h == null || h.length < minLen || h.length > maxLen) return false;
    final k = _normalizedHead(e);
    return k != null && !usedHeads.contains(k);
  }));
}

List<List<VocabEntry>> _buildTierStages({
  required int stageCount,
  required WordBuilderDifficulty difficulty,
  required List<VocabEntry> primaryCandidates,
  required List<VocabEntry> fallbackCandidates,
  required Set<String> usedHeads,
  required Random random,
  /// When true (Advanced), never mix primary + fallback in one stage — General only
  /// if the IELTS pool cannot supply that stage.
  bool strictTrackFallback = false,
}) {
  final stages = <List<VocabEntry>>[];
  var primary = List<VocabEntry>.of(primaryCandidates);
  var fallback = List<VocabEntry>.of(fallbackCandidates);

  for (var s = 0; s < stageCount; s++) {
    List<VocabEntry>? take = pickCampaignStageEntries(
      candidates: primary,
      difficulty: difficulty,
      usedHeads: usedHeads,
      random: random,
    );
    if (take == null && fallback.isNotEmpty) {
      take = pickCampaignStageEntries(
        candidates: fallback,
        difficulty: difficulty,
        usedHeads: usedHeads,
        random: random,
      );
    }
    if (!strictTrackFallback) {
      take ??= pickCampaignStageEntries(
        candidates: [...primary, ...fallback],
        difficulty: difficulty,
        usedHeads: usedHeads,
        random: random,
      );
    }
    if (take == null) {
      take = pickCampaignStageEntries(
        candidates: primary,
        difficulty: difficulty,
        usedHeads: const {},
        random: random,
      );
    }
    if (take == null && fallback.isNotEmpty) {
      take = pickCampaignStageEntries(
        candidates: fallback,
        difficulty: difficulty,
        usedHeads: const {},
        random: random,
      );
    }
    if (!strictTrackFallback) {
      take ??= pickCampaignStageEntries(
        candidates: [...primary, ...fallback],
        difficulty: difficulty,
        usedHeads: const {},
        random: random,
      );
    }

    if (take == null || take.length < kWordBuilderCampaignWordsPerStage) {
      stages.add(const []);
      continue;
    }

    final heads = take.map((e) => _normalizedHead(e)!).toSet();
    usedHeads.addAll(heads);
    primary = primary
        .where((e) => !heads.contains(_normalizedHead(e)))
        .toList(growable: false);
    fallback = fallback
        .where((e) => !heads.contains(_normalizedHead(e)))
        .toList(growable: false);
    stages.add(take);
  }

  return stages;
}

class WordBuilderCampaignPlan {
  const WordBuilderCampaignPlan({
    required this.beginnerStages,
    required this.intermediateStages,
    required this.advancedStages,
  });

  final List<List<VocabEntry>> beginnerStages;
  final List<List<VocabEntry>> intermediateStages;
  final List<List<VocabEntry>> advancedStages;

  List<List<VocabEntry>> stagesFor(WordBuilderDifficulty d) {
    switch (d) {
      case WordBuilderDifficulty.beginner:
        return beginnerStages;
      case WordBuilderDifficulty.intermediate:
        return intermediateStages;
      case WordBuilderDifficulty.advanced:
        return advancedStages;
    }
  }

  static int stableRandomSeed(List<VocabEntry> catalog) {
    var h = 2166136261;
    for (final e in catalog) {
      h = 0x7fffffff & (h ^ (e.rowId * 1000003));
      h = 0x7fffffff & (h ^ e.bookId.hashCode);
    }
    return h == 0 ? 1 : h;
  }

  static WordBuilderCampaignPlan build(
    List<VocabEntry> catalog,
    List<Book> books,
    Random random,
  ) {
    final trackByBookId = _bookTrackById(books);
    final general = <VocabEntry>[];
    final ielts = <VocabEntry>[];
    _splitCatalog(catalog, trackByBookId, general, ielts);

    final usedHeads = <String>{};

    final beginnerPrimary = _unusedLemmaPool(general, usedHeads, maxLen: 3);
    final beginnerFallback = _unusedLemmaPool(general, usedHeads, maxLen: 4);
    final beginnerStages = _buildTierStages(
      stageCount: kWordBuilderStagesPerTier,
      difficulty: WordBuilderDifficulty.beginner,
      primaryCandidates: beginnerPrimary,
      fallbackCandidates: beginnerFallback,
      usedHeads: usedHeads,
      random: random,
    );

    final interPrimary = _unusedLemmaPool(general, usedHeads, minLen: 3, maxLen: 4);
    final interFallback = [
      ..._unusedLemmaPool(general, usedHeads),
      ..._unusedLemmaPool(ielts, usedHeads),
    ];
    final intermediateStages = _buildTierStages(
      stageCount: kWordBuilderStagesPerTier,
      difficulty: WordBuilderDifficulty.intermediate,
      primaryCandidates: interPrimary,
      fallbackCandidates: _dedupePool(interFallback),
      usedHeads: usedHeads,
      random: random,
    );

    // Advanced: IELTS-tab books first; General-tab only when IELTS cannot fill a stage.
    final advPrimary = _unusedLemmaPool(ielts, usedHeads, minLen: 4);
    final advFallback = _unusedLemmaPool(general, usedHeads, minLen: 4);
    final advancedStages = _buildTierStages(
      stageCount: kWordBuilderStagesPerTier,
      difficulty: WordBuilderDifficulty.advanced,
      primaryCandidates: advPrimary,
      fallbackCandidates: advFallback,
      usedHeads: usedHeads,
      random: random,
      strictTrackFallback: true,
    );

    return WordBuilderCampaignPlan(
      beginnerStages: beginnerStages,
      intermediateStages: intermediateStages,
      advancedStages: advancedStages,
    );
  }
}

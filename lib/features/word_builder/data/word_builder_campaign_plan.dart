import 'dart:math';

import '../../../data/models/book_model.dart';
import '../../../data/models/vocab_entry.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import 'word_builder_vocab.dart';

typedef _WbTrackIds = ({Set<int> generalIds, Set<int> ieltsIds});

_WbTrackIds _collectTrackIds(List<Book> books) {
  final generalIds = <int>{};
  final ieltsIds = <int>{};
  for (final b in books) {
    if (!b.isPublic || b.isStudent) continue;
    if (b.isGeneralTrack) {
      generalIds.add(b.id);
    } else if (b.isIeltsTrack) {
      ieltsIds.add(b.id);
    }
  }
  return (generalIds: generalIds, ieltsIds: ieltsIds);
}

void _splitCatalog(
  List<VocabEntry> catalog,
  _WbTrackIds tracks,
  List<VocabEntry> outGeneral,
  List<VocabEntry> outIelts,
) {
  bool inSet(VocabEntry e, Set<int> ids) {
    final id = int.tryParse(e.bookId.trim());
    return id != null && ids.contains(id);
  }

  for (final e in catalog) {
    if (inSet(e, tracks.generalIds)) outGeneral.add(e);
    if (inSet(e, tracks.ieltsIds)) outIelts.add(e);
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
    final tracks = _collectTrackIds(books);
    final general = <VocabEntry>[];
    final ielts = <VocabEntry>[];
    _splitCatalog(catalog, tracks, general, ielts);

    final usedHeads = <String>{};

    final pool3Candidates = _dedupePool(general.where((e) {
      final h = wordBuilderGameLemma(e);
      return h != null && h.length >= 2 && h.length <= 3;
    }))..shuffle(random);

    final len2 = <VocabEntry>[];
    final len3b = <VocabEntry>[];
    for (final e in pool3Candidates) {
      final h = wordBuilderGameLemma(e)!;
      if (h.length == 2) {
        len2.add(e);
      } else if (h.length == 3) {
        len3b.add(e);
      }
    }

    final beginnerStages = <List<VocabEntry>>[];
    for (var s = 0; s < kWordBuilderStagesPerTier; s++) {
      final take = <VocabEntry>[];
      if (len2.isNotEmpty && len3b.length >= 2) {
        take.add(len2.removeAt(0));
        take.add(len3b.removeAt(0));
        take.add(len3b.removeAt(0));
      } else if (len3b.length >= 3) {
        take.add(len3b.removeAt(0));
        take.add(len3b.removeAt(0));
        take.add(len3b.removeAt(0));
      }
      for (final e in take) {
        final k = _normalizedHead(e);
        if (k != null) usedHeads.add(k);
      }
      beginnerStages.add(take);
    }

    final poolInter = _dedupePool(general.where((e) {
      final h = wordBuilderGameLemma(e);
      if (h == null || h.length < 3 || h.length > 4) return false;
      final k = _normalizedHead(e);
      return k != null && !usedHeads.contains(k);
    }))..shuffle(random);

    final i3 = <VocabEntry>[];
    final i4 = <VocabEntry>[];
    for (final e in poolInter) {
      final h = wordBuilderGameLemma(e)!;
      if (h.length == 3) {
        i3.add(e);
      } else if (h.length == 4) {
        i4.add(e);
      }
    }

    final intermediateStages = <List<VocabEntry>>[];
    for (var s = 0; s < kWordBuilderStagesPerTier; s++) {
      final take = <VocabEntry>[];
      if (i3.isNotEmpty && i4.length >= 2) {
        take.add(i3.removeAt(0));
        take.add(i4.removeAt(0));
        take.add(i4.removeAt(0));
      }
      for (final e in take) {
        final k = _normalizedHead(e);
        if (k != null) usedHeads.add(k);
      }
      intermediateStages.add(take);
    }

    final poolAdv = _dedupePool(ielts.where((e) {
      final h = wordBuilderGameLemma(e);
      if (h == null || h.length < 4 || h.length > 5) return false;
      final k = _normalizedHead(e);
      return k != null && !usedHeads.contains(k);
    }))..shuffle(random);

    final a4 = <VocabEntry>[];
    final a5 = <VocabEntry>[];
    for (final e in poolAdv) {
      final h = wordBuilderGameLemma(e)!;
      if (h.length == 4) {
        a4.add(e);
      } else if (h.length == 5) {
        a5.add(e);
      }
    }

    final advancedStages = <List<VocabEntry>>[];
    for (var s = 0; s < kWordBuilderStagesPerTier; s++) {
      final take = <VocabEntry>[];
      if (a4.isNotEmpty && a5.length >= 2) {
        take.add(a4.removeAt(0));
        take.add(a5.removeAt(0));
        take.add(a5.removeAt(0));
      }
      for (final e in take) {
        final k = _normalizedHead(e);
        if (k != null) usedHeads.add(k);
      }
      advancedStages.add(take);
    }

    return WordBuilderCampaignPlan(
      beginnerStages: beginnerStages,
      intermediateStages: intermediateStages,
      advancedStages: advancedStages,
    );
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';

const String kWordBuilderProgressPrefsKey = 'word_builder_progress_v1';

class WordBuilderProgressRepository {
  Future<WordBuilderPersistedProgress> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kWordBuilderProgressPrefsKey);
    if (raw == null || raw.isEmpty) {
      return WordBuilderPersistedProgress.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return WordBuilderPersistedProgress.empty();
      }
      return WordBuilderPersistedProgress.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (_) {
      return WordBuilderPersistedProgress.empty();
    }
  }

  Future<void> save(WordBuilderPersistedProgress progress) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      kWordBuilderProgressPrefsKey,
      jsonEncode(progress.toJson()),
    );
  }

  Future<void> stripCampaignLevelEntries() async {
    final p = await load();
    final kept = <int, WordBuilderLevelProgress>{};
    for (final e in p.perLevel.entries) {
      if (!isWordBuilderCampaignPersistedLevelId(e.key)) {
        kept[e.key] = e.value;
      }
    }
    if (kept.length == p.perLevel.length) return;
    await save(
      p.copyWith(perLevel: kept),
    );
  }
}

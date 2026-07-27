import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';

const String kWordBuilderCampaignProgressPrefsKey =
    'word_builder_campaign_progress_v1';

@immutable
class WordBuilderCampaignProgressSnapshot {
  const WordBuilderCampaignProgressSnapshot({
    required this.beginnerStagesCleared,
    required this.intermediateStagesCleared,
    required this.advancedStagesCleared,
  });

  final int beginnerStagesCleared;
  final int intermediateStagesCleared;
  final int advancedStagesCleared;

  static const empty = WordBuilderCampaignProgressSnapshot(
    beginnerStagesCleared: 0,
    intermediateStagesCleared: 0,
    advancedStagesCleared: 0,
  );

  int clearedFor(WordBuilderDifficulty d) {
    switch (d) {
      case WordBuilderDifficulty.beginner:
        return beginnerStagesCleared;
      case WordBuilderDifficulty.intermediate:
        return intermediateStagesCleared;
      case WordBuilderDifficulty.advanced:
        return advancedStagesCleared;
    }
  }

  bool isDifficultyUnlocked(
    WordBuilderDifficulty d, {
    bool unlockAll = false,
  }) {
    if (unlockAll) return true;
    switch (d) {
      case WordBuilderDifficulty.beginner:
        return true;
      case WordBuilderDifficulty.intermediate:
        return beginnerStagesCleared >= kWordBuilderStagesPerTier;
      case WordBuilderDifficulty.advanced:
        return intermediateStagesCleared >= kWordBuilderStagesPerTier;
    }
  }

  bool isStageUnlocked(
    WordBuilderDifficulty d,
    int stage1Based, {
    bool unlockAll = false,
  }) {
    if (stage1Based < 1 || stage1Based > kWordBuilderStagesPerTier) {
      return false;
    }
    if (unlockAll) return true;
    if (!isDifficultyUnlocked(d)) return false;
    final c = clearedFor(d);
    return stage1Based <= c + 1;
  }

  bool isStageCompleted(WordBuilderDifficulty d, int stage1Based) {
    return stage1Based >= 1 &&
        stage1Based <= kWordBuilderStagesPerTier &&
        stage1Based <= clearedFor(d);
  }

  WordBuilderCampaignProgressSnapshot afterClearingStage(
    WordBuilderDifficulty d,
    int stage1Based,
  ) {
    if (stage1Based < 1 || stage1Based > kWordBuilderStagesPerTier) {
      return this;
    }
    final c = clearedFor(d);
    if (stage1Based != c + 1) return this;
    switch (d) {
      case WordBuilderDifficulty.beginner:
        return WordBuilderCampaignProgressSnapshot(
          beginnerStagesCleared: c + 1,
          intermediateStagesCleared: intermediateStagesCleared,
          advancedStagesCleared: advancedStagesCleared,
        );
      case WordBuilderDifficulty.intermediate:
        return WordBuilderCampaignProgressSnapshot(
          beginnerStagesCleared: beginnerStagesCleared,
          intermediateStagesCleared: c + 1,
          advancedStagesCleared: advancedStagesCleared,
        );
      case WordBuilderDifficulty.advanced:
        return WordBuilderCampaignProgressSnapshot(
          beginnerStagesCleared: beginnerStagesCleared,
          intermediateStagesCleared: intermediateStagesCleared,
          advancedStagesCleared: c + 1,
        );
    }
  }

  Map<String, Object?> toJson() => {
    'v': 1,
    'bc': beginnerStagesCleared,
    'ic': intermediateStagesCleared,
    'ac': advancedStagesCleared,
  };

  static WordBuilderCampaignProgressSnapshot fromJson(
    Map<String, Object?> map,
  ) {
    return WordBuilderCampaignProgressSnapshot(
      beginnerStagesCleared:
          (map['bc'] as num?)?.toInt().clamp(0, kWordBuilderStagesPerTier) ?? 0,
      intermediateStagesCleared:
          (map['ic'] as num?)?.toInt().clamp(0, kWordBuilderStagesPerTier) ?? 0,
      advancedStagesCleared:
          (map['ac'] as num?)?.toInt().clamp(0, kWordBuilderStagesPerTier) ?? 0,
    );
  }
}

class WordBuilderCampaignProgressRepository {
  Future<WordBuilderCampaignProgressSnapshot> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kWordBuilderCampaignProgressPrefsKey);
    if (raw == null || raw.isEmpty) {
      return WordBuilderCampaignProgressSnapshot.empty;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return WordBuilderCampaignProgressSnapshot.empty;
      return WordBuilderCampaignProgressSnapshot.fromJson(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    } catch (_) {
      return WordBuilderCampaignProgressSnapshot.empty;
    }
  }

  Future<void> save(WordBuilderCampaignProgressSnapshot progress) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      kWordBuilderCampaignProgressPrefsKey,
      jsonEncode(progress.toJson()),
    );
  }

  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(kWordBuilderCampaignProgressPrefsKey);
  }
}

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/api_providers.dart';
import '../data/word_builder_campaign_plan.dart';
import '../data/word_builder_campaign_progress_repository.dart';
import '../word_builder_campaign_constants.dart';

final wordBuilderCampaignPlanProvider =
    FutureProvider<WordBuilderCampaignPlan>((ref) async {
  final catalog = await ref.watch(apiAllWordsCatalogProvider.future);
  final books = await ref.watch(apiBooksProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final reshuffle = prefs.getInt(kWordBuilderCampaignPlanSeedPrefsKey) ?? 0;
  final base = WordBuilderCampaignPlan.stableRandomSeed(catalog);
  final mixed = reshuffle == 0 ? base : (base ^ reshuffle);
  final seed = mixed == 0 ? 1 : mixed;
  return WordBuilderCampaignPlan.build(catalog, books, Random(seed));
});

/// Writes a new plan seed so the next [wordBuilderCampaignPlanProvider] read
/// builds different stage triples (used by Lobby campaign Reset).
Future<void> reshuffleWordBuilderCampaignPlanSeed() async {
  final prefs = await SharedPreferences.getInstance();
  var next = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  if (next == 0) next = 1;
  final prev = prefs.getInt(kWordBuilderCampaignPlanSeedPrefsKey) ?? 0;
  if (next == prev) next = (next + 1) & 0x7fffffff;
  if (next == 0) next = 1;
  await prefs.setInt(kWordBuilderCampaignPlanSeedPrefsKey, next);
}

final wordBuilderCampaignProgressRepositoryProvider =
    Provider<WordBuilderCampaignProgressRepository>(
  (ref) => WordBuilderCampaignProgressRepository(),
);

final wordBuilderCampaignProgressProvider =
    FutureProvider<WordBuilderCampaignProgressSnapshot>((ref) async {
  final repo = ref.watch(wordBuilderCampaignProgressRepositoryProvider);
  return repo.load();
});

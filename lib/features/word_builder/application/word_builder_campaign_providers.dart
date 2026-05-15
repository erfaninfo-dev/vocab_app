import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/api_providers.dart';
import '../data/word_builder_campaign_plan.dart';
import '../data/word_builder_campaign_progress_repository.dart';

final wordBuilderCampaignPlanProvider =
    FutureProvider<WordBuilderCampaignPlan>((ref) async {
  final catalog = await ref.watch(apiAllWordsCatalogProvider.future);
  final books = await ref.watch(apiBooksProvider.future);
  return WordBuilderCampaignPlan.build(
    catalog,
    books,
    Random(WordBuilderCampaignPlan.stableRandomSeed(catalog)),
  );
});

final wordBuilderCampaignProgressRepositoryProvider =
    Provider<WordBuilderCampaignProgressRepository>(
  (ref) => WordBuilderCampaignProgressRepository(),
);

final wordBuilderCampaignProgressProvider =
    FutureProvider<WordBuilderCampaignProgressSnapshot>((ref) async {
  final repo = ref.watch(wordBuilderCampaignProgressRepositoryProvider);
  return repo.load();
});

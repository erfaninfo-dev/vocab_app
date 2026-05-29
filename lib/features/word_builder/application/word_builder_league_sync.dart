import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../domain/api_providers.dart';
import '../data/word_builder_campaign_progress_repository.dart';

typedef WordBuilderProviderReader =
    T Function<T>(ProviderListenable<T> provider);

Future<void> syncWordBuilderLeagueSnapshot({
  required WordBuilderProviderReader read,
  required WordBuilderCampaignProgressSnapshot progress,
  required int coins,
}) async {
  final session = read(authProvider).valueOrNull;
  if (session == null) return;

  try {
    await read(apiServiceProvider).syncWordBuilderLeagueProgress(
      beginnerStagesCleared: progress.beginnerStagesCleared,
      intermediateStagesCleared: progress.intermediateStagesCleared,
      advancedStagesCleared: progress.advancedStagesCleared,
      coins: coins,
    );
  } catch (_) {
    // League sync should never block local gameplay.
  }
}

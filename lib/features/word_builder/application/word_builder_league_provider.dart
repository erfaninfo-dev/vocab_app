import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../data/models/league.dart';
import '../../../domain/api_providers.dart';
import '../word_builder_campaign_constants.dart';
import 'word_builder_campaign_providers.dart';
import 'word_builder_coins_provider.dart';
import 'word_builder_league_sync.dart';

const int kWordBuilderLeaguePageSize = 20;

@immutable
class WordBuilderLeaguePagedState {
  const WordBuilderLeaguePagedState({
    required this.response,
    required this.entries,
    required this.hasMore,
    required this.nextOffset,
    this.isLoadingMore = false,
  });

  final LeagueResponse response;
  final List<LeagueEntry> entries;
  final bool hasMore;
  final int nextOffset;
  final bool isLoadingMore;

  WordBuilderLeaguePagedState copyWith({
    LeagueResponse? response,
    List<LeagueEntry>? entries,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
  }) {
    return WordBuilderLeaguePagedState(
      response: response ?? this.response,
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final wordBuilderLeagueProvider =
    AsyncNotifierProvider<
      WordBuilderLeagueNotifier,
      WordBuilderLeaguePagedState
    >(WordBuilderLeagueNotifier.new);

class WordBuilderLeagueNotifier
    extends AsyncNotifier<WordBuilderLeaguePagedState> {
  @override
  Future<WordBuilderLeaguePagedState> build() async {
    final session = ref.watch(authProvider).valueOrNull;
    if (session != null) {
      final progress = await ref.watch(
        wordBuilderCampaignProgressProvider.future,
      );
      final coins = await ref.watch(wordBuilderCoinsProvider.future);
      await syncWordBuilderLeagueSnapshot(
        read: ref.read,
        progress: progress,
        coins: coins,
      );
    }

    final response = await ref
        .read(apiServiceProvider)
        .fetchLeague(
          LeagueType.wordBuilder,
          period: LeaguePeriod.lifetime,
          limit: kWordBuilderLeaguePageSize,
          offset: 0,
        );
    return WordBuilderLeaguePagedState(
      response: response,
      entries: response.leaderboard,
      hasMore: response.hasMore,
      nextOffset: response.nextOffset,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await ref
          .read(apiServiceProvider)
          .fetchLeague(
            LeagueType.wordBuilder,
            period: LeaguePeriod.lifetime,
            limit: kWordBuilderLeaguePageSize,
            offset: current.nextOffset,
          );
      state = AsyncData(
        current.copyWith(
          response: response,
          entries: [...current.entries, ...response.leaderboard],
          hasMore: response.hasMore,
          nextOffset: response.nextOffset,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

int wordBuilderOverallStageFromProgress({
  required int beginnerStagesCleared,
  required int intermediateStagesCleared,
  required int advancedStagesCleared,
}) {
  final tierIndex =
      advancedStagesCleared > 0 ||
          intermediateStagesCleared >= kWordBuilderStagesPerTier
      ? 2
      : (intermediateStagesCleared > 0 ||
                beginnerStagesCleared >= kWordBuilderStagesPerTier
            ? 1
            : 0);
  final clearedInTier = switch (tierIndex) {
    2 => advancedStagesCleared,
    1 => intermediateStagesCleared,
    _ => beginnerStagesCleared,
  };
  final level = (clearedInTier + 1).clamp(1, kWordBuilderStagesPerTier);
  return tierIndex * kWordBuilderStagesPerTier + level;
}

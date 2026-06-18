import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/admin_story.dart';
import '../../domain/api_providers.dart';
import '../../domain/api_remote_data_epoch.dart';

const Duration _visibleStoriesPollInterval = Duration(seconds: 6);

final visibleStoriesProvider =
    AsyncNotifierProvider<VisibleStoriesNotifier, List<StoryItem>>(
      VisibleStoriesNotifier.new,
    );

class VisibleStoriesNotifier extends AsyncNotifier<List<StoryItem>> {
  Timer? _pollTimer;
  bool _refreshInFlight = false;
  bool _disposeRegistered = false;

  @override
  Future<List<StoryItem>> build() async {
    if (!_disposeRegistered) {
      _disposeRegistered = true;
      ref.onDispose(() => _pollTimer?.cancel());
    }
    ref.watch(apiRemoteDataEpochProvider);
    ref.watch(authProvider);
    _startPolling();
    return ref.read(apiServiceProvider).fetchVisibleStories();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_visibleStoriesPollInterval, (_) {
      unawaited(refresh(showLoading: false));
    });
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    final previous = state.valueOrNull;
    if (showLoading) state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).fetchVisibleStories(),
    );
    _refreshInFlight = false;
    if (!showLoading && next.hasError && previous != null) return;
    state = next;
  }

  Future<void> markViewed(int storyId) async {
    final current = state.valueOrNull;
    final session = ref.read(authProvider).valueOrNull;
    if (session != null) {
      await ref.read(apiServiceProvider).markStoryViewed(storyId);
    }
    if (current != null) {
      state = AsyncData([
        for (final story in current)
          story.id == storyId ? story.copyWith(seen: true) : story,
      ]);
    }
  }

  Future<void> setLiked(StoryItem story, bool liked) async {
    final current = state.valueOrNull ?? const <StoryItem>[];
    final result = await ref
        .read(apiServiceProvider)
        .toggleStoryLike(storyId: story.id, liked: liked);
    state = AsyncData([
      for (final item in current)
        item.id == story.id
            ? item.copyWith(liked: result.liked, likeCount: result.likeCount)
            : item,
    ]);
  }

  Future<StoryPoll> votePoll({
    required StoryItem story,
    required StoryPoll poll,
    required String optionId,
  }) async {
    final current = state.valueOrNull ?? const <StoryItem>[];
    final updatedPoll = await ref
        .read(apiServiceProvider)
        .voteStoryPoll(storyId: story.id, pollId: poll.id, optionId: optionId);
    state = AsyncData([
      for (final item in current)
        item.id == story.id
            ? item.copyWith(
                textStyle: item.textStyle.copyWith(poll: updatedPoll),
              )
            : item,
    ]);
    return updatedPoll;
  }

  Future<StoryGrammarGame> answerGrammarGame({
    required StoryItem story,
    required StoryGrammarGame game,
    required String optionId,
  }) async {
    final current = state.valueOrNull ?? const <StoryItem>[];
    final updatedGame = await ref
        .read(apiServiceProvider)
        .answerStoryGrammarGame(
          storyId: story.id,
          gameId: game.id,
          optionId: optionId,
        );
    state = AsyncData([
      for (final item in current)
        item.id == story.id
            ? item.copyWith(
                textStyle: item.textStyle.copyWith(grammarGame: updatedGame),
              )
            : item,
    ]);
    return updatedGame;
  }
}

final adminStoriesProvider = FutureProvider.autoDispose<List<StoryItem>>((
  ref,
) async {
  ref.watch(apiRemoteDataEpochProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null || !session.user.isAdmin) {
    return const [];
  }
  return ref.read(apiServiceProvider).fetchAdminStories();
});

final storyAudienceProvider = FutureProvider.autoDispose
    .family<StoryAudienceSummary, int>((ref, storyId) async {
      ref.watch(apiRemoteDataEpochProvider);
      final session = ref.watch(authProvider).valueOrNull;
      if (session == null || !session.user.isAdmin) {
        throw StateError('not_admin');
      }
      return ref.read(apiServiceProvider).fetchStoryAudience(storyId);
    });

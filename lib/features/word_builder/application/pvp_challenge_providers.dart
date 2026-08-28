import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../data/models/pvp_challenge.dart';
import '../../../domain/api_providers.dart';

final pvpChallengesProvider = FutureProvider<PvpMatchListBuckets>((ref) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    return const PvpMatchListBuckets(
      incomingPending: [],
      myTurn: [],
      waitingOpponent: [],
      completedRecent: [],
    );
  }
  return ref.read(apiServiceProvider).fetchPvpChallenges();
});

final pvpChallengeDetailProvider = FutureProvider.family<PvpMatch, int>((
  ref,
  matchId,
) async {
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    throw Exception('Sign in required');
  }
  return ref.read(apiServiceProvider).fetchPvpChallengeDetail(matchId);
});

class PvpChallengeActions {
  PvpChallengeActions(this._ref);

  final Ref _ref;

  Future<PvpMatch> createChallenge(int opponentId) async {
    final match = await _ref
        .read(apiServiceProvider)
        .createPvpChallenge(opponentId: opponentId);
    _invalidate();
    return match;
  }

  Future<PvpMatch> accept(int matchId) async {
    final match = await _ref.read(apiServiceProvider).acceptPvpChallenge(matchId);
    _invalidate(matchId);
    return match;
  }

  Future<PvpMatch> decline(int matchId) async {
    final match =
        await _ref.read(apiServiceProvider).declinePvpChallenge(matchId);
    _invalidate(matchId);
    return match;
  }

  Future<PvpSubmitResult> submit({
    required int matchId,
    required DateTime startedAt,
    required DateTime completedAt,
    required List<String> words,
  }) async {
    final result = await _ref.read(apiServiceProvider).submitPvpChallenge(
          matchId: matchId,
          startedAt: startedAt,
          completedAt: completedAt,
          words: words,
        );
    _invalidate(matchId);
    return result;
  }

  void _invalidate([int? matchId]) {
    _ref.invalidate(pvpChallengesProvider);
    if (matchId != null) {
      _ref.invalidate(pvpChallengeDetailProvider(matchId));
    }
  }
}

final pvpChallengeActionsProvider = Provider<PvpChallengeActions>((ref) {
  return PvpChallengeActions(ref);
});

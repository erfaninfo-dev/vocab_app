import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'word_builder_campaign_providers.dart';
import 'word_builder_league_sync.dart';
import '../word_builder_coin_constants.dart';

final wordBuilderCoinsProvider =
    AsyncNotifierProvider<WordBuilderCoinsNotifier, int>(
      WordBuilderCoinsNotifier.new,
    );

class WordBuilderCoinsNotifier extends AsyncNotifier<int> {
  static const _prefsKey = 'word_builder_coins_v1';

  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsKey)) {
      await prefs.setInt(_prefsKey, kWordBuilderCoinsInitialBalance);
      return kWordBuilderCoinsInitialBalance;
    }
    return prefs.getInt(_prefsKey) ?? kWordBuilderCoinsInitialBalance;
  }

  Future<void> _persist(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, value);
  }

  void _syncLeague(int coins) {
    unawaited(
      ref
          .read(wordBuilderCampaignProgressProvider.future)
          .then(
            (progress) => syncWordBuilderLeagueSnapshot(
              read: ref.read,
              progress: progress,
              coins: coins,
            ),
          ),
    );
  }

  Future<bool> trySpend(int amount) async {
    if (amount <= 0) return true;
    final current = await future;
    if (current < amount) return false;
    final next = current - amount;
    await _persist(next);
    state = AsyncData(next);
    _syncLeague(next);
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final current = await future;
    final next = current + amount;
    await _persist(next);
    state = AsyncData(next);
    _syncLeague(next);
  }
}

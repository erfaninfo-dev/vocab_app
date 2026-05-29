import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/api_service.dart';
import '../auth/auth_provider.dart';
import '../stats/stats_service.dart';
import 'srs_model.dart';

// ─── Keys ─────────────────────────────────────────────────────────────────────

const _kSrsCards = 'srs_cards_v1';

// ─── State ────────────────────────────────────────────────────────────────────

class SrsState {
  const SrsState({this.cards = const {}});

  /// wordId → SrsCard
  final Map<String, SrsCard> cards;

  List<SrsCard> get dueToday =>
      cards.values.where((c) => c.isDueToday).toList();

  int get dueTodayCount => dueToday.length;

  SrsCard cardFor(String wordId) => cards[wordId] ?? SrsCard(wordId: wordId);

  SrsState copyWithCard(SrsCard card) =>
      SrsState(cards: {...cards, card.wordId: card});
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SrsNotifier extends StateNotifier<SrsState> {
  SrsNotifier(this._stats, this._readAuthToken) : super(const SrsState()) {
    _load();
  }

  final StatsNotifier _stats;
  final String? Function() _readAuthToken;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSrsCards);
    if (raw == null) return;
    try {
      final cards = SrsCard.decodeList(raw);
      state = SrsState(cards: {for (final c in cards) c.wordId: c});
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSrsCards,
      SrsCard.encodeList(state.cards.values.toList()),
    );
  }

  /// Rate a word and advance its schedule.
  Future<void> rate(String wordId, SrsRating rating) async {
    final card = state.cardFor(wordId);
    final updated = Sm2.rate(card, rating);
    state = state.copyWithCard(updated);
    await _save();
    // Log to stats
    await _stats.logWordReview();
    _recordLeagueReview(wordId);
  }

  void _recordLeagueReview(String wordId) {
    final token = _readAuthToken();
    if (token == null || token.isEmpty) return;
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final encoded = base64Url.encode(utf8.encode(wordId)).replaceAll('=', '');
    final safeId = encoded.length > 54 ? encoded.substring(0, 54) : encoded;
    unawaited(
      ApiService(authToken: token)
          .recordLeagueEvent(
            eventType: 'srs_review',
            clientRequestId: 'srs-$day-$safeId',
            sourceType: 'srs_card',
            sourceId: wordId,
            answeredCount: 1,
          )
          .catchError((_) {}),
    );
  }

  /// Reset a word's SRS data (e.g., when user re-adds to study).
  Future<void> reset(String wordId) async {
    state = state.copyWithCard(SrsCard(wordId: wordId));
    await _save();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final srsProvider = StateNotifierProvider<SrsNotifier, SrsState>(
  (ref) => SrsNotifier(
    ref.read(statsProvider.notifier),
    () => ref.read(authProvider).valueOrNull?.token,
  ),
);

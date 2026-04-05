import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  SrsCard cardFor(String wordId) =>
      cards[wordId] ?? SrsCard(wordId: wordId);

  SrsState copyWithCard(SrsCard card) => SrsState(
    cards: {...cards, card.wordId: card},
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SrsNotifier extends StateNotifier<SrsState> {
  SrsNotifier(this._stats) : super(const SrsState()) {
    _load();
  }

  final StatsNotifier _stats;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSrsCards);
    if (raw == null) return;
    try {
      final cards = SrsCard.decodeList(raw);
      state = SrsState(
        cards: {for (final c in cards) c.wordId: c},
      );
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
  }

  /// Reset a word's SRS data (e.g., when user re-adds to study).
  Future<void> reset(String wordId) async {
    state = state.copyWithCard(SrsCard(wordId: wordId));
    await _save();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final srsProvider = StateNotifierProvider<SrsNotifier, SrsState>(
  (ref) => SrsNotifier(ref.read(statsProvider.notifier)),
);

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book_model.dart';
import '../data/models/grammar_question.dart';
import '../data/models/grammar_topic_summary.dart';
import '../data/models/unit_model.dart';
import '../data/models/vocab_entry.dart';
import '../core/auth/auth_provider.dart';
import '../data/services/api_service.dart';

// ─── Shared service instance (includes auth bearer when logged in) ───────────

final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authProvider);
  final token = auth.valueOrNull?.token;
  return ApiService(authToken: token);
});

// ─── Books ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /books.php

final apiBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.read(apiServiceProvider).fetchBooks();
});

// ─── Units ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /units.php?book_id={bookId}

final apiUnitsProvider = FutureProvider.family<List<UnitInfo>, int>((ref, bookId) {
  return ref.read(apiServiceProvider).fetchUnits(bookId);
});

// ─── Sections ─────────────────────────────────────────────────────────────────
// Corresponds to: GET /sections.php?book_id={bookId}&unit={unit}
// Returns [] when the unit has no sections.

typedef BookUnit = ({int bookId, int unit});

final apiSectionsProvider = FutureProvider.family<List<int>, BookUnit>((
  ref,
  arg,
) {
  return ref.read(apiServiceProvider).fetchSections(arg.bookId, arg.unit);
});

// ─── Words ────────────────────────────────────────────────────────────────────
// Corresponds to:
//   GET /words.php?book_id={bookId}&unit={unit}&section={section}  (with section)
//   GET /words.php?book_id={bookId}&unit={unit}                    (no sections)

typedef BookUnitSection = ({int bookId, int unit, int? section});

final apiWordsProvider =
    FutureProvider.family<List<VocabEntry>, BookUnitSection>((ref, arg) {
      return ref
          .read(apiServiceProvider)
          .fetchWords(arg.bookId, arg.unit, section: arg.section);
    });

// ─── All words for a book (Favorites screen) ─────────────────────────────────
// Corresponds to: GET /words.php?book_id={bookId}

final apiAllWordsForBookProvider = FutureProvider.family<List<VocabEntry>, int>(
  (ref, bookId) {
    return ref.read(apiServiceProvider).fetchAllWordsForBook(bookId);
  },
);

// ─── Grammar (DB column `content` = topic name) ─────────────────────────────

final apiGrammarTopicsProvider = FutureProvider<List<GrammarTopicSummary>>((ref) {
  return ref.read(apiServiceProvider).fetchGrammarTopics();
});

final apiGrammarQuestionsProvider =
    FutureProvider.family<List<GrammarQuestion>, String>((ref, topic) {
      return ref.read(apiServiceProvider).fetchGrammarQuestions(topic);
    });

/// Stable cache key for one or more grammar topic names (sorted, joined).
String grammarTopicsCacheKey(List<String> topics) {
  final copy = topics.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
    ..sort();
  return copy.join('\x1E');
}

/// Fetches questions for all [topics], merges, shuffles, returns up to [kGrammarQuizSessionSize].
const int kGrammarQuizSessionSize = 20;

final apiGrammarQuizSessionProvider =
    FutureProvider.family<List<GrammarQuestion>, String>((ref, topicsKey) async {
      if (topicsKey.isEmpty) return [];
      final topics = topicsKey.split('\x1E').where((s) => s.isNotEmpty).toList();
      if (topics.isEmpty) return [];
      final svc = ref.read(apiServiceProvider);
      final lists = await Future.wait(
        topics.map((t) => svc.fetchGrammarQuestions(t)),
      );
      final merged = <GrammarQuestion>[];
      for (final list in lists) {
        merged.addAll(list);
      }
      if (merged.isEmpty) return [];
      merged.shuffle(Random());
      if (merged.length <= kGrammarQuizSessionSize) return merged;
      return merged.sublist(0, kGrammarQuizSessionSize);
    });

// ─── New Providers for Search ───────────────────────────────────────────────

// Search query provider
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

// Books list with search
final apiSearchBooksProvider = FutureProvider<List<Book>>((ref) {
  final query = ref.watch(bookSearchQueryProvider); // Watch the query state

  // If the query is empty, fetch all books (like before)
  // Otherwise, search using the query
  if (query.isEmpty) {
    return ref.read(apiServiceProvider).fetchBooks();
  } else {
    return ref.read(apiServiceProvider).searchBooks(query);
  }
});

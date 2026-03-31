import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book_model.dart';
import '../data/models/vocab_entry.dart';
import '../data/services/api_service.dart';

// ─── Shared service instance ─────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => const ApiService());

// ─── Books ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /books.php

final apiBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.read(apiServiceProvider).fetchBooks();
});

// ─── Units ────────────────────────────────────────────────────────────────────
// Corresponds to: GET /units.php?book_id={bookId}

final apiUnitsProvider = FutureProvider.family<List<int>, int>((ref, bookId) {
  return ref.read(apiServiceProvider).fetchUnits(bookId);
});

// ─── Sections ─────────────────────────────────────────────────────────────────
// Corresponds to: GET /sections.php?book_id={bookId}&unit={unit}
// Returns [] when the unit has no sections.

typedef BookUnit = ({int bookId, int unit});

final apiSectionsProvider =
    FutureProvider.family<List<int>, BookUnit>((ref, arg) {
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

final apiAllWordsForBookProvider =
    FutureProvider.family<List<VocabEntry>, int>((ref, bookId) {
  return ref.read(apiServiceProvider).fetchAllWordsForBook(bookId);
});

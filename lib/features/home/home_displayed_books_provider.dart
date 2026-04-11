import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';
import 'home_book_track_provider.dart';

/// Unified fetch for the home grid: public books or student scope depending on [homeBookTrackProvider].
final apiHomeBooksProvider = FutureProvider<List<Book>>((ref) async {
  final track = ref.watch(homeBookTrackProvider);
  final query = ref.watch(bookSearchQueryProvider);
  final session = ref.watch(authProvider).valueOrNull;
  final svc = ref.read(apiServiceProvider);

  if (track.isStudentCatalog) {
    if (session == null || !session.user.studentAccess) {
      return [];
    }
    if (query.trim().isEmpty) {
      return svc.fetchBooks(scope: 'student');
    }
    return svc.searchBooks(query.trim(), scope: 'student');
  }
  if (query.trim().isEmpty) {
    return svc.fetchBooks(scope: 'public');
  }
  return svc.searchBooks(query.trim(), scope: 'public');
});

/// Books for the home grid: current segment (IELTS / General / Students) + optional title/description filter.
final homeDisplayedBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final asyncBooks = ref.watch(apiHomeBooksProvider);
  final track = ref.watch(homeBookTrackProvider);
  final q = ref.watch(bookSearchQueryProvider).trim().toLowerCase();

  return asyncBooks.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (books) {
      var list = track.isStudentCatalog
          ? List<Book>.of(books)
          : books.where((b) => b.track == track.apiValue).toList();
      if (q.isNotEmpty) {
        list = list
            .where(
              (b) =>
                  b.title.toLowerCase().contains(q) ||
                  (b.description ?? '').toLowerCase().contains(q),
            )
            .toList();
      }
      return AsyncData(list);
    },
  );
});

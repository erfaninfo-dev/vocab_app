import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';
import 'home_book_track_provider.dart';

/// Public catalog for home (IELTS + General filters); independent of selected tab.
final apiPublicBooksForHomeProvider = FutureProvider<List<Book>>((ref) async {
  final query = ref.watch(bookSearchQueryProvider);
  final svc = ref.read(apiServiceProvider);
  if (query.trim().isEmpty) {
    return svc.fetchBooks(scope: 'public');
  }
  return svc.searchBooks(query.trim(), scope: 'public');
});

/// Student catalog when logged in with access; empty otherwise.
final apiStudentBooksForHomeProvider = FutureProvider<List<Book>>((ref) async {
  final query = ref.watch(bookSearchQueryProvider);
  final session = ref.watch(authProvider).valueOrNull;
  if (session == null) {
    return <Book>[];
  }
  final u = session.user;
  if (!u.studentAccess && !u.isTeacher && !u.isAdmin) {
    return <Book>[];
  }
  final svc = ref.read(apiServiceProvider);
  if (query.trim().isEmpty) {
    return svc.fetchBooks(scope: 'student');
  }
  return svc.searchBooks(query.trim(), scope: 'student');
});

/// Books for one home tab — used by [PageView] so IELTS / General can swipe without refetching public data.
final homeDisplayedBooksForTrackProvider =
    Provider.family<AsyncValue<List<Book>>, HomeBookTrack>((ref, track) {
  final q = ref.watch(bookSearchQueryProvider).trim().toLowerCase();

  if (track.isStudentCatalog) {
    final asyncBooks = ref.watch(apiStudentBooksForHomeProvider);
    return asyncBooks.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (books) {
        var list = List<Book>.of(books);
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
  }

  final asyncBooks = ref.watch(apiPublicBooksForHomeProvider);
  return asyncBooks.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (books) {
      var list = books.where((b) => b.track == track.apiValue).toList();
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

/// Current tab (segment + swipe) — header count, etc.
final homeDisplayedBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final track = ref.watch(homeBookTrackProvider);
  return ref.watch(homeDisplayedBooksForTrackProvider(track));
});

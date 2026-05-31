import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_provider.dart';
import '../data/services/api_service.dart';
import '../features/home/home_displayed_books_provider.dart';
import 'api_providers.dart';
import 'api_remote_data_epoch.dart';

/// Clears all persisted GET response cache and bumps [apiRemoteDataEpochProvider] so
/// every API-backed provider that watches the epoch reloads from the network.
Future<void> refreshAllRemoteApiData(WidgetRef ref) async {
  await ref.read(apiServiceProvider).bustAllHttpGetDiskCache();
  ref.read(apiRemoteDataEpochProvider.notifier).state++;
}

String? _booksSearchQueryArg(WidgetRef ref) {
  final query = ref.read(bookSearchQueryProvider).trim();
  return query.isEmpty ? null : query;
}

/// Drops disk cache for `books.php` (public + student scopes, optional search).
Future<void> bustBooksCatalogCacheForRef(WidgetRef ref) async {
  await ref
      .read(apiServiceProvider)
      .bustBooksCatalogCache(searchQuery: _booksSearchQueryArg(ref));
}

/// Clears `books.php` for anonymous and the current bearer (tags differ in disk cache).
Future<void> bustBooksCatalogCacheAllAuthTags(WidgetRef ref) async {
  final searchQuery = _booksSearchQueryArg(ref);
  await ApiService().bustBooksCatalogCache(searchQuery: searchQuery);
  await bustBooksCatalogCacheForRef(ref);
}

/// Riverpod book-list providers that read [ApiService.fetchBooks] / [searchBooks].
void invalidateBooksCatalogProviders(WidgetRef ref) {
  ref.invalidate(apiPublicBooksForHomeProvider);
  ref.invalidate(apiStudentBooksForHomeProvider);
  ref.invalidate(apiBooksProvider);
  ref.invalidate(apiSearchBooksProvider);
}

/// Fresh catalog from network after clearing persisted `books.php` cache.
Future<void> reloadBooksCatalogFromNetwork(WidgetRef ref) async {
  await bustBooksCatalogCacheAllAuthTags(ref);
  invalidateBooksCatalogProviders(ref);
}

/// Clears persisted `units.php` / `sections.php` cache for home catalog books.
Future<void> bustCatalogStructureCacheForHomeBooks(WidgetRef ref) async {
  final api = ref.read(apiServiceProvider);
  final bookIds = <int>{};

  try {
    final public = ref.read(apiPublicBooksForHomeProvider).valueOrNull;
    if (public != null) {
      bookIds.addAll(public.map((b) => b.id));
    }
  } catch (_) {}

  try {
    final student = ref.read(apiStudentBooksForHomeProvider).valueOrNull;
    if (student != null) {
      bookIds.addAll(student.map((b) => b.id));
    }
  } catch (_) {}

  for (final id in bookIds) {
    await api.bustUnitsCache(id);
  }
  invalidateUnitsProvidersForBooks(ref, bookIds);

  for (final bookId in bookIds) {
    try {
      final units = await api.fetchUnits(bookId);
      for (final unitInfo in units) {
        await api.bustSectionsCache(bookId, unitInfo.unit);
      }
    } catch (_) {}
  }
}

void invalidateUnitsProvidersForBooks(WidgetRef ref, Iterable<int> bookIds) {
  for (final id in bookIds) {
    ref.invalidate(apiUnitsProvider(id));
  }
}

/// Fresh sections list for one unit after clearing persisted `sections.php` cache.
Future<void> reloadSectionsFromNetwork(
  WidgetRef ref, {
  required int bookId,
  required int unit,
}) async {
  await ref.read(apiServiceProvider).bustSectionsCache(bookId, unit);
  final key = (bookId: bookId, unit: unit);
  ref.invalidate(apiSectionsProvider(key));
  await ref.read(apiSectionsProvider(key).future);
}

/// Splash / onboarding: bust stale disk cache, then warm Home providers.
Future<void> prefetchBooksCatalogForHome(WidgetRef ref) async {
  await ref.read(authProvider.future);
  await reloadBooksCatalogFromNetwork(ref);
  try {
    await ref.read(apiPublicBooksForHomeProvider.future);
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user != null &&
        (user.studentAccess || user.isTeacher || user.isAdmin)) {
      await ref.read(apiStudentBooksForHomeProvider.future);
    }
    await bustCatalogStructureCacheForHomeBooks(ref);
  } catch (_) {
    invalidateBooksCatalogProviders(ref);
  }
}

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
  } catch (_) {
    invalidateBooksCatalogProviders(ref);
  }
}

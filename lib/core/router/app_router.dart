import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/favorites_screen.dart';
import '../../features/flashcards/flashcards_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/sections/sections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/units/units_screen.dart';
import '../../features/words/words_screen.dart';

// ─── LOCAL EXCEL MODE routes (commented out) ─────────────────────────────────
// import '../../features/home/home_screen.dart';     // same file, different providers
//
// Route tree when using local Excel data:
//   /books/:bookId/units              → UnitsScreen(assetPath: decoded bookId)
//   /books/:bookId/units/:unit        → SectionsScreen(assetPath, unit)
//   /books/:bookId/units/:unit/sections/:section
//                                     → WordsScreen(assetPath, unit, section)
//   /books/:bookId/units/:unit/sections/:section/flashcards
//                                     → FlashcardsScreen(assetPath, unit, section)
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // ── API MODE routes ────────────────────────────────────────────────────
      // :bookId is a numeric database ID (int).

      // Books → Units
      GoRoute(
        path: '/books/:bookId/units',
        builder: (context, state) {
          final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
          return UnitsScreen(bookId: bookId);
        },
      ),

      // Units → Sections  (unit HAS sections)
      GoRoute(
        path: '/books/:bookId/units/:unit/sections',
        builder: (context, state) {
          final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
          final unit   = int.tryParse(state.pathParameters['unit']   ?? '') ?? 1;
          return SectionsScreen(bookId: bookId, unit: unit);
        },
      ),

      // Sections → Words  (with a specific section)
      GoRoute(
        path: '/books/:bookId/units/:unit/sections/:section/words',
        builder: (context, state) {
          final bookId  = int.tryParse(state.pathParameters['bookId']  ?? '') ?? 0;
          final unit    = int.tryParse(state.pathParameters['unit']    ?? '') ?? 1;
          final section = int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
          return WordsScreen(bookId: bookId, unit: unit, section: section);
        },
      ),

      // Unit → Words directly  (unit has NO sections)
      GoRoute(
        path: '/books/:bookId/units/:unit/words',
        builder: (context, state) {
          final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
          final unit   = int.tryParse(state.pathParameters['unit']   ?? '') ?? 1;
          return WordsScreen(bookId: bookId, unit: unit, section: null);
        },
      ),

      // Flashcards with section
      GoRoute(
        path: '/books/:bookId/units/:unit/sections/:section/flashcards',
        builder: (context, state) {
          final bookId  = int.tryParse(state.pathParameters['bookId']  ?? '') ?? 0;
          final unit    = int.tryParse(state.pathParameters['unit']    ?? '') ?? 1;
          final section = int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
          return FlashcardsScreen(bookId: bookId, unit: unit, section: section);
        },
      ),

      // Flashcards without section
      GoRoute(
        path: '/books/:bookId/units/:unit/flashcards',
        builder: (context, state) {
          final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
          final unit   = int.tryParse(state.pathParameters['unit']   ?? '') ?? 1;
          return FlashcardsScreen(bookId: bookId, unit: unit, section: null);
        },
      ),

      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});

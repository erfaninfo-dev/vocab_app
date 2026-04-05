import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/favorites_screen.dart';
import '../../features/flashcards/flashcards_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/sections/sections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/units/units_screen.dart';
import '../../features/words/words_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Splash (no shell) ──────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

      // ── Shell: all screens share the bottom NavigationBar ─────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/review',   builder: (_, __) => const ReviewScreen()),
          GoRoute(path: '/stats',    builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

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

          // Quiz with section
          GoRoute(
            path: '/books/:bookId/units/:unit/sections/:section/quiz',
            builder: (context, state) {
              final bookId  = int.tryParse(state.pathParameters['bookId']  ?? '') ?? 0;
              final unit    = int.tryParse(state.pathParameters['unit']    ?? '') ?? 1;
              final section = int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
              return QuizScreen(bookId: bookId, unit: unit, section: section);
            },
          ),

          // Quiz without section
          GoRoute(
            path: '/books/:bookId/units/:unit/quiz',
            builder: (context, state) {
              final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit   = int.tryParse(state.pathParameters['unit']   ?? '') ?? 1;
              return QuizScreen(bookId: bookId, unit: unit);
            },
          ),

          GoRoute(
            path: '/favorites',
            builder: (_, __) => const FavoritesScreen(),
          ),
        ],
      ),
    ],
  );
});

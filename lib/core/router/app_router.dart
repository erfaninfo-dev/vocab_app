import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/favorites_screen.dart';
import '../../features/grammar/grammar_quiz_screen.dart';
import '../../features/grammar/grammar_result_review_screen.dart';
import '../../features/grammar/grammar_results_screen.dart';
import '../../features/grammar/grammar_topics_screen.dart';
import '../../features/flashcards/flashcards_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quiz/book_vocab_quiz_setup_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/sections/sections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/auth_hub_screen.dart';
import '../../features/onboarding/language_selection_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/learning_insights_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/units/units_screen.dart';
import '../../features/words/words_screen.dart';
import '../../domain/api_providers.dart';

List<String> _grammarPracticeTopics(GoRouterState state) {
  final multi = state.uri.queryParametersAll['topic'];
  if (multi != null && multi.isNotEmpty) return multi;
  final one = state.uri.queryParameters['topic'];
  if (one != null && one.trim().isNotEmpty) return [one.trim()];
  return const [];
}

int _grammarPracticeQuestionCount(GoRouterState state) {
  final topics = _grammarPracticeTopics(state);
  final raw = state.uri.queryParameters['count'] ?? state.uri.queryParameters['n'];
  final parsed = int.tryParse(raw ?? '');
  final n = parsed ?? kGrammarQuizDefaultQuestionCount;
  final floor = topics.isEmpty
      ? 1
      : grammarQuizMinQuestionsForTopics(topics.length);
  return n.clamp(floor, kGrammarQuizSessionSize);
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Splash (no shell) ──────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

      // First-launch guide (no shell)
      GoRoute(
        path: '/language',
        builder: (_, __) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      GoRoute(path: '/auth', builder: (_, __) => const AuthHubScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // ── Shell: all screens share the bottom NavigationBar ─────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),

          GoRoute(
            path: '/grammar',
            builder: (_, __) => const GrammarTopicsScreen(),
          ),
          GoRoute(
            path: '/grammar/results',
            builder: (_, __) => const GrammarResultsScreen(),
          ),
          GoRoute(
            path: '/grammar/result/:resultId',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['resultId'] ?? '') ?? 0;
              return GrammarResultReviewScreen(resultId: id);
            },
          ),
          GoRoute(
            path: '/grammar/practice',
            builder: (context, state) {
              final topics = _grammarPracticeTopics(state);
              final count = _grammarPracticeQuestionCount(state);
              return GrammarQuizScreen(
                key: ValueKey('${grammarTopicsCacheKey(topics)}_$count'),
                topics: topics,
                questionCount: count,
              );
            },
          ),
          GoRoute(path: '/review',   builder: (_, __) => const ReviewScreen()),
          GoRoute(path: '/stats',    builder: (_, __) => const StatsScreen()),
          GoRoute(
            path: '/stats/insights',
            builder: (_, __) => const LearningInsightsScreen(),
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

          // Books → Units
          GoRoute(
            path: '/books/:bookId/units',
            builder: (context, state) {
              final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return UnitsScreen(bookId: bookId);
            },
          ),

          /// Multi-unit / whole-book quiz (query: units, count, scope)
          GoRoute(
            path: '/books/:bookId/quiz',
            builder: (context, state) {
              final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return QuizScreen(bookId: bookId);
            },
          ),

          GoRoute(
            path: '/books/:bookId/vocab-quiz',
            builder: (context, state) {
              final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return BookVocabQuizSetupScreen(bookId: bookId);
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
              // Use the same setup screen as book-level quiz, but seed only this unit.
              // (User can still select other units.)
              return BookVocabQuizSetupScreen(
                bookId: bookId,
                initialSelectedUnits: {unit},
              );
            },
          ),

          // Quiz without section
          GoRoute(
            path: '/books/:bookId/units/:unit/quiz',
            builder: (context, state) {
              final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit   = int.tryParse(state.pathParameters['unit']   ?? '') ?? 1;
              return BookVocabQuizSetupScreen(
                bookId: bookId,
                initialSelectedUnits: {unit},
              );
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

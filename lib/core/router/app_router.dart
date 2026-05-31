import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../tts/tts_service.dart';
import '../../data/models/league.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/word_builder/word_builder_constants.dart';
import '../../features/word_builder/presentation/word_builder_lobby_screen.dart';
import '../../features/word_builder/presentation/word_builder_ltr_scope.dart';
import '../../features/word_builder/presentation/word_builder_session_screen.dart';
import '../../features/word_builder/presentation/word_builder_campaign_stages_screen.dart';
import '../../features/word_builder/domain/word_builder_models.dart';
import '../../features/grammar/grammar_quiz_screen.dart';
import '../../features/grammar/grammar_result_review_screen.dart';
import '../../features/grammar/grammar_results_screen.dart';
import '../../features/grammar/grammar_topics_screen.dart';
import '../../features/flashcards/flashcards_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/series_books_screen.dart';
import '../../features/league/league_screen.dart';
import '../../features/quiz/book_vocab_quiz_setup_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/review/review_screen.dart';
import '../../features/sections/sections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/shell/shell_scaffold.dart';
import '../../features/auth/login_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/auth_hub_screen.dart';
import '../../features/onboarding/language_selection_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/learning_insights_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/stories/admin_story_audience_screen.dart';
import '../../features/stories/admin_story_create_screen.dart';
import '../../features/stories/story_viewer_screen.dart';
import '../../features/you/you_screen.dart';
import '../../features/you/student_class_sessions_screen.dart';
import '../../features/you/student_panel_screen.dart';
import '../../features/you/student_message_peers_screen.dart';
import '../../features/you/teacher_chat_screen.dart';
import '../../features/teacher/teacher_chat_open_args.dart';
import '../../features/teacher/teacher_dashboard_screen.dart';
import '../../features/teacher/teacher_student_detail_screen.dart';
import '../../features/vocab_quiz/vocab_quiz_history_screen.dart';
import '../../features/vocab_quiz/vocab_quiz_result_detail_screen.dart';
import '../../features/unit_samples/unit_samples_screen.dart';
import '../../features/units/units_screen.dart';
import '../../features/words/words_screen.dart';
import '../../domain/api_providers.dart';

/// Root stack (routes outside [ShellRoute], e.g. `/teacher/...`).
final GlobalKey<NavigatorState> _routerRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'routerRoot');

/// Inner stack for tab shell (`/home`, `/grammar`, …).
final GlobalKey<NavigatorState> _routerShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'routerShell');

List<String> _grammarPracticeTopics(GoRouterState state) {
  final multi = state.uri.queryParametersAll['topic'];
  if (multi != null && multi.isNotEmpty) return multi;
  final one = state.uri.queryParameters['topic'];
  if (one != null && one.trim().isNotEmpty) return [one.trim()];
  return const [];
}

int _grammarPracticeQuestionCount(GoRouterState state) {
  final topics = _grammarPracticeTopics(state);
  final raw =
      state.uri.queryParameters['count'] ?? state.uri.queryParameters['n'];
  final parsed = int.tryParse(raw ?? '');
  final n = parsed ?? kGrammarQuizDefaultQuestionCount;
  final floor = topics.isEmpty
      ? 1
      : grammarQuizMinQuestionsForTopics(topics.length);
  return n.clamp(floor, kGrammarQuizSessionSize);
}

final routerProvider = Provider<GoRouter>((ref) {
  Future<void> stopTts() => ref.read(ttsProvider.notifier).stop();
  final rootTtsSilencer = TtsNavigatorSilencer(stopTts);
  final shellTtsSilencer = TtsNavigatorSilencer(stopTts);

  return GoRouter(
    navigatorKey: _routerRootNavigatorKey,
    observers: [rootTtsSilencer],
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

      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/stories/create',
        builder: (_, __) => const AdminStoryCreateScreen(),
      ),
      GoRoute(
        path: '/stories/viewer',
        builder: (_, state) => StoryViewerScreen(
          initialStoryId: int.tryParse(
            state.uri.queryParameters['storyId'] ?? '',
          ),
          grammarOnly: state.uri.queryParameters['scope'] == 'grammar',
        ),
      ),
      GoRoute(
        path: '/stories/admin/audience/:storyId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['storyId'] ?? '') ?? 0;
          return AdminStoryAudienceScreen(storyId: id);
        },
      ),

      GoRoute(
        path: '/teacher',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return TeacherDashboardScreen(
            initialTab: switch (tab) {
              'messages' => TeacherPanelTab.messages,
              'schedule' => TeacherPanelTab.schedule,
              'finance' => TeacherPanelTab.finance,
              _ => TeacherPanelTab.students,
            },
          );
        },
      ),
      // Legacy entry point — the teacher inbox is now the Messages tab of the
      // unified panel. Redirect so old deep links keep working.
      GoRoute(
        path: '/teacher/inbox',
        redirect: (_, __) => '/teacher?tab=messages',
      ),
      GoRoute(
        path: '/student-panel',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return StudentPanelScreen(
            initialTab: switch (tab) {
              'sessions' => StudentPanelTab.classSessions,
              'review' => StudentPanelTab.review,
              _ => StudentPanelTab.progress,
            },
          );
        },
      ),
      GoRoute(
        path: '/teacher/student/:studentId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '') ?? 0;
          return TeacherStudentDetailScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/teacher/chat/:studentId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['studentId'] ?? '') ?? 0;
          final extra = state.extra;
          TeacherChatOpenArgs? peer;
          String? hint;
          if (extra is TeacherChatOpenArgs) {
            peer = extra;
          } else if (extra is String) {
            hint = extra;
          }
          return TeacherChatScreen(
            studentId: id,
            peerTitleHint: hint,
            teacherPeer: peer,
          );
        },
      ),

      // Full-screen grammar review on the root stack (outside [ShellRoute]).
      // Pushing `/grammar/result/...` from `/teacher/...` must not target the
      // shell navigator — that caused duplicate route key assertions.
      GoRoute(
        path: '/grammar/result/:resultId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['resultId'] ?? '') ?? 0;
          return GrammarResultReviewScreen(
            key: ValueKey<String>('grammar_result_$id'),
            resultId: id,
          );
        },
      ),

      // ── Shell: all screens share the bottom NavigationBar ─────────────────
      ShellRoute(
        navigatorKey: _routerShellNavigatorKey,
        observers: [shellTtsSilencer],
        builder: (context, state, child) =>
            ShellScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

          GoRoute(
            path: '/series-books',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is SeriesBooksRouteArgs) {
                return SeriesBooksScreen(
                  title: extra.title,
                  books: extra.books,
                );
              }
              return const _SeriesBooksInvalidRoute();
            },
          ),

          GoRoute(
            path: '/word-builder',
            builder: (_, __) =>
                const WordBuilderLtrScope(child: WordBuilderLobbyScreen()),
          ),
          GoRoute(
            path: '/word-builder/campaign',
            builder: (context, state) {
              final raw = state.uri.queryParameters['difficulty'] ?? 'beginner';
              final d = switch (raw) {
                'intermediate' => WordBuilderDifficulty.intermediate,
                'advanced' => WordBuilderDifficulty.advanced,
                _ => WordBuilderDifficulty.beginner,
              };
              return WordBuilderLtrScope(
                child: WordBuilderCampaignStagesScreen(difficulty: d),
              );
            },
          ),
          GoRoute(
            path: '/word-builder/session',
            builder: (context, state) {
              final q = state.uri.queryParameters['bookId'] ?? 'all';
              final key = q == 'all'
                  ? kWordBuilderAllBooksKey
                  : (int.tryParse(q) ?? kWordBuilderAllBooksKey);
              return WordBuilderLtrScope(
                child: WordBuilderSessionScreen(bookKey: key),
              );
            },
          ),

          GoRoute(
            path: '/grammar',
            builder: (_, __) => const GrammarTopicsScreen(),
          ),
          GoRoute(
            path: '/league',
            builder: (_, state) => LeagueScreen(
              initialType: LeagueType.fromApi(
                state.uri.queryParameters['type'],
              ),
            ),
          ),
          GoRoute(
            path: '/grammar/results',
            builder: (_, __) => const GrammarResultsScreen(),
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
          GoRoute(path: '/review', builder: (_, __) => const ReviewScreen()),
          GoRoute(
            path: '/you/messages/pick',
            builder: (_, __) => const StudentMessagePeersScreen(),
          ),
          GoRoute(
            path: '/you/messages',
            builder: (context, state) {
              final raw = state.uri.queryParameters['peer_teacher_id'];
              final pid = int.tryParse(raw ?? '');
              return TeacherChatScreen(
                peerTeacherId: pid != null && pid > 0 ? pid : null,
              );
            },
          ),
          GoRoute(
            path: '/you/class-sessions',
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final initial = tab == 'schedule' ? 1 : 0;
              return StudentClassSessionsScreen(initialTabIndex: initial);
            },
          ),
          GoRoute(path: '/you', builder: (_, __) => const YouScreen()),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(
            path: '/stats/insights',
            builder: (_, __) => const LearningInsightsScreen(),
          ),
          GoRoute(
            path: '/vocab-quiz/history',
            builder: (_, __) => const VocabQuizHistoryScreen(),
          ),
          GoRoute(
            path: '/vocab-quiz/result/:resultId',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['resultId'] ?? '') ?? 0;
              final mistakesOnly = state.uri.queryParameters['mistakes'] == '1';
              return VocabQuizResultDetailScreen(
                resultId: id,
                mistakesOnly: mistakesOnly,
              );
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),

          // Books → Units
          GoRoute(
            path: '/books/:bookId/units',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return UnitsScreen(bookId: bookId);
            },
          ),

          /// Multi-unit / whole-book quiz (query: units, count, scope)
          GoRoute(
            path: '/books/:bookId/quiz',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return QuizScreen(bookId: bookId);
            },
          ),

          GoRoute(
            path: '/books/:bookId/vocab-quiz',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              return BookVocabQuizSetupScreen(bookId: bookId);
            },
          ),

          // Units → Sections  (unit HAS sections)
          GoRoute(
            path: '/books/:bookId/units/:unit/sections',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              return SectionsScreen(bookId: bookId, unit: unit);
            },
          ),

          // Sections → Words  (with a specific section)
          GoRoute(
            path: '/books/:bookId/units/:unit/sections/:section/words',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              final section =
                  int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
              return WordsScreen(bookId: bookId, unit: unit, section: section);
            },
          ),

          // Unit → Words directly  (unit has NO sections)
          GoRoute(
            path: '/books/:bookId/units/:unit/words',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              return WordsScreen(bookId: bookId, unit: unit, section: null);
            },
          ),

          // Unit + Section → Sample texts
          GoRoute(
            path: '/books/:bookId/units/:unit/sections/:section/samples',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              final section =
                  int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
              return UnitSamplesScreen(
                bookId: bookId,
                unit: unit,
                section: section,
              );
            },
          ),

          // Unit → Sample texts (no section)
          GoRoute(
            path: '/books/:bookId/units/:unit/samples',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              return UnitSamplesScreen(bookId: bookId, unit: unit);
            },
          ),

          // Flashcards with section
          GoRoute(
            path: '/books/:bookId/units/:unit/sections/:section/flashcards',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              final section =
                  int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
              return FlashcardsScreen(
                bookId: bookId,
                unit: unit,
                section: section,
              );
            },
          ),

          // Flashcards without section
          GoRoute(
            path: '/books/:bookId/units/:unit/flashcards',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              return FlashcardsScreen(
                bookId: bookId,
                unit: unit,
                section: null,
              );
            },
          ),

          // Quiz with section
          GoRoute(
            path: '/books/:bookId/units/:unit/sections/:section/quiz',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              final section =
                  int.tryParse(state.pathParameters['section'] ?? '') ?? 1;
              return BookVocabQuizSetupScreen(
                bookId: bookId,
                lockedUnit: unit,
                initialSelectedSections: {
                  unit: {section},
                },
              );
            },
          ),

          // Quiz without section
          GoRoute(
            path: '/books/:bookId/units/:unit/quiz',
            builder: (context, state) {
              final bookId =
                  int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
              final unit =
                  int.tryParse(state.pathParameters['unit'] ?? '') ?? 1;
              return BookVocabQuizSetupScreen(bookId: bookId, lockedUnit: unit);
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

class _SeriesBooksInvalidRoute extends StatelessWidget {
  const _SeriesBooksInvalidRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

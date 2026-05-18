import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/stats/stats_service.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'combined_quiz_group_chart.dart';
import 'grammar_stats_charts.dart';
import 'quiz_insights_data.dart';
import 'vocab_quiz_daily_chart.dart';

/// Full breakdown: vocabulary (local) + grammar (server) charts.
class LearningInsightsScreen extends ConsumerStatefulWidget {
  const LearningInsightsScreen({super.key});

  @override
  ConsumerState<LearningInsightsScreen> createState() =>
      _LearningInsightsScreenState();
}

class _LearningInsightsScreenState extends ConsumerState<LearningInsightsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.insightsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.tabOverview),
            Tab(text: l10n.tabVocabulary),
            Tab(text: l10n.tabGrammarStats),
          ],
          labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(scheme: scheme),
          _VocabularyTab(scheme: scheme),
          const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: GrammarStatsCharts(),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(statsProvider);
    final loggedIn = ref.watch(authProvider).valueOrNull != null;
    final grammarAsync = ref.watch(grammarStatsChartResultsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          l10n.insightsLast14,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        if (!loggedIn)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.insightsSignInGrammar,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!loggedIn) const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: grammarAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                l10n.insightsGrammarLoadError,
                style: TextStyle(color: scheme.error),
              ),
              data: (grammar) {
                final pairs = buildDailyQuizPairs(
                  stats: stats,
                  grammarResults: grammar,
                  days: 14,
                );
                return CombinedQuizGroupChart(
                  days: pairs,
                  scheme: scheme,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _VocabularyTab extends ConsumerWidget {
  const _VocabularyTab({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(statsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          l10n.vocabDailyAccuracy,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: VocabQuizDailyChart(stats: stats, scheme: scheme),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.allTimeDevice,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.statsQuizCorrectFraction(
                    stats.totalQuizCorrect,
                    stats.totalQuizAnswered,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  l10n.statsAccuracyPercent(
                    (stats.quizAccuracy * 100).toStringAsFixed(1),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

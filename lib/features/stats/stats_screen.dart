import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/stats/stats_service.dart';
import '../../l10n/app_localizations.dart';
import '../grammar/grammar_results_screen.dart';
import '../vocab_quiz/vocab_quiz_history_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;

    final tabBar = TabBar(
      controller: _tabController,
      indicatorWeight: 3,
      labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle:
          tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
      tabs: [
        Tab(text: l10n.statsTabVocab),
        Tab(text: l10n.statsTabGrammar),
        Tab(text: l10n.statsTabProgress),
      ],
    );

    final tabView = TabBarView(
      controller: _tabController,
      children: [
        _StatsTabScaffold(
          child: const VocabQuizHistoryBody(),
        ),
        _StatsTabScaffold(
          child: const GrammarStatsTabPanel(),
        ),
        const _StatsProgressTab(),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          Material(color: scheme.surface, child: tabBar),
          Expanded(child: tabView),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.statsMyProgress),
        bottom: tabBar,
      ),
      body: tabView,
    );
  }
}

class _StatsTabScaffold extends StatelessWidget {
  const _StatsTabScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary.withOpacity(0.07),
            scheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}

class _StatsProgressTab extends ConsumerWidget {
  const _StatsProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final mastery = ref.watch(wordMasteryProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary.withOpacity(0.07),
            scheme.surface,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StreakCard(
            l10n: l10n,
            current: stats.currentStreak,
            longest: stats.longestStreak,
            totalDays: stats.totalStudyDays,
            studiedToday: stats.studiedToday,
          ),
          const SizedBox(height: 14),
          _SectionLabel(l10n.wordMastery),
          const SizedBox(height: 8),
          _MasteryCard(l10n: l10n, mastery: mastery),
          const SizedBox(height: 14),
          _SectionLabel(l10n.last7Days),
          const SizedBox(height: 8),
          _WeeklyChart(l10n: l10n, days: stats.last7Days),
          const SizedBox(height: 14),
          _SectionLabel(l10n.quizInsights),
          const SizedBox(height: 8),
          _QuizInsightsEntryCard(
            l10n: l10n,
            scheme: scheme,
            vocabAccuracy: stats.quizAccuracy,
            vocabAnswered: stats.totalQuizAnswered,
            vocabCorrect: stats.totalQuizCorrect,
          ),
          const SizedBox(height: 14),
          _SectionLabel(l10n.allTime),
          const SizedBox(height: 8),
          _TotalsRow(
            l10n: l10n,
            wordsReviewed: stats.totalWordsReviewed,
            studyDays: stats.totalStudyDays,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}

// ─── Quiz insights entry → /stats/insights ────────────────────────────────────

class _QuizInsightsEntryCard extends StatelessWidget {
  const _QuizInsightsEntryCard({
    required this.l10n,
    required this.scheme,
    required this.vocabAccuracy,
    required this.vocabAnswered,
    required this.vocabCorrect,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final double vocabAccuracy;
  final int vocabAnswered;
  final int vocabCorrect;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/stats/insights'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.insights_rounded, size: 44, color: scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vocabAndGrammar,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.statsInsightsCardSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (vocabAnswered > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.statsVocabDeviceAccuracy(
                          (vocabAccuracy * 100).toStringAsFixed(0),
                          vocabCorrect,
                          vocabAnswered,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.l10n,
    required this.current,
    required this.longest,
    required this.totalDays,
    required this.studiedToday,
  });

  final AppLocalizations l10n;
  final int current;
  final int longest;
  final int totalDays;
  final bool studiedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.streakDays(current),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      studiedToday
                          ? l10n.statsStudiedToday
                          : l10n.statsStudyToKeepStreak,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StreakStat(
                label: l10n.longest,
                value: l10n.statsDaysOnly(longest),
                icon: '🏆',
              ),
              const SizedBox(width: 12),
              _StreakStat(
                label: l10n.totalDays,
                value: l10n.statsDaysOnly(totalDays),
                icon: '📅',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Word Mastery Card ────────────────────────────────────────────────────────

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.l10n, required this.mastery});

  final AppLocalizations l10n;
  final WordMastery mastery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = mastery.total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MasteryDot(color: Colors.green.shade400),
                const SizedBox(width: 8),
                Text(
                  l10n.mastered,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${mastery.mastered}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MasteryBar(
              value: total == 0 ? 0 : mastery.mastered / total,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MasteryDot(color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Text(l10n.learning, style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${mastery.learning}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MasteryBar(
              value: total == 0 ? 0 : mastery.learning / total,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MasteryDot(color: scheme.primary.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(l10n.seenOnce, style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${mastery.seen}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MasteryBar(
              value: total == 0 ? 0 : mastery.seen / total,
              color: scheme.primary.withOpacity(0.5),
            ),
            if (total > 0) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  l10n.statsWordsStudiedTotal(total),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MasteryDot extends StatelessWidget {
  const _MasteryDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _MasteryBar extends StatelessWidget {
  const _MasteryBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        color: color,
        backgroundColor: color.withOpacity(0.15),
      ),
    );
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.l10n, required this.days});

  final AppLocalizations l10n;
  final List<DayActivity> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxWords =
        days.map((d) => d.wordsReviewed).fold(0, (a, b) => a > b ? a : b);
    final maxVal = maxWords == 0 ? 1 : maxWords;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.wordsReviewedPerDay,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  final ratio = day.wordsReviewed / maxVal;
                  final isToday = _isToday(day.date);
                  final dayName = _shortDay(context, day.date);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (day.wordsReviewed > 0)
                            Text(
                              '${day.wordsReviewed}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final h = constraints.maxHeight;
                                  final barH = day.wordsReviewed == 0
                                      ? 4.0
                                      : (h * ratio).clamp(4.0, h);
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    height: barH,
                                    decoration: BoxDecoration(
                                      color: day.wordsReviewed == 0
                                          ? scheme.outlineVariant
                                              .withOpacity(0.3)
                                          : isToday
                                              ? scheme.primary
                                              : scheme.primary.withOpacity(0.5),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.normal,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _shortDay(BuildContext context, DateTime d) {
    return DateFormat.E(
      Localizations.localeOf(context).toString(),
    ).format(d);
  }
}

// ─── Totals Row ───────────────────────────────────────────────────────────────

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.l10n,
    required this.wordsReviewed,
    required this.studyDays,
  });

  final AppLocalizations l10n;
  final int wordsReviewed;
  final int studyDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: '📖',
            value: '$wordsReviewed',
            label: l10n.totalReviews,
            color: Colors.blue.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(
            icon: '🗓️',
            value: '$studyDays',
            label: l10n.studyDays,
            color: Colors.purple.shade400,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final String icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

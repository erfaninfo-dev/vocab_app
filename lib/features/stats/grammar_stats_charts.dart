import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_result.dart';
import '../../domain/api_providers.dart';

/// Grammar quiz trends (uses saved results from the server).
class GrammarStatsCharts extends ConsumerWidget {
  const GrammarStatsCharts({super.key});

  static double? _accuracy(GrammarResult r) {
    final s = r.score;
    final t = r.totalQuestions;
    if (s == null || t == null || t <= 0) return null;
    return (s / t) * 100;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loggedIn = ref.watch(authProvider).valueOrNull != null;

    if (!loggedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.rule_rounded, color: scheme.primary, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Sign in to see grammar score trends from your saved quizzes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(grammarStatsChartResultsProvider);

    return async.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: scheme.primary),
          ),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Could not load grammar stats.',
            style: TextStyle(color: scheme.error),
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: scheme.outline, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No grammar results yet. Complete a grammar quiz and save your score.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final withPct = <({GrammarResult r, double pct})>[];
        for (final r in results) {
          final a = _accuracy(r);
          if (a != null) withPct.add((r: r, pct: a));
        }
        if (withPct.isEmpty) {
          return const SizedBox.shrink();
        }

        final last15 = withPct.length > 15 ? withPct.sublist(0, 15) : withPct;
        final chronological = last15.reversed.toList();
        final avg = chronological.map((e) => e.pct).reduce((a, b) => a + b) /
            chronological.length;

        final spots = <FlSpot>[
          for (var i = 0; i < chronological.length; i++)
            FlSpot(i.toDouble(), chronological[i].pct),
        ];

        final minY = (chronological.map((e) => e.pct).reduce(math.min) - 5)
            .clamp(0.0, 100.0);
        final maxY = (chronological.map((e) => e.pct).reduce(math.max) + 5)
            .clamp(0.0, 100.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grammar overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Average (last ${chronological.length} saved): '
                      '${avg.round()}%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Score trend (oldest → newest)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (chronological.length < 2)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Save at least two grammar quizzes to see a line chart.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minY: minY,
                            maxY: maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: scheme.outlineVariant.withValues(alpha: 0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 20,
                                  getTitlesWidget: (v, m) => Text(
                                    '${v.round()}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: math.max(1, (spots.length / 6).ceil().toDouble()),
                                  getTitlesWidget: (v, m) {
                                    final i = v.round();
                                    if (i < 0 || i >= chronological.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${i + 1}',
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.25,
                                color: scheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (s, p, b, i) =>
                                      FlDotCirclePainter(
                                    radius: 3.5,
                                    color: scheme.primary,
                                    strokeWidth: 1,
                                    strokeColor: scheme.surface,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: scheme.primary.withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attempts distribution',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: _AccuracyBucketsBar(
                              results: withPct.map((e) => e.pct).toList(),
                              scheme: scheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Groups accuracies into 0–40, 40–60, 60–80, 80–100 buckets.
class _AccuracyBucketsBar extends StatelessWidget {
  const _AccuracyBucketsBar({
    required this.results,
    required this.scheme,
  });

  final List<double> results;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final buckets = [0, 0, 0, 0];
    for (final p in results) {
      if (p < 40) {
        buckets[0]++;
      } else if (p < 60) {
        buckets[1]++;
      } else if (p < 80) {
        buckets[2]++;
      } else {
        buckets[3]++;
      }
    }
    final maxC = buckets.reduce(math.max);
    final labels = ['0–39%', '40–59%', '60–79%', '80–100%'];
    final colors = [
      scheme.error.withValues(alpha: 0.75),
      scheme.tertiary.withValues(alpha: 0.8),
      scheme.secondary.withValues(alpha: 0.85),
      Colors.green.shade600,
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxC > 0 ? maxC.toDouble() + 0.5 : 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) => Text(
                v == v.roundToDouble() ? '${v.toInt()}' : '',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (i, m) {
                final idx = i.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < 4; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: maxC > 0 ? buckets[i].toDouble() : 0,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: colors[i],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

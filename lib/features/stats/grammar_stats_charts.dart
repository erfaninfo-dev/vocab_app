import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

/// Grammar quiz trends (uses saved results from the server).
class GrammarStatsCharts extends ConsumerWidget {
  const GrammarStatsCharts({super.key});

  static double? _accuracy(GrammarResult r) {
    final s = r.score;
    final t = r.totalQuestions;
    if (s == null || t == null || t <= 0) return null;
    return (s / t) * 100;
  }

  static DateTime? _parseCreatedAt(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  static String _mmDd(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.statsSignInGrammarTrend,
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
            l10n.statsCouldNotLoadGrammar,
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
                      l10n.statsNoGrammarYet,
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

        final attemptCount = chronological.length;
        final last = chronological.isNotEmpty ? chronological.last : null;
        final best = chronological.map((e) => e.pct).reduce(math.max);
        final worst = chronological.map((e) => e.pct).reduce(math.min);
        final trendDelta = (chronological.length >= 2)
            ? (chronological.last.pct - chronological.first.pct)
            : null;

        final spots = <FlSpot>[
          for (var i = 0; i < chronological.length; i++)
            FlSpot(i.toDouble(), chronological[i].pct),
        ];

        final minY = (chronological.map((e) => e.pct).reduce(math.min) - 5)
            .clamp(0.0, 100.0);
        final maxY = (chronological.map((e) => e.pct).reduce(math.max) + 5)
            .clamp(0.0, 100.0);

        final n = chronological.length;
        final tickStep = math.max(1, (n / 4).floor()); // show ~5 ticks max
        final shown = <int>{0, tickStep, tickStep * 2, tickStep * 3, n - 1}
          ..removeWhere((i) => i < 0 || i >= n);

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
                      l10n.grammarOverview,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.averageLastAttempts(attemptCount)}'
                      '${avg.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _MetricChip(
                          icon: Icons.numbers_rounded,
                          label: l10n.attempts,
                          value: '$attemptCount',
                          scheme: scheme,
                        ),
                        if (last != null)
                          _MetricChip(
                            icon: Icons.schedule_rounded,
                            label: l10n.lastLabel,
                            value: '${last.pct.toStringAsFixed(1)}%',
                            scheme: scheme,
                          ),
                        _MetricChip(
                          icon: Icons.trending_up_rounded,
                          label: l10n.bestLabel,
                          value: '${best.toStringAsFixed(1)}%',
                          scheme: scheme,
                        ),
                        _MetricChip(
                          icon: Icons.trending_down_rounded,
                          label: l10n.worstLabel,
                          value: '${worst.toStringAsFixed(1)}%',
                          scheme: scheme,
                        ),
                        if (trendDelta != null)
                          _MetricChip(
                            icon: trendDelta >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            label: l10n.trendLabel,
                            value:
                                '${trendDelta >= 0 ? '+' : ''}${trendDelta.toStringAsFixed(1)}%',
                            scheme: scheme,
                          ),
                      ],
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
                        l10n.scoreTrendTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (chronological.length < 2)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.saveTwoQuizzesChart,
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
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipRoundedRadius: 12,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((s) {
                                    final i = s.x.round().clamp(0, n - 1);
                                    final raw = chronological[i].r.createdAt;
                                    final dt = _parseCreatedAt(raw);
                                    final dateLabel = dt != null ? _mmDd(dt) : '#${i + 1}';
                                    final r = chronological[i].r;
                                    final score = r.score ?? 0;
                                    final total = r.totalQuestions ?? 0;
                                    final pct = chronological[i].pct;
                                    return LineTooltipItem(
                                      '$dateLabel\n${pct.toStringAsFixed(1)}% ($score/$total)',
                                      Theme.of(context).textTheme.labelMedium!,
                                    );
                                  }).toList();
                                },
                              ),
                            ),
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
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (v, m) {
                                    final i = v.round();
                                    if (i < 0 || i >= chronological.length) {
                                      return const SizedBox.shrink();
                                    }
                                    if (!shown.contains(i)) {
                                      return const SizedBox.shrink();
                                    }
                                    final dt = _parseCreatedAt(
                                      chronological[i].r.createdAt,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        dt != null ? _mmDd(dt) : '${i + 1}',
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
                      l10n.attemptsDistribution,
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
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 12,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt().clamp(0, 3);
              final count = buckets[idx];
              final total = results.isEmpty ? 0 : results.length;
              final pct = total == 0 ? 0 : (count / total * 100);
              return BarTooltipItem(
                '${labels[idx]}\n$count attempt(s) • ${pct.toStringAsFixed(0)}%',
                Theme.of(context).textTheme.labelMedium!,
              );
            },
          ),
        ),
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/stats/stats_service.dart';
import 'quiz_insights_data.dart';

/// Vocabulary quiz only: daily accuracy % (device), last 14 days — bar chart.
class VocabQuizDailyChart extends StatelessWidget {
  const VocabQuizDailyChart({
    super.key,
    required this.stats,
    required this.scheme,
  });

  final StatsState stats;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final pairs = buildDailyQuizPairs(stats: stats, grammarResults: const []);
    final hasVocab = pairs.any((p) => p.vocabPct != null);
    if (!hasVocab) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Answer vocabulary quiz questions to see daily accuracy here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final n = pairs.length;
    final tickStep = math.max(1, (n / 4).floor()); // show ~5 ticks max
    final shown = <int>{
      0,
      tickStep,
      tickStep * 2,
      tickStep * 3,
      n - 1,
    }..removeWhere((i) => i < 0 || i >= n);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final i = group.x.toInt();
                final label =
                    (i >= 0 && i < n) ? pairs[i].labelMmDd : '';
                final v = rod.toY;
                final pretty = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
                return BarTooltipItem(
                  '$label\n$pretty%',
                  Theme.of(context).textTheme.labelMedium!,
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (v) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, m) => Text(
                  '${v.toInt()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 1,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= n) return const SizedBox.shrink();
                  final shouldShow = shown.contains(i);
                  if (!shouldShow) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      pairs[i].labelMmDd,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < n; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: pairs[i].vocabPct ?? 0,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    color: pairs[i].vocabPct != null
                        ? scheme.tertiary.withValues(alpha: 0.9)
                        : scheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

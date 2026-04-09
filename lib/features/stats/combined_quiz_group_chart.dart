import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'quiz_insights_data.dart';

/// Grouped bars: vocabulary (local) vs grammar (server) per day, 0–100%.
class CombinedQuizGroupChart extends StatelessWidget {
  const CombinedQuizGroupChart({
    super.key,
    required this.days,
    required this.scheme,
  });

  final List<DailyQuizPair> days;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }
    final hasAny = days.any(
      (d) => d.vocabPct != null || d.grammarPct != null,
    );
    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No quiz data in this range yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final maxY = 100.0;
    final n = days.length;
    final tickStep = math.max(1, (n / 4).floor()); // show ~5 ticks max
    final shown = <int>{
      0,
      tickStep,
      tickStep * 2,
      tickStep * 3,
      n - 1,
    }..removeWhere((i) => i < 0 || i >= n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: scheme.tertiary, label: 'Vocabulary'),
            const SizedBox(width: 16),
            _LegendDot(color: scheme.primary, label: 'Grammar'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final i = group.x.toInt();
                    final label =
                        (i >= 0 && i < n) ? days[i].labelMmDd : '';
                    final which = rodIndex == 0 ? 'Vocabulary' : 'Grammar';
                    final v = rod.toY;
                    final pretty =
                        v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
                    return BarTooltipItem(
                      '$label • $which\n$pretty%',
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
                          days[i].labelMmDd,
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
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: days[i].vocabPct ?? 0,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        color: scheme.tertiary.withValues(alpha: 0.9),
                      ),
                      BarChartRodData(
                        toY: days[i].grammarPct ?? 0,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        color: scheme.primary.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

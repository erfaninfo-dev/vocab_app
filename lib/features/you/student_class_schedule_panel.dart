import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/class_schedule_slot.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../class_schedule/schedule_time_format.dart';
import '../class_schedule/weekly_schedule_timeline.dart';

/// Weekly class times — same scale and hierarchy as [StudentClassSessionsPanel],
/// with a distinct schedule identity (clock tiles, calendar header).
class StudentClassSchedulePanel extends ConsumerWidget {
  const StudentClassSchedulePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context);
    final timeFmt = DateFormat.jm(loc.toString());
    final async = ref.watch(myClassScheduleProvider);
    final dayOrder = weekdayDisplayOrder(loc);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userFriendlyErrorMessage(e, l10n),
                textAlign: TextAlign.center,
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(myClassScheduleProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (slots) {
        final byDay = <int, List<ClassScheduleSlot>>{};
        for (var w = 1; w <= 7; w++) {
          byDay[w] = [];
        }
        for (final s in slots) {
          byDay[s.weekday.clamp(1, 7)]!.add(s);
        }
        for (final list in byDay.values) {
          list.sort((a, b) => a.startTime.compareTo(b.startTime));
        }

        final daysWithClass =
            dayOrder.where((w) => byDay[w]!.isNotEmpty).toList();
        final count = slots.length;

        final headerInner = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: scheme.onSecondaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.teacherTabWeeklySchedule,
                    style: tt.titleMedium,
                  ),
                ),
                if (count > 0)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '$count',
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.youClassScheduleSubtitle,
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        );

        final header = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: headerInner),
        );

        if (daysWithClass.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.classScheduleEmpty,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final list = WeeklyScheduleTimelineList(
          daysWithClass: daysWithClass,
          byDay: byDay,
          scheme: scheme,
          tt: tt,
          buildSlot: (s) => WeeklyScheduleReadOnlySlot(
            timeText: formatScheduleRange(s, loc.toString(), timeFmt),
            label: s.label?.trim(),
            scheme: scheme,
            tt: tt,
          ),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [header, list],
        );
      },
    );
  }
}

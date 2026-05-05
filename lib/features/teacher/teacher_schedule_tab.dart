import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_upcoming_slot.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../class_schedule/schedule_time_format.dart';
import '../class_schedule/weekly_schedule_timeline.dart';
import 'teacher_chat_ui.dart';

class TeacherScheduleTab extends ConsumerWidget {
  const TeacherScheduleTab({super.key, required this.l10n, required this.scheme});

  final AppLocalizations l10n;
  final ColorScheme scheme;

  static String _dayHeading(
    AppLocalizations l10n,
    String locale,
    DateTime slotDay,
    DateTime now,
  ) {
    final t0 = DateTime(now.year, now.month, now.day);
    final t1 = DateTime(slotDay.year, slotDay.month, slotDay.day);
    final diff = t1.difference(t0).inDays;
    if (diff == 0) return l10n.sessionDayToday;
    if (diff == 1) return l10n.sessionDayTomorrow;
    return DateFormat.EEEE(locale).format(slotDay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.jm(loc);
    final async = ref.watch(teacherWeekUpcomingProvider);
    final now = DateTime.now();

    return DecoratedBox(
      decoration: TeacherChatUi.teacherPanelBackground(scheme),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userFriendlyErrorMessage(err, l10n),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(teacherWeekUpcomingProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          return RefreshIndicator(
            color: scheme.primary,
            onRefresh: () async {
              await refreshAllRemoteApiData(ref);
              ref.invalidate(teacherWeekUpcomingProvider);
              try {
                await ref.read(teacherWeekUpcomingProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 72,
                            color: scheme.primary.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.teacherScheduleEmpty,
                            textAlign: TextAlign.center,
                            style: tt.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _TeacherScheduleTimeline(
                        items: items,
                        nearestOccurrence:
                            items.isNotEmpty ? items.first : null,
                        scheme: scheme,
                        tt: tt,
                        l10n: l10n,
                        loc: loc,
                        timeFmt: timeFmt,
                        now: now,
                        onOpenStudent: (id) =>
                            context.push('/teacher/student/$id'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherScheduleTimeline extends StatelessWidget {
  const _TeacherScheduleTimeline({
    required this.items,
    required this.nearestOccurrence,
    required this.scheme,
    required this.tt,
    required this.l10n,
    required this.loc,
    required this.timeFmt,
    required this.now,
    required this.onOpenStudent,
  });

  final List<TeacherUpcomingSlotItem> items;
  final TeacherUpcomingSlotItem? nearestOccurrence;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final String loc;
  final DateFormat timeFmt;
  final DateTime now;
  final void Function(int studentId) onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final lineColor = Color.lerp(
      scheme.outlineVariant,
      scheme.primary,
      0.35,
    )!;
    final groups = <DateTime, List<TeacherUpcomingSlotItem>>{};
    for (final i in items) {
      final k = DateTime(
        i.startLocal.year,
        i.startLocal.month,
        i.startLocal.day,
      );
      groups.putIfAbsent(k, () => []).add(i);
    }
    final orderedDays = groups.keys.toList()..sort();
    final children = <Widget>[const SizedBox(height: 18)];

    for (var di = 0; di < orderedDays.length; di++) {
      final dayKey = orderedDays[di];
      final group = groups[dayKey]!;
      final isFirstDay = di == 0;
      final isLastDay = di == orderedDays.length - 1;

      children.add(
        ScheduleTimelineDayHeader(
          weekdayText: TeacherScheduleTab._dayHeading(
            l10n,
            loc,
            group.first.startLocal,
            now,
          ),
          scheme: scheme,
          tt: tt,
          lineColor: lineColor,
          bridgeLineFromAbove: !isFirstDay,
          hasSlotsBelow: group.isNotEmpty,
        ),
      );

      for (var si = 0; si < group.length; si++) {
        final item = group[si];
        final isFirstSlot = si == 0;
        final isLastSlot = si == group.length - 1;
        final extendTop = isFirstSlot
            ? kScheduleTimelineFirstSlotLineUp
            : kScheduleTimelineSlotGap / 2;
        final extendBottom = isLastSlot && isLastDay
            ? 0.0
            : isLastSlot && !isLastDay
                ? kScheduleTimelineLastSlotToNextDay
                : kScheduleTimelineSlotGap / 2;
        final isNearest = _isSameOccurrence(item, nearestOccurrence);

        children.add(
          Padding(
            padding: EdgeInsets.only(
              bottom: isLastSlot && isLastDay ? 0 : kScheduleTimelineSlotGap,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScheduleTimelineSlotRail(
                    lineColor: lineColor,
                    scheme: scheme,
                    extendTop: extendTop,
                    extendBottom: extendBottom,
                    emphasizeDot: isNearest,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: isNearest
                          ? scheme.primaryContainer.withValues(alpha: 0.72)
                          : scheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isNearest
                              ? scheme.primary.withValues(alpha: 0.55)
                              : scheme.outlineVariant.withValues(alpha: 0.5),
                          width: isNearest ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => onOpenStudent(item.studentId),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileAvatar(
                                avatarId: item.avatarId,
                                userId: item.studentId,
                                size: 52,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.studentDisplayLabel,
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isNearest
                                            ? scheme.onPrimaryContainer
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatScheduleRange(
                                        item.slot,
                                        loc,
                                        timeFmt,
                                      ),
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    if (item.slot.label != null &&
                                        item.slot.label!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.slot.label!.trim(),
                                        style: tt.bodySmall?.copyWith(
                                          color: isNearest
                                              ? scheme.onPrimaryContainer
                                                  .withValues(alpha: 0.85)
                                              : scheme.onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      item.studentEmail,
                                      style: tt.bodySmall?.copyWith(
                                        color: isNearest
                                            ? scheme.onPrimaryContainer
                                                .withValues(alpha: 0.8)
                                            : scheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isNearest
                                    ? scheme.onPrimaryContainer
                                        .withValues(alpha: 0.75)
                                    : scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  static bool _isSameOccurrence(
    TeacherUpcomingSlotItem item,
    TeacherUpcomingSlotItem? ref,
  ) {
    if (ref == null) return false;
    return item.studentId == ref.studentId &&
        item.slot.id == ref.slot.id &&
        item.startLocal.millisecondsSinceEpoch ==
            ref.startLocal.millisecondsSinceEpoch;
  }
}

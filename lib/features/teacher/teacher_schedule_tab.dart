import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/schedule_attendance.dart';
import '../../data/models/teacher_student.dart';
import '../../data/models/teacher_upcoming_slot.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../class_schedule/schedule_time_format.dart';
import '../class_schedule/weekly_schedule_timeline.dart';
import 'teacher_chat_ui.dart';

final _scheduleAttendanceModeOverridesProvider =
    StateProvider<Map<int, ScheduleAttendanceMode>>((ref) => const {});

class TeacherScheduleTab extends ConsumerWidget {
  const TeacherScheduleTab({
    super.key,
    required this.l10n,
    required this.scheme,
  });

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

  Future<void> _openTemporaryClassSheet(
    BuildContext context,
    WidgetRef ref, {
    TeacherUpcomingSlotItem? existing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final students = await ref.read(teacherStudentsProvider.future);
      if (!context.mounted) return;
      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherTemporaryClassNoStudents)),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) =>
            _TemporaryClassEditorSheet(students: students, existing: existing),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    }
  }

  Future<void> _deleteTemporaryClass(
    BuildContext context,
    WidgetRef ref,
    TeacherUpcomingSlotItem item,
  ) async {
    final slotId = item.temporarySlotId;
    if (slotId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.teacherTemporaryClassDeleteConfirmTitle),
        content: Text(l10n.teacherTemporaryClassDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.classScheduleRemove),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(apiServiceProvider)
          .deleteTeacherTemporaryScheduleSlot(slotId: slotId);
      ref.invalidate(teacherTemporaryScheduleProvider);
      ref.invalidate(teacherWeekUpcomingProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherTemporaryClassDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    }
  }

  Future<void> _setStudentAttendanceMode(
    BuildContext context,
    WidgetRef ref,
    int studentId,
    ScheduleAttendanceMode mode,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final previous = ref.read(_scheduleAttendanceModeOverridesProvider);
    ref.read(_scheduleAttendanceModeOverridesProvider.notifier).state = {
      ...previous,
      studentId: mode,
    };
    try {
      await ref
          .read(apiServiceProvider)
          .setTeacherScheduleAttendanceMode(studentId: studentId, mode: mode);
      ref.invalidate(teacherWeekUpcomingProvider);
      ref.invalidate(teacherStudentsProvider);
    } catch (e) {
      ref.read(_scheduleAttendanceModeOverridesProvider.notifier).state =
          previous;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    }
  }

  Future<void> _resolvePendingOccurrence(
    BuildContext context,
    WidgetRef ref,
    TeacherUpcomingSlotItem item,
    bool didHappen,
  ) async {
    final id = item.attendanceOccurrenceId;
    if (id == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(apiServiceProvider)
          .resolveTeacherSchedulePendingOccurrence(
            occurrenceId: id,
            didHappen: didHappen,
          );
      ref.invalidate(teacherWeekUpcomingProvider);
      ref.invalidate(teacherStudentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            didHappen
                ? l10n.teacherClassSessionAdded
                : l10n.teacherScheduleClassSkipped,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.jm(loc);
    final async = ref.watch(teacherWeekUpcomingProvider);
    final modeOverrides = ref.watch(_scheduleAttendanceModeOverridesProvider);
    final now = DateTime.now();

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
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
                        onPressed: () =>
                            ref.invalidate(teacherWeekUpcomingProvider),
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
                  child: _ScheduleStartAutoRefresh(
                    items: items,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (items.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                32,
                                32,
                                120,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 72,
                                    color: scheme.primary.withValues(
                                      alpha: 0.45,
                                    ),
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
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                            sliver: SliverToBoxAdapter(
                              child: _TeacherScheduleTimeline(
                                items: items,
                                nearestOccurrence: items.isNotEmpty
                                    ? items.first
                                    : null,
                                scheme: scheme,
                                tt: tt,
                                l10n: l10n,
                                loc: loc,
                                timeFmt: timeFmt,
                                now: now,
                                modeOverrides: modeOverrides,
                                onOpenStudent: (id) =>
                                    context.push('/teacher/student/$id'),
                                onDeleteTemporary: (item) =>
                                    _deleteTemporaryClass(context, ref, item),
                                onEditTemporary: (item) =>
                                    _openTemporaryClassSheet(
                                      context,
                                      ref,
                                      existing: item,
                                    ),
                                onSetAttendanceMode: (studentId, mode) =>
                                    _setStudentAttendanceMode(
                                      context,
                                      ref,
                                      studentId,
                                      mode,
                                    ),
                                onResolvePending: (item, didHappen) =>
                                    _resolvePendingOccurrence(
                                      context,
                                      ref,
                                      item,
                                      didHappen,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        PositionedDirectional(
          end: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: FloatingActionButton.extended(
            heroTag: 'teacher_temporary_class_fab',
            onPressed: () => _openTemporaryClassSheet(context, ref),
            backgroundColor: const Color(0xFF00A884),
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.teacherTemporaryClassBadge,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleStartAutoRefresh extends ConsumerStatefulWidget {
  const _ScheduleStartAutoRefresh({required this.items, required this.child});

  final List<TeacherUpcomingSlotItem> items;
  final Widget child;

  @override
  ConsumerState<_ScheduleStartAutoRefresh> createState() =>
      _ScheduleStartAutoRefreshState();
}

class _ScheduleStartAutoRefreshState
    extends ConsumerState<_ScheduleStartAutoRefresh> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _ScheduleStartAutoRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    DateTime? nextStart;
    for (final item in widget.items) {
      if (!item.startLocal.isAfter(now)) continue;
      if (nextStart == null || item.startLocal.isBefore(nextStart)) {
        nextStart = item.startLocal;
      }
    }
    if (nextStart == null) return;

    final delay = nextStart.difference(now) + const Duration(seconds: 1);
    _timer = Timer(delay.isNegative ? const Duration(seconds: 1) : delay, () {
      if (!mounted) return;
      ref.invalidate(teacherWeekUpcomingProvider);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
    required this.modeOverrides,
    required this.onOpenStudent,
    required this.onDeleteTemporary,
    required this.onEditTemporary,
    required this.onSetAttendanceMode,
    required this.onResolvePending,
  });

  final List<TeacherUpcomingSlotItem> items;
  final TeacherUpcomingSlotItem? nearestOccurrence;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final String loc;
  final DateFormat timeFmt;
  final DateTime now;
  final Map<int, ScheduleAttendanceMode> modeOverrides;
  final void Function(int studentId) onOpenStudent;
  final void Function(TeacherUpcomingSlotItem item) onDeleteTemporary;
  final void Function(TeacherUpcomingSlotItem item) onEditTemporary;
  final void Function(int studentId, ScheduleAttendanceMode mode)
  onSetAttendanceMode;
  final void Function(TeacherUpcomingSlotItem item, bool didHappen)
  onResolvePending;

  @override
  Widget build(BuildContext context) {
    final lineColor = Color.lerp(scheme.outlineVariant, scheme.primary, 0.35)!;
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
        final attendanceMode =
            modeOverrides[item.studentId] ?? item.attendanceMode;
        final extendTop = isFirstSlot
            ? kScheduleTimelineFirstSlotLineUp
            : kScheduleTimelineSlotGap / 2;
        final extendBottom = isLastSlot && isLastDay
            ? 0.0
            : isLastSlot && !isLastDay
            ? kScheduleTimelineLastSlotToNextDay
            : kScheduleTimelineSlotGap / 2;
        final isNearest = _isSameOccurrence(item, nearestOccurrence);
        final pendingBackground = scheme.brightness == Brightness.dark
            ? const Color(0xFF4A2028)
            : const Color(0xFFFFE7EA);
        final pendingBorder = scheme.brightness == Brightness.dark
            ? const Color(0xFFD87A88)
            : const Color(0xFFFF9AA8);
        final pendingForeground = scheme.brightness == Brightness.dark
            ? const Color(0xFFFFD9DE)
            : const Color(0xFF7B1722);

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
                      color: item.isManualPending
                          ? pendingBackground
                          : isNearest
                          ? scheme.primaryContainer.withValues(alpha: 0.72)
                          : scheme.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: item.isManualPending
                              ? pendingBorder.withValues(alpha: 0.8)
                              : isNearest
                              ? scheme.primary.withValues(alpha: 0.55)
                              : scheme.outlineVariant.withValues(alpha: 0.5),
                          width: isNearest || item.isManualPending ? 1.5 : 1,
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
                                    if (item.isTemporary) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: scheme.tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            child: Text(
                                              l10n.teacherTemporaryClassBadge,
                                              style: tt.labelSmall?.copyWith(
                                                color:
                                                    scheme.onTertiaryContainer,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                    const SizedBox(height: 12),
                                    _AttendanceModeToggle(
                                      value: attendanceMode,
                                      l10n: l10n,
                                      onChanged: (mode) => onSetAttendanceMode(
                                        item.studentId,
                                        mode,
                                      ),
                                    ),
                                    if (item.isManualPending) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.teacherScheduleDidClassHappen,
                                        style: tt.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: pendingForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          SizedBox(
                                            width: 92,
                                            height: 38,
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                textStyle: tt.labelLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              onPressed: () =>
                                                  onResolvePending(item, true),
                                              icon: const Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                              ),
                                              label: Text(
                                                l10n.teacherScheduleYes,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 92,
                                            height: 38,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                foregroundColor: scheme.primary,
                                                side: BorderSide(
                                                  color: scheme.primary
                                                      .withValues(alpha: 0.55),
                                                ),
                                                textStyle: tt.labelLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              onPressed: () =>
                                                  onResolvePending(item, false),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                              ),
                                              label: Text(
                                                l10n.teacherScheduleNo,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.isManualPending)
                                const SizedBox.shrink()
                              else if (item.isTemporary)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: l10n.teacherClassSessionEdit,
                                      onPressed: () => onEditTemporary(item),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.classScheduleRemove,
                                      onPressed: () => onDeleteTemporary(item),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: scheme.error,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isNearest
                                      ? scheme.onPrimaryContainer.withValues(
                                          alpha: 0.75,
                                        )
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
        item.isTemporary == ref.isTemporary &&
        item.slot.id == ref.slot.id &&
        item.startLocal.millisecondsSinceEpoch ==
            ref.startLocal.millisecondsSinceEpoch;
  }
}

class _AttendanceModeToggle extends StatelessWidget {
  const _AttendanceModeToggle({
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  final ScheduleAttendanceMode value;
  final AppLocalizations l10n;
  final ValueChanged<ScheduleAttendanceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              _AttendanceModeToggleSegment(
                label: l10n.teacherScheduleModeAuto,
                selected: value == ScheduleAttendanceMode.auto,
                onTap: () => onChanged(ScheduleAttendanceMode.auto),
              ),
              const SizedBox(width: 3),
              _AttendanceModeToggleSegment(
                label: l10n.teacherScheduleModeManual,
                selected: value == ScheduleAttendanceMode.manual,
                onTap: () => onChanged(ScheduleAttendanceMode.manual),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceModeToggleSegment extends StatelessWidget {
  const _AttendanceModeToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('selected'),
                          size: 16,
                          color: foreground,
                        )
                      : const SizedBox(
                          key: ValueKey('unselected'),
                          width: 16,
                          height: 16,
                        ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemporaryClassEditorSheet extends ConsumerStatefulWidget {
  const _TemporaryClassEditorSheet({required this.students, this.existing});

  final List<TeacherStudentSummary> students;
  final TeacherUpcomingSlotItem? existing;

  @override
  ConsumerState<_TemporaryClassEditorSheet> createState() =>
      _TemporaryClassEditorSheetState();
}

class _TemporaryClassEditorSheetState
    extends ConsumerState<_TemporaryClassEditorSheet> {
  late int _studentId;
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _labelCtrl;
  var _saving = false;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final existing = widget.existing;
    final existingStudentIsAvailable =
        existing != null &&
        widget.students.any((s) => s.id == existing.studentId);
    _studentId = existingStudentIsAvailable
        ? existing.studentId
        : widget.students.first.id;
    final initialStart = existing?.startLocal ?? now;
    _date = DateTime(initialStart.year, initialStart.month, initialStart.day);
    _time = TimeOfDay(hour: initialStart.hour, minute: initialStart.minute);
    _labelCtrl = TextEditingController(text: existing?.slot.label ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  DateTime get _startAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      final label = _labelCtrl.text.trim().isEmpty
          ? null
          : _labelCtrl.text.trim();
      final existingSlotId = widget.existing?.temporarySlotId;
      if (_isEditing && existingSlotId != null) {
        await ref
            .read(apiServiceProvider)
            .updateTeacherTemporaryScheduleSlot(
              slotId: existingSlotId,
              studentId: _studentId,
              startAt: _startAt,
              label: label,
            );
      } else {
        await ref
            .read(apiServiceProvider)
            .addTeacherTemporaryScheduleSlot(
              studentId: _studentId,
              startAt: _startAt,
              label: label,
            );
      }
      ref.invalidate(teacherTemporaryScheduleProvider);
      ref.invalidate(teacherWeekUpcomingProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? l10n.teacherTemporaryClassUpdated
                : l10n.teacherTemporaryClassSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final dateText = DateFormat.yMMMd(loc).format(_date);
    final timeText = DateFormat.jm(loc).format(_startAt);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + inset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherTemporaryClassTitle,
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _studentId,
              decoration: InputDecoration(
                labelText: l10n.teacherTemporaryClassStudentLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final s in widget.students)
                  DropdownMenuItem(value: s.id, child: Text(s.displayLabel)),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _studentId = v);
                    },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_rounded, color: scheme.primary),
              title: Text(l10n.teacherClassSessionDateFieldLabel),
              subtitle: Text(dateText),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickDate,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule_rounded, color: scheme.primary),
              title: Text(l10n.teacherClassSessionTimeFieldLabel),
              subtitle: Text(timeText),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickTime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.classScheduleLabelHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(l10n),
              icon: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Icon(_isEditing ? Icons.edit_rounded : Icons.add_rounded),
              label: Text(
                _isEditing
                    ? l10n.teacherClassSessionEdit
                    : l10n.teacherTemporaryClassAddButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/models/class_schedule_slot.dart';
import '../you/you_jelly_style.dart';
import 'schedule_time_format.dart';

const double _kTimelineGutter = 26;
const double _kTimelineX = 12;

/// Shared with [TeacherScheduleTab] timeline rows.
const double kScheduleTimelineSlotGap = 10;
const double kScheduleTimelineFirstSlotLineUp = 14;
const double kScheduleTimelineLastSlotToNextDay = 32;

/// Vertical timeline + day headers; [buildSlot] renders each time row (read-only
/// or teacher actions).
class WeeklyScheduleTimelineList extends StatelessWidget {
  const WeeklyScheduleTimelineList({
    super.key,
    required this.daysWithClass,
    required this.byDay,
    required this.scheme,
    required this.tt,
    required this.buildSlot,
  });

  final List<int> daysWithClass;
  final Map<int, List<ClassScheduleSlot>> byDay;
  final ColorScheme scheme;
  final TextTheme tt;
  final Widget Function(ClassScheduleSlot slot) buildSlot;

  @override
  Widget build(BuildContext context) {
    final lineColor = Color.lerp(
      scheme.outlineVariant,
      scheme.primary,
      0.35,
    )!;
    final children = <Widget>[const SizedBox(height: 18)];

    for (var di = 0; di < daysWithClass.length; di++) {
      final w = daysWithClass[di];
      final slots = byDay[w]!;
      final isFirstDay = di == 0;
      final isLastDay = di == daysWithClass.length - 1;

      children.add(
        ScheduleTimelineDayHeader(
          weekdayText: weekdayTitle(context, w),
          scheme: scheme,
          tt: tt,
          lineColor: lineColor,
          bridgeLineFromAbove: !isFirstDay,
          hasSlotsBelow: slots.isNotEmpty,
        ),
      );

      for (var si = 0; si < slots.length; si++) {
        final s = slots[si];
        final isFirstSlot = si == 0;
        final isLastSlot = si == slots.length - 1;
        final extendTop = isFirstSlot
            ? kScheduleTimelineFirstSlotLineUp
            : kScheduleTimelineSlotGap / 2;
        final extendBottom = isLastSlot && isLastDay
            ? 0.0
            : isLastSlot && !isLastDay
                ? kScheduleTimelineLastSlotToNextDay
                : kScheduleTimelineSlotGap / 2;

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
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: buildSlot(s)),
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
}

/// Day title + large dot on the vertical line (weekly / teacher schedule).
class ScheduleTimelineDayHeader extends StatelessWidget {
  const ScheduleTimelineDayHeader({
    super.key,
    required this.weekdayText,
    required this.scheme,
    required this.tt,
    required this.lineColor,
    required this.bridgeLineFromAbove,
    required this.hasSlotsBelow,
  });

  final String weekdayText;
  final ColorScheme scheme;
  final TextTheme tt;
  final Color lineColor;
  final bool bridgeLineFromAbove;
  final bool hasSlotsBelow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _kTimelineGutter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: _kTimelineX,
                    top: bridgeLineFromAbove
                        ? -kScheduleTimelineSlotGap / 2
                        : 0,
                    bottom: hasSlotsBelow ? -kScheduleTimelineSlotGap / 2 : 0,
                    child: Container(
                      width: 2,
                      color: lineColor.withValues(alpha: 0.9),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary,
                        border: Border.all(
                          color: scheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.22),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  weekdayText,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small dot + vertical connector for one timed row.
class ScheduleTimelineSlotRail extends StatelessWidget {
  const ScheduleTimelineSlotRail({
    super.key,
    required this.lineColor,
    required this.scheme,
    required this.extendTop,
    required this.extendBottom,
    this.emphasizeDot = false,
  });

  final Color lineColor;
  final ColorScheme scheme;
  final double extendTop;
  final double extendBottom;
  final bool emphasizeDot;

  @override
  Widget build(BuildContext context) {
    final d = emphasizeDot ? 12.0 : 10.0;
    return SizedBox(
      width: _kTimelineGutter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: _kTimelineX,
            top: -extendTop,
            bottom: -extendBottom,
            child: Container(
              width: 2,
              color: lineColor.withValues(
                alpha: emphasizeDot ? 0.95 : 0.85,
              ),
            ),
          ),
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emphasizeDot ? scheme.primary : scheme.surface,
              border: emphasizeDot
                  ? null
                  : Border.all(
                      color: scheme.primary,
                      width: 2,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only weekly slot card (learner view); same surface + border as app cards.
class WeeklyScheduleReadOnlySlot extends StatelessWidget {
  const WeeklyScheduleReadOnlySlot({
    super.key,
    required this.timeText,
    this.label,
    required this.scheme,
    required this.tt,
  });

  final String timeText;
  final String? label;
  final ColorScheme scheme;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final lab = label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: youJellyCardDecoration(context, scheme: scheme),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          YouJellyIconBubble(
            color: scheme.secondary,
            size: 44,
            child: Icon(
              Icons.schedule_rounded,
              size: 22,
              color: scheme.onSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeText,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lab != null && lab.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lab,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

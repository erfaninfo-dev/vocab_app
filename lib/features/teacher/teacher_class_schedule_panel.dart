import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/class_schedule_slot.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../class_schedule/schedule_time_format.dart';
import '../class_schedule/weekly_schedule_timeline.dart';

class TeacherClassSchedulePanel extends ConsumerStatefulWidget {
  const TeacherClassSchedulePanel({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<TeacherClassSchedulePanel> createState() =>
      _TeacherClassSchedulePanelState();
}

class _TeacherClassSchedulePanelState
    extends ConsumerState<TeacherClassSchedulePanel> {
  var _adding = false;
  final Set<int> _busyIds = {};

  Future<void> _invalidate() async {
    ref.invalidate(teacherStudentScheduleProvider(widget.studentId));
    ref.invalidate(teacherWeekUpcomingProvider);
  }

  Future<void> _openEditor({ClassScheduleSlot? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ScheduleSlotEditorSheet(
        studentId: widget.studentId,
        existing: existing,
        onDone: (msg) async {
          await _invalidate();
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      ),
    );
  }

  Future<void> _delete(ClassScheduleSlot slot, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.classScheduleDeleteConfirmTitle),
          content: Text(l10n.classScheduleDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: s.error,
                foregroundColor: s.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.classScheduleRemove),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busyIds.add(slot.id));
    try {
      await ref.read(apiServiceProvider).deleteTeacherScheduleSlot(
            studentId: widget.studentId,
            slotId: slot.id,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.classScheduleSlotDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(slot.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final localeObj = Localizations.localeOf(context);
    final loc = localeObj.toString();
    final timeFmt = DateFormat.jm(loc);
    final async = ref.watch(teacherStudentScheduleProvider(widget.studentId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFriendlyErrorMessage(e, l10n),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (slots) {
        final byDay = <int, List<ClassScheduleSlot>>{};
        for (var w = 1; w <= 7; w++) {
          byDay[w] = [];
        }
        for (final s in slots) {
          final k = s.weekday.clamp(1, 7);
          byDay[k]!.add(s);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              width: double.infinity,
              decoration: appJellyCardDecoration(context, scheme: scheme),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppJellyIconBubble(
                          color: scheme.secondary,
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: scheme.onSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l10n.teacherTabWeeklySchedule,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AppJellyCountBadge(
                          label: '${slots.length}',
                          tone: AppJellyBadgeTone.primary,
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.teacherClassScheduleSubtitle,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _adding
                        ? null
                        : () async {
                            setState(() => _adding = true);
                            try {
                              await _openEditor();
                            } finally {
                              if (mounted) setState(() => _adding = false);
                            }
                          },
                    icon: _adding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.secondary,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(l10n.teacherClassScheduleAddButton),
                  ),
                ],
              ),
            ),
            ),
            if (slots.isEmpty) ...[
              const SizedBox(height: 32),
              Icon(
                Icons.event_repeat_rounded,
                size: 56,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.classScheduleEmpty,
                textAlign: TextAlign.center,
                style: tt.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              WeeklyScheduleTimelineList(
                daysWithClass: weekdayDisplayOrder(localeObj)
                    .where((w) => byDay[w]!.isNotEmpty)
                    .toList(),
                byDay: byDay,
                scheme: scheme,
                tt: tt,
                buildSlot: (s) => _ScheduleTile(
                  slot: s,
                  timeLabel: formatScheduleRange(s, loc, timeFmt),
                  scheme: scheme,
                  tt: tt,
                  l10n: l10n,
                  busy: _busyIds.contains(s.id),
                  onEdit: _busyIds.contains(s.id)
                      ? null
                      : () => _openEditor(existing: s),
                  onDelete: _busyIds.contains(s.id)
                      ? null
                      : () => _delete(s, l10n),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.slot,
    required this.timeLabel,
    required this.scheme,
    required this.tt,
    required this.l10n,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassScheduleSlot slot;
  final String timeLabel;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final label = slot.label?.trim();
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    scheme.secondaryContainer.withValues(alpha: 0.95),
                foregroundColor: scheme.onSecondaryContainer,
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.secondary,
                        ),
                      )
                    : const Icon(Icons.schedule_rounded, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeLabel,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (label != null && label.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.teacherClassSessionEdit,
                onPressed: busy ? null : onEdit,
                icon: Icon(Icons.edit_outlined, color: scheme.primary),
              ),
              IconButton(
                tooltip: l10n.classScheduleRemove,
                onPressed: busy ? null : onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleSlotEditorSheet extends ConsumerStatefulWidget {
  const _ScheduleSlotEditorSheet({
    required this.studentId,
    this.existing,
    required this.onDone,
  });

  final int studentId;
  final ClassScheduleSlot? existing;
  final Future<void> Function(String message) onDone;

  @override
  ConsumerState<_ScheduleSlotEditorSheet> createState() =>
      _ScheduleSlotEditorSheetState();
}

class _ScheduleSlotEditorSheetState extends ConsumerState<_ScheduleSlotEditorSheet> {
  late int _weekday;
  late TimeOfDay _start;
  late TimeOfDay _end;
  var _hasEnd = false;
  late final TextEditingController _labelCtrl;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _weekday = ex.weekday.clamp(1, 7);
      _start = parseScheduleHm(ex.startTime) ?? TimeOfDay.now();
      final e = ex.endTime;
      if (e != null && e.isNotEmpty) {
        _end = parseScheduleHm(e) ?? _start;
        _hasEnd = true;
      } else {
        _end = TimeOfDay(
          hour: (_start.hour + 1) % 24,
          minute: _start.minute,
        );
        _hasEnd = false;
      }
      _labelCtrl = TextEditingController(text: ex.label ?? '');
    } else {
      _weekday = DateTime.now().weekday;
      _start = TimeOfDay.now();
      _end = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: TimeOfDay.now().minute,
      );
      _hasEnd = false;
      _labelCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _start,
    );
    if (t == null || !mounted) return;
    setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _end,
    );
    if (t == null || !mounted) return;
    setState(() => _end = t);
  }

  bool _rangeOk(AppLocalizations l10n) {
    if (!_hasEnd) return true;
    final a = timeOfDayToMinutes(_start);
    final b = timeOfDayToMinutes(_end);
    if (b <= a) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classScheduleInvalidRange)),
      );
      return false;
    }
    return true;
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_rangeOk(l10n)) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final lab = _labelCtrl.text.trim();
      final endHm = _hasEnd ? scheduleHm(_end) : null;
      if (widget.existing != null) {
        await api.updateTeacherScheduleSlot(
          studentId: widget.studentId,
          slotId: widget.existing!.id,
          weekday: _weekday,
          startTimeHm: scheduleHm(_start),
          endTimeHm: endHm,
          label: lab.isEmpty ? null : lab,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        await widget.onDone(l10n.classScheduleSlotUpdated);
      } else {
        await api.addTeacherScheduleSlot(
          studentId: widget.studentId,
          weekday: _weekday,
          startTimeHm: scheduleHm(_start),
          endTimeHm: endHm,
          label: lab.isEmpty ? null : lab,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        await widget.onDone(l10n.classScheduleSlotAdded);
      }
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
    final pad = MediaQuery.paddingOf(context).bottom;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: pad + inset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing != null
                  ? l10n.teacherClassScheduleEditTitle
                  : l10n.teacherClassScheduleAddButton,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _weekday,
              decoration: InputDecoration(
                labelText: l10n.classScheduleWeekdayLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (var w = 1; w <= 7; w++)
                  DropdownMenuItem(
                    value: w,
                    child: Text(weekdayTitle(context, w)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _weekday = v);
                    },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule_rounded, color: scheme.primary),
              title: Text(l10n.classScheduleStartLabel),
              subtitle: Text(scheduleHm(_start)),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickStart,
            ),
            SwitchListTile(
              value: _hasEnd,
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                        _hasEnd = v;
                      }),
              title: Text(l10n.classScheduleIncludeEnd),
              subtitle: Text(
                l10n.classScheduleHasEndSubtitle,
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (_hasEnd)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.schedule_outlined, color: scheme.primary),
                title: Text(l10n.classScheduleEndLabel),
                subtitle: Text(scheduleHm(_end)),
                trailing: const Icon(Icons.chevron_right_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                onTap: _saving ? null : _pickEnd,
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelCtrl,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.classScheduleLabelHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onInverseSurface,
                      ),
                    )
                  : Text(l10n.teacherSessionSave),
            ),
          ],
        ),
      ),
    );
  }
}

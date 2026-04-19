import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

DateTime? _parseSessionLocal(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized)?.toLocal();
}

List<MapEntry<DateTime, List<ClassSessionEntry>>> _groupByDay(
  List<ClassSessionEntry> sessions,
) {
  final map = <DateTime, List<ClassSessionEntry>>{};
  final unparsed = <ClassSessionEntry>[];
  for (final s in sessions) {
    final dt = _parseSessionLocal(s.recordedAtRaw);
    if (dt == null) {
      unparsed.add(s);
      continue;
    }
    final day = DateTime(dt.year, dt.month, dt.day);
    map.putIfAbsent(day, () => []).add(s);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      final da = _parseSessionLocal(a.recordedAtRaw);
      final db = _parseSessionLocal(b.recordedAtRaw);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
  }
  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  final out = keys.map((k) => MapEntry(k, map[k]!)).toList();
  if (unparsed.isNotEmpty) {
    out.add(MapEntry(DateTime(1970), unparsed));
  }
  return out;
}

class TeacherClassSessionsPanel extends ConsumerStatefulWidget {
  const TeacherClassSessionsPanel({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<TeacherClassSessionsPanel> createState() =>
      _TeacherClassSessionsPanelState();
}

class _TeacherClassSessionsPanelState
    extends ConsumerState<TeacherClassSessionsPanel> {
  var _adding = false;
  final Set<int> _busyIds = {};

  Future<void> _invalidate() async {
    ref.invalidate(teacherStudentSessionsProvider(widget.studentId));
    ref.invalidate(teacherStudentsProvider);
  }

  Future<void> _add(AppLocalizations l10n) async {
    setState(() => _adding = true);
    try {
      await ref
          .read(apiServiceProvider)
          .addTeacherClassSession(widget.studentId);
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassSessionAdded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _delete(ClassSessionEntry entry, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.teacherClassSessionDeleteConfirmTitle),
          content: Text(l10n.teacherClassSessionDeleteConfirmBody),
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
              child: Text(l10n.teacherClassSessionDelete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busyIds.add(entry.id));
    try {
      await ref
          .read(apiServiceProvider)
          .deleteTeacherClassSession(
            studentId: widget.studentId,
            sessionId: entry.id,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassSessionDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(entry.id));
      }
    }
  }

  Future<void> _edit(
    ClassSessionEntry entry,
    AppLocalizations l10n,
    int displayIndex,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditSessionSheet(
        studentId: widget.studentId,
        entry: entry,
        displayIndex: displayIndex,
        onDone: () async {
          await _invalidate();
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.teacherSessionUpdated)));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final async = ref.watch(teacherStudentSessionsProvider(widget.studentId));

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
      data: (info) {
        final sessions = info.sessions;
        final sortedForIndex = List<ClassSessionEntry>.from(sessions);
        sortedForIndex.sort((a, b) {
          final da = _parseSessionLocal(a.recordedAtRaw);
          final db = _parseSessionLocal(b.recordedAtRaw);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        final displayIndexFor = <int, int>{};
        for (var i = 0; i < sortedForIndex.length; i++) {
          final e = sortedForIndex[i];
          displayIndexFor[e.id] = e.index > 0 ? e.index : i + 1;
        }
        final grouped = _groupByDay(sessions);
        final dayFmt = DateFormat.yMMMMEEEEd(loc);
        final timeFmt = DateFormat.jm(loc);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.35),
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                ),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: scheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.teacherClassSessions,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '${sessions.length}',
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.teacherClassSessionsTabSubtitle,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _adding ? null : () => _add(l10n),
                    icon: _adding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(l10n.teacherClassSessionsAddButton),
                  ),
                ],
              ),
            ),
            if (sessions.isEmpty) ...[
              const SizedBox(height: 32),
              Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.youClassSessionsEmpty,
                textAlign: TextAlign.center,
                style: tt.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.teacherClassSessionsHintEmpty,
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              for (final g in grouped) ...[
                if (g.key.year != 1970) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Text(
                      dayFmt.format(g.key),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Text(
                      '—',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                ...g.value.map((e) {
                  final dt = _parseSessionLocal(e.recordedAtRaw);
                  final idx = displayIndexFor[e.id] ?? 1;
                  final busy = _busyIds.contains(e.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionTile(
                      displayIndex: idx,
                      timeLabel: dt != null
                          ? (g.key.year == 1970
                                ? DateFormat.yMMMd(loc).add_Hm().format(dt)
                                : timeFmt.format(dt))
                          : e.recordedAtRaw,
                      scheme: scheme,
                      tt: tt,
                      l10n: l10n,
                      busy: busy,
                      onEdit: busy ? null : () => _edit(e, l10n, idx),
                      onDelete: busy ? null : () => _delete(e, l10n),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.displayIndex,
    required this.timeLabel,
    required this.scheme,
    required this.tt,
    required this.l10n,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final int displayIndex;
  final String timeLabel;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.9),
                foregroundColor: scheme.onPrimaryContainer,
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : Text(
                        '$displayIndex',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teacherClassSessionHeading(displayIndex),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timeLabel,
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.teacherClassSessionEdit,
                onPressed: busy ? null : onEdit,
                icon: Icon(Icons.edit_outlined, color: scheme.primary),
              ),
              IconButton(
                tooltip: l10n.teacherClassSessionDelete,
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

class _EditSessionSheet extends ConsumerStatefulWidget {
  const _EditSessionSheet({
    required this.studentId,
    required this.entry,
    required this.displayIndex,
    required this.onDone,
  });

  final int studentId;
  final ClassSessionEntry entry;
  final int displayIndex;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<_EditSessionSheet> {
  late DateTime _selected;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selected =
        _parseSessionLocal(widget.entry.recordedAtRaw) ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        d.year,
        d.month,
        d.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (t == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateTeacherClassSessionTime(
            studentId: widget.studentId,
            sessionId: widget.entry.id,
            recordedAt: _selected,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onDone();
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
              l10n.teacherClassSessionEditTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teacherClassSessionHeading(widget.displayIndex),
              style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_month_rounded,
                color: scheme.primary,
              ),
              title: Text(l10n.teacherClassSessionDateFieldLabel),
              subtitle: Text(DateFormat.yMMMMEEEEd(loc).format(_selected)),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickDate,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule_rounded, color: scheme.primary),
              title: Text(l10n.teacherClassSessionTimeFieldLabel),
              subtitle: Text(DateFormat.jm(loc).format(_selected)),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickTime,
            ),
            const SizedBox(height: 20),
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

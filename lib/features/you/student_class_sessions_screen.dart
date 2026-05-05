import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/datetime/class_session_recorded_at.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'student_class_schedule_panel.dart';

List<MapEntry<DateTime, List<ClassSessionEntry>>> _groupByDay(
  List<ClassSessionEntry> sessions,
) {
  final map = <DateTime, List<ClassSessionEntry>>{};
  final unparsed = <ClassSessionEntry>[];
  for (final s in sessions) {
    final dt = parseClassSessionRecordedAtFromApi(s.recordedAtRaw);
    if (dt == null) {
      unparsed.add(s);
      continue;
    }
    final day = DateTime(dt.year, dt.month, dt.day);
    map.putIfAbsent(day, () => []).add(s);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      final da = parseClassSessionRecordedAtFromApi(a.recordedAtRaw);
      final db = parseClassSessionRecordedAtFromApi(b.recordedAtRaw);
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

class StudentClassSessionsScreen extends StatefulWidget {
  const StudentClassSessionsScreen({super.key, this.initialTabIndex = 0});

  /// 0 = class sessions, 1 = weekly schedule.
  final int initialTabIndex;

  @override
  State<StudentClassSessionsScreen> createState() =>
      _StudentClassSessionsScreenState();
}

class _StudentClassSessionsScreenState extends State<StudentClassSessionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scheme.primary.withValues(alpha: 0.08), scheme.surface],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studentPanelTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.teacherTabClassSessions),
            Tab(text: l10n.teacherTabWeeklySchedule),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DecoratedBox(
            decoration: gradient,
            child: const StudentClassSessionsPanel(fullPage: true),
          ),
          DecoratedBox(
            decoration: gradient,
            child: const StudentClassSchedulePanel(),
          ),
        ],
      ),
    );
  }
}

/// Student read-only version of class sessions, matching teacher panel styling.
class StudentClassSessionsPanel extends ConsumerWidget {
  const StudentClassSessionsPanel({
    super.key,
    this.fullPage = false,
    this.onOpenFullPage,
  });

  final bool fullPage;
  final VoidCallback? onOpenFullPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final async = ref.watch(myClassSessionsProvider);

    Widget contentForInfo(TeacherSessionInfo info) {
      final sessions = info.sessions;
      final sessionCount = sessions.length;

      final headerInner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.school_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(l10n.youClassSessionsTitle, style: tt.titleMedium),
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
                    '$sessionCount',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              if (!fullPage && onOpenFullPage != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.youClassSessionsSubtitle,
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      );

      if (!fullPage) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenFullPage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: headerInner,
            ),
          ),
        );
      }

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

      final sortedForIndex = List<ClassSessionEntry>.from(sessions);
      sortedForIndex.sort((a, b) {
        final da = parseClassSessionRecordedAtFromApi(a.recordedAtRaw);
        final db = parseClassSessionRecordedAtFromApi(b.recordedAtRaw);
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

      final list = sessions.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.youClassSessionsEmpty,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
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
                  ],
                  ...g.value.map((e) {
                    final dt = parseClassSessionRecordedAtFromApi(e.recordedAtRaw);
                    final idx = displayIndexFor[e.id] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudentSessionTile(
                        displayIndex: idx,
                        timeLabel: dt != null
                            ? (g.key.year == 1970
                                  ? DateFormat.yMMMd(loc).add_Hm().format(dt)
                                  : timeFmt.format(dt))
                            : e.recordedAtRaw,
                        scheme: scheme,
                        tt: tt,
                        l10n: l10n,
                      ),
                    );
                  }),
                ],
              ],
            );

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [header, list],
      );
    }

    return async.when(
      loading: () => fullPage
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            ),
      error: (e, _) => fullPage
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  userFriendlyErrorMessage(e, l10n),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(Icons.error_outline_rounded, color: scheme.error),
                title: Text(l10n.errorGeneric),
                onTap: () => ref.invalidate(myClassSessionsProvider),
              ),
            ),
      data: contentForInfo,
    );
  }
}

class _StudentSessionTile extends StatelessWidget {
  const _StudentSessionTile({
    required this.displayIndex,
    required this.timeLabel,
    required this.scheme,
    required this.tt,
    required this.l10n,
  });

  final int displayIndex;
  final String timeLabel;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer.withValues(alpha: 0.9),
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(
                '$displayIndex',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherClassSessionHeading(displayIndex),
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

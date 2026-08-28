import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/datetime/class_session_chronological_index.dart';
import '../../core/datetime/class_session_recorded_at.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/widgets/term_payment_status_chip.dart';
import '../../core/widgets/term_title_card.dart';
import '../../data/models/teacher_class_group.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'student_class_schedule_panel.dart';
import 'you_jelly_style.dart';

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

class StudentClassSessionsScreen extends ConsumerStatefulWidget {
  const StudentClassSessionsScreen({
    super.key,
    this.initialTabKey = StudentClassSessionsTabKey.personal,
    this.embedded = false,
  });

  final StudentClassSessionsTabKey initialTabKey;

  /// When true, renders only the inner tab bar and body (for [StudentPanelScreen]).
  final bool embedded;

  @override
  ConsumerState<StudentClassSessionsScreen> createState() =>
      _StudentClassSessionsScreenState();
}

enum StudentClassSessionsTabKey { personal, schedule }

class _StudentClassSessionsScreenState
    extends ConsumerState<StudentClassSessionsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabController(int length, int initialIndex) {
    if (_tabController != null && _tabController!.length == length) {
      return;
    }
    _tabController?.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, length - 1),
    );
  }

  int _initialIndexFor(
    StudentMyClassSessionsResponse data,
    AppLocalizations l10n,
  ) {
    if (widget.initialTabKey == StudentClassSessionsTabKey.schedule) {
      return 1 + data.classGroups.length;
    }
    return 0;
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
    final async = ref.watch(myClassSessionsProvider);

    Widget buildTabs(StudentMyClassSessionsResponse data) {
      final tabCount = 1 + data.classGroups.length + 1;
      final initial = _initialIndexFor(data, l10n);
      _syncTabController(tabCount, initial);
      final controller = _tabController!;

      final tabs = <Widget>[
        Tab(text: l10n.studentPersonalClassTab),
        ...data.classGroups.map((g) => Tab(text: g.name)),
        Tab(text: l10n.teacherTabWeeklySchedule),
      ];

      final views = <Widget>[
        DecoratedBox(
          decoration: gradient,
          child: StudentClassSessionsPanel(
            fullPage: true,
            sessionInfo: data.personal,
            titleText: l10n.studentPersonalClassTab,
            subtitleText: l10n.youClassSessionsSubtitle,
          ),
        ),
        ...data.classGroups.map(
          (g) => DecoratedBox(
            decoration: gradient,
            child: StudentClassSessionsPanel(
              fullPage: true,
              sessionInfo: g.sessionInfo,
              titleText: g.name,
              subtitleText: g.note ?? l10n.studentGroupClassSubtitle,
            ),
          ),
        ),
        DecoratedBox(
          decoration: gradient,
          child: const StudentClassSchedulePanel(),
        ),
      ];

      final tabBar = TabBar(
        controller: controller,
        isScrollable: true,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        tabs: tabs,
      );

      final tabView = TabBarView(controller: controller, children: views);

      if (widget.embedded) {
        return Column(
          children: [
            Material(color: scheme.surface, child: tabBar),
            Expanded(child: tabView),
          ],
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.studentPanelTitle),
          bottom: tabBar,
        ),
        body: tabView,
      );
    }

    return async.when(
      loading: () {
        _syncTabController(2, 0);
        final loadingBody = const Center(child: CircularProgressIndicator());
        if (widget.embedded) {
          return Column(
            children: [
              Material(
                color: scheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(text: l10n.studentPersonalClassTab),
                    Tab(text: l10n.teacherTabWeeklySchedule),
                  ],
                ),
              ),
              Expanded(child: loadingBody),
            ],
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.studentPanelTitle)),
          body: loadingBody,
        );
      },
      error: (e, _) {
        final errBody = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              userFriendlyErrorMessage(e, l10n),
              textAlign: TextAlign.center,
            ),
          ),
        );
        if (widget.embedded) {
          return errBody;
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.studentPanelTitle)),
          body: errBody,
        );
      },
      data: buildTabs,
    );
  }
}

/// Student read-only version of class sessions, matching teacher panel styling.
class StudentClassSessionsPanel extends ConsumerWidget {
  const StudentClassSessionsPanel({
    super.key,
    this.fullPage = false,
    this.onOpenFullPage,
    this.sessionInfo,
    this.titleText,
    this.subtitleText,
  });

  final bool fullPage;
  final VoidCallback? onOpenFullPage;

  /// When set (e.g. personal or one group tab), display this slice only.
  final TeacherSessionInfo? sessionInfo;

  final String? titleText;
  final String? subtitleText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (sessionInfo != null) {
      return _StudentSessionsBody(
        info: sessionInfo!,
        fullPage: fullPage,
        onOpenFullPage: onOpenFullPage,
        titleText: titleText,
        subtitleText: subtitleText,
        scheme: scheme,
        tt: tt,
        l10n: l10n,
      );
    }

    final async = ref.watch(myClassSessionsProvider);

    return async.when(
      loading: () => fullPage
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: 140,
              decoration: youJellyCardDecoration(context, scheme: scheme),
              child: const Center(child: CircularProgressIndicator()),
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
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.invalidate(myClassSessionsProvider),
                borderRadius: BorderRadius.circular(kYouJellyRadius),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: youJellyCardDecoration(context, scheme: scheme),
                  child: Row(
                    children: [
                      YouJellyIconBubble(
                        color: scheme.error,
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: scheme.onError,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.errorGeneric,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      data: (data) {
        final total = data.totalSessionCount;
        final groupHint = data.classGroups.isEmpty
            ? null
            : l10n.studentClassGroupsPreviewHint(data.classGroups.length);
        return _StudentSessionsBody(
          info: data.personal,
          fullPage: fullPage,
          onOpenFullPage: onOpenFullPage,
          titleText: titleText ?? l10n.youClassSessionsTitle,
          subtitleText: subtitleText ??
              (groupHint != null
                  ? '${l10n.youClassSessionsSubtitle}\n$groupHint'
                  : l10n.youClassSessionsSubtitle),
          sessionCountOverride: total,
          scheme: scheme,
          tt: tt,
          l10n: l10n,
        );
      },
    );
  }
}

class _StudentSessionsBody extends StatelessWidget {
  const _StudentSessionsBody({
    required this.info,
    required this.fullPage,
    required this.scheme,
    required this.tt,
    required this.l10n,
    this.onOpenFullPage,
    this.titleText,
    this.subtitleText,
    this.sessionCountOverride,
  });

  final TeacherSessionInfo info;
  final bool fullPage;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final VoidCallback? onOpenFullPage;
  final String? titleText;
  final String? subtitleText;
  final int? sessionCountOverride;

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final sessions = info.sessions;
    final sessionCount = sessionCountOverride ?? sessions.length;
    final title = titleText ?? l10n.youClassSessionsTitle;
    final subtitle = subtitleText ?? l10n.youClassSessionsSubtitle;

    final headerInner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            YouJellyIconBubble(
              color: scheme.primary,
              child: Icon(
                Icons.school_outlined,
                color: scheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            YouJellyCountBadge(
              label: '$sessionCount',
              tone: YouJellyBadgeTone.primary,
            ),
            if (!fullPage && onOpenFullPage != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
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
          borderRadius: BorderRadius.circular(kYouJellyRadius),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: youJellyCardDecoration(context, scheme: scheme),
            child: headerInner,
          ),
        ),
      );
    }

    final header = Container(
      width: double.infinity,
      decoration: youJellyCardDecoration(context, scheme: scheme),
      child: Padding(padding: const EdgeInsets.all(18), child: headerInner),
    );

    final dayFmt = DateFormat.yMMMMEEEEd(loc);
    final timeFmt = DateFormat.jm(loc);

    final Widget list;
    if (sessions.isEmpty) {
      list = Padding(
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
      );
    } else if (info.usesTermsTable && info.terms.isNotEmpty) {
      final termBlocks = <Widget>[const SizedBox(height: 18)];
      for (final term in info.terms) {
        final termSessions =
            sessions.where((s) => s.termId == term.id).toList();
        if (termSessions.isEmpty && term.sessionCount == 0) {
          continue;
        }
        termBlocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TermTitleCard(
                      title: l10n.teacherClassTermTitle(term.sortOrder),
                    ),
                    const SizedBox(width: 8),
                    TermPaymentStatusChip(
                      isPaid: term.isPaid,
                      l10n: l10n,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.teacherClassTermSessionsProgress(
                    term.sessionCount,
                    term.sessionCap,
                  ),
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
        final groupedT = _groupByDay(termSessions);
        for (final g in groupedT) {
          if (g.key.year != 1970) {
            termBlocks.add(
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
            );
          } else {
            termBlocks.add(
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
            );
          }
          for (final e in g.value) {
            final dt = parseClassSessionRecordedAtFromApi(e.recordedAtRaw);
            final idx = classSessionChronologicalIndexInTerm(e, termSessions);
            termBlocks.add(
              Padding(
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
              ),
            );
          }
          termBlocks.add(const SizedBox(height: 8));
        }
      }
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: termBlocks,
      );
    } else {
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
      list = Column(
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
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [header, list],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: youJellyCardDecoration(context, scheme: scheme),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          YouJellyIconBubble(
            color: scheme.primary,
            size: 44,
            child: Text(
              '$displayIndex',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onPrimary,
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
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
          YouJellyIconBubble(
            color: scheme.primary,
            size: 32,
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

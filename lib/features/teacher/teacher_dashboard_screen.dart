import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'messages_updating.dart';
import 'teacher_chat_open_args.dart';
import 'teacher_chat_ui.dart';
import 'teacher_schedule_tab.dart';

/// Tabs exposed by the teacher panel. Stored as an enum so deep links like
/// `/teacher?tab=messages` can preselect the right tab without magic ints.
enum TeacherPanelTab { students, schedule, messages }

/// Unified teacher panel: student roster, week schedule, and a Telegram-style
/// message inbox. Messages tab polls in the background so the
/// unread badge and previews stay fresh without a manual pull-to-refresh.
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({
    super.key,
    this.initialTab = TeacherPanelTab.students,
  });

  /// Which tab to open on first render. Used by deep links (e.g. the legacy
  /// `/teacher/inbox` redirect) so the user lands exactly where they expect.
  final TeacherPanelTab initialTab;

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Messages tab refreshes on this cadence whenever the panel is foregrounded.
  static const _kInboxPollInterval = Duration(seconds: 15);

  late final TabController _tabs;
  Timer? _inboxPollTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (widget.initialTab) {
        TeacherPanelTab.messages => 2,
        TeacherPanelTab.schedule => 1,
        TeacherPanelTab.students => 0,
      },
    )..addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartInboxPoll();
      // If we launched directly into Messages, fetch immediately instead of
      // waiting a full poll interval.
      if (_tabs.index == 2) _refreshInbox();
    });
  }

  @override
  void dispose() {
    _stopInboxPoll();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeStartInboxPoll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopInboxPoll();
    }
  }

  /// Keep the Messages tab polling only while it is actually visible — the
  /// Students tab doesn't need the network traffic.
  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 2) {
      _maybeStartInboxPoll();
      // Trigger one immediate refresh when the user switches onto Messages so
      // they don't wait up to 15 s to see the latest state.
      _refreshInbox();
    } else {
      _stopInboxPoll();
    }
  }

  void _maybeStartInboxPoll() {
    if (_tabs.index != 2) return;
    _inboxPollTimer?.cancel();
    _inboxPollTimer = startMessagesPolling(
      interval: _kInboxPollInterval,
      tick: _refreshInbox,
    );
  }

  void _stopInboxPoll() {
    _inboxPollTimer?.cancel();
    _inboxPollTimer = null;
  }

  Future<void> _refreshInbox() async {
    if (!mounted) return;
    await withMessagesUpdating(ref, () async {
      ref.invalidate(teacherInboxStudentsProvider);
      try {
        await ref.read(teacherInboxStudentsProvider.future);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;
    final updating = ref.watch(messagesUpdatingProvider);
    final tt = Theme.of(context).textTheme;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.teacherPanelTitle),
        ),
        body: Center(child: Text(l10n.signIn)),
      );
    }

    if (!session.user.isTeacher && !session.user.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.teacherPanelTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.teacherAccessDenied,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: scheme.primary.withValues(alpha: 0.12),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.teacherPanelTitle),
            // Surface the live "Updating…" hint right next to the title while
            // the Messages tab is fetching so teachers know data is in motion.
            if (_tabs.index == 2 && updating)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: MessagesUpdatingLabel(
                  active: true,
                  color: scheme.primary,
                  style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: false,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              icon: const Icon(Icons.groups_2_rounded),
              text: l10n.teacherPanelTabStudents,
            ),
            Tab(
              icon: const Icon(Icons.calendar_view_week_rounded),
              text: l10n.teacherPanelTabSchedule,
            ),
            Tab(
              icon: const Icon(Icons.chat_rounded),
              text: l10n.teacherPanelTabMessages,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StudentsTab(l10n: l10n, scheme: scheme),
          TeacherScheduleTab(l10n: l10n, scheme: scheme),
          _MessagesTab(l10n: l10n, scheme: scheme, onRefresh: _refreshInbox),
        ],
      ),
    );
  }
}

/// Roster of students linked to the current teacher. Tapping one drills into
/// their practice detail screen.
class _StudentsTab extends ConsumerWidget {
  const _StudentsTab({required this.l10n, required this.scheme});

  final AppLocalizations l10n;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherStudentsProvider);
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
                  onPressed: () => ref.invalidate(teacherStudentsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (List<TeacherStudentSummary> students) {
          if (students.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.groups_rounded,
                  size: 72,
                  color: scheme.primary.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.teacherStudentsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await refreshAllRemoteApiData(ref);
              await ref.read(teacherStudentsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = students[i];
                return Card(
                  elevation: 2,
                  shadowColor: scheme.primary.withValues(alpha: 0.18),
                  color: scheme.surface.withValues(alpha: 0.96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/teacher/student/${s.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ProfileAvatar(
                            avatarId: s.avatar,
                            userId: s.id,
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.displayLabel,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.email,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${s.sessionCount}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Telegram-style chat list embedded as the second tab of the teacher panel.
/// Tapping a row opens the existing chat thread route so all read/unread and
/// editing behavior stays identical to the standalone inbox screen.
class _MessagesTab extends ConsumerWidget {
  const _MessagesTab({
    required this.l10n,
    required this.scheme,
    required this.onRefresh,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(teacherInboxStudentsProvider);
    final myId = ref.watch(authProvider).valueOrNull?.user.id;
    final localeName = Localizations.localeOf(context).toString();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: TeacherChatUi.inboxListBackgroundDecor(scheme)),
        Positioned.fill(
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
                          ref.invalidate(teacherInboxStudentsProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
            data: (List<TeacherStudentSummary> students) {
              if (students.isEmpty) {
                return RefreshIndicator(
                  color: scheme.primary,
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.mark_chat_unread_rounded,
                        size: 80,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.teacherStudentsEmpty,
                        textAlign: TextAlign.center,
                        style: tt.bodyLarge?.copyWith(
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: scheme.primary,
                onRefresh: () => withMessagesUpdating(ref, () async {
                  await refreshAllRemoteApiData(ref);
                  await ref.read(teacherInboxStudentsProvider.future);
                  await ref.read(teacherMessagesUnreadFabProvider.future);
                }),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final now = DateTime.now();
                    final lastDt = TeacherChatUi.tryParseApiDate(
                      s.lastMessageAt,
                    );
                    final timeStr = lastDt != null
                        ? TeacherChatUi.formatListTimestamp(
                            messageLocal: lastDt,
                            nowLocal: now,
                            l10n: l10n,
                            localeName: localeName,
                          )
                        : null;

                    var preview = '';
                    if (s.lastMessagePreview != null &&
                        s.lastMessagePreview!.trim().isNotEmpty) {
                      if (s.lastMessageFromTeacher == true) {
                        preview =
                            '${l10n.chatPreviewYouPrefix}${s.lastMessagePreview}';
                      } else {
                        preview = s.lastMessagePreview!;
                      }
                    }

                    final hasUnread = s.unreadFromStudent > 0;
                    final isSavedMessages = myId != null && s.id == myId;
                    final title = isSavedMessages
                        ? 'Saved Messages'
                        : s.displayLabel;
                    final openArgs = TeacherChatOpenArgs(
                      displayTitle: title,
                      avatarId: s.avatar,
                      userId: s.id,
                    );

                    return Card(
                      elevation: hasUnread ? 3 : 2,
                      shadowColor: scheme.primary.withValues(
                        alpha: hasUnread ? 0.24 : 0.16,
                      ),
                      color: scheme.surface.withValues(alpha: 0.96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: hasUnread
                              ? scheme.primary.withValues(alpha: 0.42)
                              : scheme.outlineVariant.withValues(alpha: 0.35),
                          width: hasUnread ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          context.push(
                            '/teacher/chat/${s.id}',
                            extra: openArgs,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSavedMessages)
                                CircleAvatar(
                                  radius: 27,
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(
                                    Icons.bookmark_rounded,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                )
                              else
                                ProfileAvatar(
                                  avatarId: s.avatar,
                                  userId: s.id,
                                  size: 54,
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: hasUnread
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (preview.isNotEmpty)
                                      Text(
                                        preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.25,
                                          fontWeight: hasUnread
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      )
                                    else
                                      Text(
                                        s.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (timeStr != null)
                                    Text(
                                      timeStr,
                                      style: tt.labelMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (hasUnread) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s.unreadFromStudent > 99
                                            ? '99+'
                                            : '${s.unreadFromStudent}',
                                        style: TextStyle(
                                          color: scheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

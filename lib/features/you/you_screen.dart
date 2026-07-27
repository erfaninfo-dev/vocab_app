import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/srs/srs_provider.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../l10n/app_localizations.dart';
import 'student_class_sessions_screen.dart';
import 'learning_goal_card.dart';
import 'you_account_section.dart';
import 'you_jelly_style.dart';

List<Widget> _youTeacherMessagesSection({
  required BuildContext context,
  required WidgetRef ref,
  required ColorScheme scheme,
  required AppLocalizations l10n,
  required AsyncValue<TeacherMessagesPreview> previewAsync,
  required bool hasTeacher,
}) {
  return previewAsync.when(
    data: (TeacherMessagesPreview p) {
      final noThreadYet =
          p.peerCount == 0 && p.lastMessage == null && !hasTeacher;
      if (noThreadYet) {
        return [
          _SectionLabel(label: l10n.youSectionMessages),
          const SizedBox(height: 8),
          _YouNoTeacherMessagesCard(scheme: scheme, l10n: l10n),
        ];
      }
      final hub = p.peerCount > 1;
      return [
        _SectionLabel(
          label: hub ? l10n.youSectionMessagesHub : l10n.youSectionMessages,
        ),
        const SizedBox(height: 8),
        _TeacherMessagesPreviewCard(
          preview: p,
          useHubCopy: hub,
          onOpen: () {
            if (p.peerCount > 1) {
              context.push('/you/messages/pick');
            } else {
              final id = p.teacher?.id;
              if (id != null && id > 0) {
                context.push('/you/messages?peer_teacher_id=$id');
              } else {
                context.push('/you/messages');
              }
            }
          },
        ),
      ];
    },
    loading: () => [
      _SectionLabel(label: l10n.youSectionMessages),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: youJellyCardDecoration(context, scheme: scheme),
        child: const Center(child: CircularProgressIndicator()),
      ),
    ],
    error: (_, __) => [
      _SectionLabel(label: l10n.youSectionMessages),
      const SizedBox(height: 8),
      YouJellyShell(
        onTap: () => ref.invalidate(teacherMessagesPreviewProvider),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: youJellyCardSurfaceDecoration(context, scheme: scheme),
        shadows: youJellyCardShadows(context, scheme: scheme),
        child: Row(
          children: [
            YouJellyIconBubble(
              color: scheme.error,
              child: Icon(Icons.error_outline_rounded, color: scheme.onError),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.errorGeneric,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authProvider).valueOrNull;
    final isTeacherPanel =
        session?.user.isTeacher == true || session?.user.isAdmin == true;
    final hasTeacher = session?.user.teacherUserId != null;
    final studentAccess = session?.user.studentAccess == true;
    final previewAsync = ref.watch(teacherMessagesPreviewProvider);
    final showLearnerMessages =
        !isTeacherPanel && session != null && (hasTeacher || studentAccess);

    final appBar = styledAppGradientAppBar(
      context: context,
      title: Text(l10n.youPageTitle),
    );
    final topInset = appGradientContentTopInset(
      context,
      appBar: appBar,
      extra: 12,
    );

    return AppGradientScaffold(
      appBar: appBar,
      floatingActionButton: session?.user.isAdmin == true
          ? FloatingActionButton.extended(
              heroTag: 'you_add_story_fab',
              onPressed: () => context.push('/stories/create'),
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Add Story',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
        children: [
          const YouAccountSection(),
          if (showLearnerMessages) ...[
            const SizedBox(height: 20),
            ..._youTeacherMessagesSection(
              context: context,
              ref: ref,
              scheme: scheme,
              l10n: l10n,
              previewAsync: previewAsync,
              hasTeacher: hasTeacher,
            ),
          ],
          if (session?.user.isAdmin == true) ...[
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.youSectionAdmin),
            const SizedBox(height: 8),
            _YouAdminUsersInkCard(
              scheme: scheme,
              l10n: l10n,
              onTap: () => context.push('/admin/users'),
            ),
          ],
          const SizedBox(height: 16),
          _SectionLabel(label: l10n.youSectionProgress),
          const SizedBox(height: 8),
          _YouProgressInkCard(
            scheme: scheme,
            l10n: l10n,
            onTap: () => context.push('/stats'),
          ),
          const SizedBox(height: 20),
          _SectionLabel(label: learningGoalSectionTitle(context)),
          const SizedBox(height: 8),
          const LearningGoalCard(),
          if (!isTeacherPanel && hasTeacher) ...[
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.youClassSessionsTitle),
            const SizedBox(height: 8),
            StudentClassSessionsPanel(
              onOpenFullPage: () => context.push('/you/class-sessions'),
            ),
          ],
          if (isTeacherPanel) ...[
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.teacherOpenPanel),
            const SizedBox(height: 8),
            _YouTeacherPanelInkCard(
              scheme: scheme,
              l10n: l10n,
              onTap: () => context.push('/teacher'),
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(label: l10n.youSectionReview),
          const SizedBox(height: 8),
          _YouReviewInkCard(
            scheme: scheme,
            l10n: l10n,
            dueCount: ref.watch(srsProvider.select((s) => s.dueTodayCount)),
            onTap: () => context.push('/review'),
          ),
        ],
      ),
    );
  }
}

class _YouJellyNavCard extends StatelessWidget {
  const _YouJellyNavCard({
    required this.scheme,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onIconColor,
    required this.onTap,
    this.trailing,
  });

  final ColorScheme scheme;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color onIconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return YouJellyShell(
      onTap: onTap,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: youJellyCardSurfaceDecoration(context, scheme: scheme),
      shadows: youJellyCardShadows(context, scheme: scheme),
      child: Row(
        children: [
          YouJellyIconBubble(
            color: iconColor,
            child: Icon(icon, color: onIconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _YouAdminUsersInkCard extends StatelessWidget {
  const _YouAdminUsersInkCard({
    required this.scheme,
    required this.l10n,
    required this.onTap,
  });

  final ColorScheme scheme;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _YouJellyNavCard(
      scheme: scheme,
      title: l10n.adminUserManagement,
      subtitle: l10n.youAdminPanelSubtitle,
      icon: Icons.manage_accounts_rounded,
      iconColor: scheme.error,
      onIconColor: scheme.onError,
      onTap: onTap,
    );
  }
}

class _YouReviewInkCard extends StatelessWidget {
  const _YouReviewInkCard({
    required this.scheme,
    required this.l10n,
    required this.dueCount,
    required this.onTap,
  });

  final ColorScheme scheme;
  final AppLocalizations l10n;
  final int dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _YouJellyNavCard(
      scheme: scheme,
      title: l10n.tabReview,
      subtitle: l10n.youSectionReviewSubtitle,
      icon: Icons.loop_rounded,
      iconColor: scheme.primary,
      onIconColor: scheme.onPrimary,
      onTap: onTap,
      trailing: dueCount > 0
          ? YouJellyCountBadge(label: dueCount > 99 ? '99+' : '$dueCount')
          : null,
    );
  }
}

class _YouProgressInkCard extends StatelessWidget {
  const _YouProgressInkCard({
    required this.scheme,
    required this.l10n,
    required this.onTap,
  });

  final ColorScheme scheme;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _YouJellyNavCard(
      scheme: scheme,
      title: l10n.statsMyProgress,
      subtitle: l10n.youSectionProgressSubtitle,
      icon: Icons.insights_rounded,
      iconColor: scheme.tertiary,
      onIconColor: scheme.onTertiary,
      onTap: onTap,
    );
  }
}

class _YouTeacherPanelInkCard extends StatelessWidget {
  const _YouTeacherPanelInkCard({
    required this.scheme,
    required this.l10n,
    required this.onTap,
  });

  final ColorScheme scheme;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _YouJellyNavCard(
      scheme: scheme,
      title: l10n.teacherOpenPanel,
      subtitle: l10n.youTeacherPanelSubtitle,
      icon: Icons.dashboard_customize_rounded,
      iconColor: scheme.tertiary,
      onIconColor: scheme.onTertiary,
      onTap: onTap,
    );
  }
}

class _YouNoTeacherMessagesCard extends StatelessWidget {
  const _YouNoTeacherMessagesCard({required this.scheme, required this.l10n});

  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: youJellyCardDecoration(context, scheme: scheme),
      child: Row(
        children: [
          YouJellyIconBubble(
            color: scheme.primary,
            child: Icon(Icons.info_outline_rounded, color: scheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.teacherMessagesNoTeacher,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherMessagesPreviewCard extends StatelessWidget {
  const _TeacherMessagesPreviewCard({
    required this.preview,
    required this.onOpen,
    this.useHubCopy = false,
  });

  final TeacherMessagesPreview preview;
  final VoidCallback onOpen;
  final bool useHubCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final unread = preview.unreadCount;
    final last = preview.lastMessage;
    final teacher = preview.teacher;
    final title = teacher?.displayName?.trim().isNotEmpty == true
        ? teacher!.displayName!
        : l10n.youSectionMessages;

    String? timeLabel;
    if (last != null) {
      try {
        final dt = DateTime.tryParse(last.createdAt);
        if (dt != null) {
          timeLabel = DateFormat.MMMd().add_jm().format(dt.toLocal());
        }
      } catch (_) {}
    }

    return YouJellyShell(
      onTap: onOpen,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: youJellyCardSurfaceDecoration(context, scheme: scheme),
      shadows: youJellyCardShadows(context, scheme: scheme),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  YouJellyIconBubble(
                    color: scheme.primary,
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          useHubCopy
                              ? l10n.youSectionMessagesSubtitleHub
                              : l10n.youSectionMessagesSubtitle,
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    YouJellyCountBadge(label: unread > 99 ? '99+' : '$unread'),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: youJellyInsetDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (timeLabel != null)
                        Text(
                          timeLabel,
                          style: tt.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (timeLabel != null) const SizedBox(height: 4),
                      Text(
                        last.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.teacherMessagesEmpty,
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.3,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

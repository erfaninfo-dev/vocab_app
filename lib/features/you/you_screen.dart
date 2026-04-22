import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'student_class_sessions_screen.dart';
import 'you_account_section.dart';

BoxDecoration _youPanelCardDecoration(ColorScheme scheme) {
  return BoxDecoration(
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.youPageTitle)),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.06),
              scheme.surface,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const YouAccountSection(),
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
            if (showLearnerMessages) ...[
              const SizedBox(height: 20),
              previewAsync.when(
                data: (TeacherMessagesPreview p) {
                  final noThreadYet = p.peerCount == 0 &&
                      p.lastMessage == null &&
                      !hasTeacher;
                  if (noThreadYet) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(label: l10n.youSectionMessages),
                        const SizedBox(height: 8),
                        _YouNoTeacherMessagesCard(
                          scheme: scheme,
                          l10n: l10n,
                        ),
                      ],
                    );
                  }
                  final hub = p.peerCount > 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                        label: hub
                            ? l10n.youSectionMessagesHub
                            : l10n.youSectionMessages,
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
                              context.push(
                                '/you/messages?peer_teacher_id=$id',
                              );
                            } else {
                              context.push('/you/messages');
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: l10n.youSectionMessages),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: _youPanelCardDecoration(scheme),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
                error: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: l10n.youSectionMessages),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            ref.invalidate(teacherMessagesPreviewProvider),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: _youPanelCardDecoration(scheme),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: scheme.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.errorGeneric,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _youPanelCardDecoration(scheme),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.errorContainer,
                child: Icon(
                  Icons.manage_accounts_rounded,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.adminUserManagement, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.youAdminPanelSubtitle,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
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
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _youPanelCardDecoration(scheme),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.tertiaryContainer,
                child: Icon(
                  Icons.insights_rounded,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.statsMyProgress, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.youSectionProgressSubtitle,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
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
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _youPanelCardDecoration(scheme),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.tertiaryContainer,
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: scheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.teacherOpenPanel, style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.youTeacherPanelSubtitle,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouNoTeacherMessagesCard extends StatelessWidget {
  const _YouNoTeacherMessagesCard({
    required this.scheme,
    required this.l10n,
  });

  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _youPanelCardDecoration(scheme),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.teacherMessagesNoTeacher,
              style: Theme.of(context).textTheme.bodyMedium,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _youPanelCardDecoration(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          useHubCopy
                              ? l10n.youSectionMessagesSubtitleHub
                              : l10n.youSectionMessagesSubtitle,
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: TextStyle(
                            color: scheme.onError,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (last != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (timeLabel != null)
                        Text(
                          timeLabel,
                          style: tt.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (timeLabel != null) const SizedBox(height: 4),
                      Text(
                        last.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium,
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
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/teacher_message.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'class_sessions_strip.dart';
import 'you_account_section.dart';

class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authProvider).valueOrNull;
    final isTeacher = session?.user.isTeacher == true;
    final hasTeacher = session?.user.teacherUserId != null;
    final previewAsync = ref.watch(teacherMessagesPreviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.youPageTitle),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withOpacity(0.06), scheme.surface],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const YouAccountSection(),
            const SizedBox(height: 16),
            _SectionLabel(label: l10n.youSectionProgress),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                title: Text(l10n.statsMyProgress),
                subtitle: Text(l10n.youSectionProgressSubtitle),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: () => context.push('/stats'),
              ),
            ),
            if (!isTeacher && hasTeacher) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.youClassSessionsTitle),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.youClassSessionsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ref.watch(myClassSessionsProvider).when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => ListTile(
                          leading: Icon(
                            Icons.error_outline_rounded,
                            color: scheme.error,
                          ),
                          title: Text(l10n.errorGeneric),
                          onTap: () =>
                              ref.invalidate(myClassSessionsProvider),
                        ),
                        data: (info) => ClassSessionsStrip(
                          sessions: info.sessions,
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isTeacher) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.teacherOpenPanel),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.tertiaryContainer,
                    child: Icon(
                      Icons.dashboard_customize_rounded,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  title: Text(l10n.teacherOpenPanel),
                  subtitle: Text(l10n.youTeacherPanelSubtitle),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () => context.push('/teacher'),
                ),
              ),
            ],
            if (!isTeacher && session != null) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.youSectionMessages),
              if (!hasTeacher)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                  ),
                )
              else
                previewAsync.when(
                  data: (TeacherMessagesPreview p) =>
                      _TeacherMessagesPreviewCard(
                    preview: p,
                    onOpen: () => context.push('/you/messages'),
                  ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => Card(
                    child: ListTile(
                      leading: Icon(Icons.error_outline_rounded,
                          color: scheme.error),
                      title: Text(l10n.errorGeneric),
                      onTap: () =>
                          ref.invalidate(teacherMessagesPreviewProvider),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeacherMessagesPreviewCard extends StatelessWidget {
  const _TeacherMessagesPreviewCard({
    required this.preview,
    required this.onOpen,
  });

  final TeacherMessagesPreview preview;
  final VoidCallback onOpen;

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
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(
                        Icons.forum_rounded,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          Text(
                            l10n.youSectionMessagesSubtitle,
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unread > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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
                      color: scheme.surfaceContainerHighest.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.5),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (unread > 0)
                      Text(
                        l10n.newMessagesCount(unread),
                        style: tt.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (unread > 0) const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

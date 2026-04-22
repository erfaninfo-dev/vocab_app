import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_chat_open_args.dart';
import 'teacher_chat_ui.dart';

/// Telegram-style chat list for teachers (sorted by API).
class TeacherInboxScreen extends ConsumerWidget {
  const TeacherInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final session = ref.watch(authProvider).valueOrNull;
    final localeName = Localizations.localeOf(context).toString();

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.teacherInboxTitle),
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
          title: Text(l10n.teacherInboxTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.teacherAccessDenied,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final async = ref.watch(teacherInboxStudentsProvider);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        surfaceTintColor: scheme.secondary.withValues(alpha: 0.14),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.teacherInboxTitle,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              tooltip: l10n.teacherInboxOpenPanel,
              onPressed: () => context.push('/teacher'),
              icon: const Icon(Icons.groups_2_rounded),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: TeacherChatUi.inboxListBackgroundDecor(scheme),
          ),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                    ),
                  );
                }
                return RefreshIndicator(
                  color: scheme.primary,
                  onRefresh: () async {
                    ref.invalidate(teacherInboxStudentsProvider);
                    ref.invalidate(teacherMessagesUnreadFabProvider);
                    await ref.read(teacherInboxStudentsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = students[i];
                      final now = DateTime.now();
                      final lastDt =
                          TeacherChatUi.tryParseApiDate(s.lastMessageAt);
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
                      final openArgs = TeacherChatOpenArgs(
                        displayTitle: s.displayLabel,
                        avatarId: s.avatar,
                        userId: s.id,
                      );

                      return Card(
                        elevation: hasUnread ? 3 : 2,
                        shadowColor:
                            scheme.primary.withValues(alpha: hasUnread ? 0.24 : 0.16),
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
                                ProfileAvatar(
                                  avatarId: s.avatar,
                                  userId: s.id,
                                  size: 54,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.displayLabel,
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
                                          borderRadius:
                                              BorderRadius.circular(20),
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
      ),
    );
  }
}

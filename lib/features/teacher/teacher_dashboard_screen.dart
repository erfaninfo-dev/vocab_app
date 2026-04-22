import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_chat_ui.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;

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

    final async = ref.watch(teacherStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: scheme.primary.withValues(alpha: 0.12),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.teacherPanelTitle),
        actions: [
          IconButton.filledTonal(
            tooltip: l10n.teacherInboxTitle,
            onPressed: () => context.push('/teacher/inbox'),
            icon: const Icon(Icons.chat_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
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
                    onPressed: () =>
                        ref.invalidate(teacherStudentsProvider),
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
                ref.invalidate(teacherStudentsProvider);
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
                      onTap: () =>
                          context.push('/teacher/student/${s.id}'),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
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
                                color: scheme.primaryContainer
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${s.sessionCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
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
      ),
    );
  }
}

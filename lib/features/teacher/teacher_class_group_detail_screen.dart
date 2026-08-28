import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../data/models/teacher_class_group.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_chat_ui.dart';

class TeacherClassGroupDetailScreen extends ConsumerStatefulWidget {
  const TeacherClassGroupDetailScreen({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<TeacherClassGroupDetailScreen> createState() =>
      _TeacherClassGroupDetailScreenState();
}

class _TeacherClassGroupDetailScreenState
    extends ConsumerState<TeacherClassGroupDetailScreen> {
  var _addingSession = false;
  final Set<int> _busyMemberIds = {};

  Future<void> _invalidateAll() async {
    ref.invalidate(teacherClassGroupProvider(widget.groupId));
    ref.invalidate(teacherClassGroupsProvider);
    ref.invalidate(teacherStudentsProvider);
    ref.invalidate(teacherWeekUpcomingProvider);
    const filters = [
      TeacherFinancialFilters(),
      TeacherFinancialFilters(period: TeacherFinancePeriod.week),
      TeacherFinancialFilters(period: TeacherFinancePeriod.month),
    ];
    for (final f in filters) {
      ref.invalidate(teacherFinancialSummaryProvider(f));
    }
    final group = ref.read(teacherClassGroupProvider(widget.groupId)).valueOrNull;
    if (group != null) {
      for (final m in group.members) {
        ref.invalidate(teacherStudentSessionsProvider(m.studentId));
      }
    }
  }

  Future<void> _addSessionForAll(AppLocalizations l10n) async {
    setState(() => _addingSession = true);
    try {
      final response = await ref
          .read(apiServiceProvider)
          .addTeacherClassGroupSession(groupId: widget.groupId);
      await _invalidateAll();
      if (!mounted) return;
      final failed = response.results.where((r) => !r.ok).length;
      if (failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.teacherClassGroupsSessionPartial(
                response.addedCount,
                failed,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.teacherClassGroupsSessionAdded(response.addedCount),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _addingSession = false);
    }
  }

  Future<void> _removeMember(
    TeacherClassGroupMember member,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherClassGroupsRemoveMemberTitle),
        content: Text(l10n.teacherClassGroupsRemoveMemberBody(member.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teacherClassGroupsRemoveMemberConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyMemberIds.add(member.studentId));
    try {
      await ref.read(apiServiceProvider).removeTeacherClassGroupMember(
        groupId: widget.groupId,
        studentId: member.studentId,
      );
      await _invalidateAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyMemberIds.remove(member.studentId));
    }
  }

  Future<void> _showAddMemberSheet(
    TeacherClassGroupDetail group,
    AppLocalizations l10n,
  ) async {
    final students = await ref.read(teacherStudentsProvider.future);
    if (!mounted) return;
    final memberIds = group.members.map((m) => m.studentId).toSet();
    final available =
        students.where((s) => !memberIds.contains(s.id)).toList();
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherClassGroupsNoStudentsToAdd)),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  l10n.teacherClassGroupsAddMemberTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final s = available[i];
                    return ListTile(
                      leading: ProfileAvatar(
                        avatarId: s.avatar,
                        userId: s.id,
                        size: 40,
                      ),
                      title: Text(s.displayLabel),
                      subtitle: Text(s.email),
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await ref
                              .read(apiServiceProvider)
                              .addTeacherClassGroupMember(
                                groupId: widget.groupId,
                                studentId: s.id,
                              );
                          await _invalidateAll();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(userFriendlyErrorMessage(e, l10n)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteGroup(
    TeacherClassGroupDetail group,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherClassGroupsDeleteTitle),
        content: Text(l10n.teacherClassGroupsDeleteBody(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teacherClassGroupsDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiServiceProvider).deleteTeacherClassGroup(widget.groupId);
      ref.invalidate(teacherClassGroupsProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(teacherClassGroupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: async.when(
          data: (g) => Text(g.name),
          loading: () => Text(l10n.teacherClassGroupsTitle),
          error: (_, __) => Text(l10n.teacherClassGroupsTitle),
        ),
        actions: [
          async.whenOrNull(
            data: (g) => PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteGroup(g, l10n);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.teacherClassGroupsDeleteTitle),
                ),
              ],
            ),
          ) ??
              const SizedBox.shrink(),
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
                        ref.invalidate(teacherClassGroupProvider(widget.groupId)),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (group) {
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(teacherClassGroupProvider(widget.groupId).future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (group.note != null) ...[
                            Text(
                              group.note!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          FilledButton.icon(
                            onPressed: _addingSession || group.members.isEmpty
                                ? null
                                : () => _addSessionForAll(l10n),
                            icon: _addingSession
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_circle_outline_rounded),
                            label: Text(l10n.teacherClassGroupsAddSessionButton),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.teacherClassGroupsAddSessionHint,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.teacherClassGroupsMembersSection,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddMemberSheet(group, l10n),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: Text(l10n.teacherClassGroupsAddMemberButton),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (group.members.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.teacherClassGroupsMembersEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: group.members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final m = group.members[i];
                          final busy = _busyMemberIds.contains(m.studentId);
                          return AppJellyCard(
                            onTap: () =>
                                context.push('/teacher/student/${m.studentId}'),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ProfileAvatar(
                                  avatarId: m.avatar,
                                  userId: m.studentId,
                                  size: 44,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        m.email,
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
                                IconButton(
                                  tooltip: l10n.teacherClassGroupsRemoveMemberConfirm,
                                  onPressed: busy
                                      ? null
                                      : () => _removeMember(m, l10n),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_remove_outlined,
                                          color: scheme.error,
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

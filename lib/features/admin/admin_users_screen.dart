import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/admin_user_row.dart';
import '../../data/services/api_service.dart';
import '../../l10n/app_localizations.dart';
import 'admin_users_provider.dart';

/// Teachers plus the signed-in admin (so an admin can assign themselves).
List<AdminUserRow> _teacherPickerRows(
  List<AdminUserRow> all,
  int? currentAdminUserId,
) {
  final byId = <int, AdminUserRow>{};
  for (final u in all) {
    if (u.isTeacher) {
      byId[u.id] = u;
    }
  }
  if (currentAdminUserId != null) {
    for (final u in all) {
      if (u.id == currentAdminUserId) {
        byId[u.id] = u;
        break;
      }
    }
  }
  final list = byId.values.toList()
    ..sort((a, b) {
      final la = a.displayName?.trim().isNotEmpty == true
          ? a.displayName!.trim()
          : a.email;
      final lb = b.displayName?.trim().isNotEmpty == true
          ? b.displayName!.trim()
          : b.email;
      return la.toLowerCase().compareTo(lb.toLowerCase());
    });
  return list;
}

bool _teacherIdInPool(int? tid, List<AdminUserRow> pool) {
  if (tid == null) return true;
  return pool.any((t) => t.id == tid);
}

(Color bg, Color fg) _avatarColors(AdminUserRow user, ColorScheme scheme) {
  switch (user.id % 3) {
    case 0:
      return (scheme.primaryContainer, scheme.onPrimaryContainer);
    case 1:
      return (scheme.secondaryContainer, scheme.onSecondaryContainer);
    default:
      return (scheme.tertiaryContainer, scheme.onTertiaryContainer);
  }
}

String _adminTeacherLabel(AdminUserRow u) {
  final n = u.teacherName?.trim();
  if (n != null && n.isNotEmpty) return n;
  final id = u.teacherUserId;
  if (id != null) return '#$id';
  return '';
}

String _userInitials(AdminUserRow u) {
  final n = u.displayName?.trim();
  if (n != null && n.isNotEmpty) {
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return n.length >= 2
        ? n.substring(0, 2).toUpperCase()
        : n[0].toUpperCase();
  }
  final e = u.email;
  if (e.isEmpty) return '?';
  return e[0].toUpperCase();
}

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminUserRow> _filtered(List<AdminUserRow> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((u) {
      if (u.email.toLowerCase().contains(q)) return true;
      final dn = u.displayName?.toLowerCase() ?? '';
      if (dn.contains(q)) return true;
      final tn = u.teacherName?.toLowerCase() ?? '';
      return tn.contains(q);
    }).toList();
  }

  Future<void> _openEditor(
    BuildContext context,
    AdminUserRow row,
    List<AdminUserRow> all,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _AdminEditUserSheet(
          row: row,
          allUsers: all,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(adminUsersListProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.adminUsersTitle),
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.12),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(scheme.primaryContainer, scheme.surface, 0.35)!,
              scheme.surface,
              Color.lerp(scheme.tertiaryContainer, scheme.surface, 0.88)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: async.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: scheme.primary),
          ),
          error: (e, _) {
            final msg = e is StateError && e.message == 'not_admin'
                ? l10n.adminAccessDenied
                : '$e';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 56,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () => context.pop(),
                      child: Text(l10n.back),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (users) {
            final list = _filtered(users);
            final emptyMessage = users.isEmpty
                ? l10n.adminNoUsers
                : (_query.trim().isNotEmpty
                    ? l10n.adminNoSearchResults
                    : l10n.adminNoUsers);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.adminScreenSubtitle,
                          style: tt.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: _AdminSearchField(
                    controller: _searchCtrl,
                    query: _query,
                    hintText: l10n.adminSearchUsersHint,
                    closeTooltip: l10n.close,
                    scheme: scheme,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? RefreshIndicator(
                          color: scheme.primary,
                          onRefresh: () async {
                            ref.invalidate(adminUsersListProvider);
                            await ref.read(adminUsersListProvider.future);
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.45,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline_rounded,
                                        size: 56,
                                        color: scheme.primary
                                            .withValues(alpha: 0.42),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        emptyMessage,
                                        textAlign: TextAlign.center,
                                        style: tt.bodyLarge?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: scheme.primary,
                          onRefresh: () async {
                            ref.invalidate(adminUsersListProvider);
                            await ref.read(adminUsersListProvider.future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final u = list[i];
                              return _AdminUserTile(
                                user: u,
                                l10n: l10n,
                                scheme: scheme,
                                onTap: () => _openEditor(context, u, users),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Stands out from list cards: white surface, primary border, soft shadow.
class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({
    required this.controller,
    required this.query,
    required this.hintText,
    required this.closeTooltip,
    required this.scheme,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final String closeTooltip;
  final ColorScheme scheme;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.45),
          width: 1.75,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: tt.bodyLarge,
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: tt.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          filled: true,
          fillColor: scheme.surface,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: scheme.primary,
            size: 26,
          ),
          prefixIconConstraints: const BoxConstraints(
            minHeight: 48,
            minWidth: 48,
          ),
          suffixIcon: query.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: closeTooltip,
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: scheme.primary.withValues(alpha: 0.55),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _AdminEditUserSheet extends ConsumerStatefulWidget {
  const _AdminEditUserSheet({
    required this.row,
    required this.allUsers,
  });

  final AdminUserRow row;
  final List<AdminUserRow> allUsers;

  @override
  ConsumerState<_AdminEditUserSheet> createState() =>
      _AdminEditUserSheetState();
}

class _AdminEditUserSheetState extends ConsumerState<_AdminEditUserSheet> {
  late final bool _initialStudent;
  late final int? _initialTeacherId;
  late bool _student;
  late int? _teacherId;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final adminId = ref.read(authProvider).valueOrNull?.user.id;
    final pool = _teacherPickerRows(widget.allUsers, adminId);
    _initialStudent = widget.row.studentAccess;
    _initialTeacherId = widget.row.teacherUserId;
    _student = widget.row.studentAccess;
    _teacherId = widget.row.teacherUserId;
    if (!_teacherIdInPool(_teacherId, pool)) {
      _teacherId = null;
    }
  }

  bool get _dirty =>
      _student != _initialStudent || _teacherId != _initialTeacherId;

  Future<void> _confirmDiscardAndClose() async {
    final l10n = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.discardStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(l10n.discardLeave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(authProvider).valueOrNull;
    if (session == null) return;
    final adminId = session.user.id;
    final pool = _teacherPickerRows(widget.allUsers, adminId);
    if (_student && _teacherId != null && !_teacherIdInPool(_teacherId, pool)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.adminTeacherInvalid),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService(authToken: session.token).adminSetUserStudentFlags(
        userId: widget.row.id,
        studentAccess: _student,
        teacherUserId: _student ? _teacherId : null,
      );
      if (!mounted) return;
      ref.invalidate(adminUsersListProvider);
      if (widget.row.id == session.user.id) {
        await ref.read(authProvider.notifier).refreshSession();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.adminUpdated),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('$e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final adminId = ref.watch(authProvider).valueOrNull?.user.id;
    final teacherPool = _teacherPickerRows(widget.allUsers, adminId);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmDiscardAndClose());
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            _userInitials(widget.row),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.adminEditUserSheetTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.row.displayName?.trim().isNotEmpty ==
                                        true
                                    ? widget.row.displayName!.trim()
                                    : widget.row.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.row.displayName?.trim().isNotEmpty ==
                                  true)
                                Text(
                                  widget.row.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      title: Text(
                        l10n.adminStudentAccess,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      value: _student,
                      onChanged: _saving
                          ? null
                          : (v) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _student = v;
                                if (!v) {
                                  _teacherId = null;
                                }
                              });
                            },
                    ),
                    if (_student) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        decoration: InputDecoration(
                          labelText: l10n.adminAssignedTeacher,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        value: _teacherId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.adminNoTeacher),
                          ),
                          ...teacherPool.map(
                            (t) => DropdownMenuItem<int?>(
                              value: t.id,
                              child: Text(
                                t.displayName?.trim().isNotEmpty == true
                                    ? '${t.displayName} · ${t.email}'
                                    : t.email,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _teacherId = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(l10n.adminSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserTile extends StatelessWidget {
  const _AdminUserTile({
    required this.user,
    required this.l10n,
    required this.scheme,
    required this.onTap,
  });

  final AdminUserRow user;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasName = user.displayName?.trim().isNotEmpty == true;
    final title = hasName ? user.displayName!.trim() : user.email;
    final subtitle = hasName ? user.email : null;
    final (avatarBg, avatarFg) = _avatarColors(user, scheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: scheme.surfaceContainerLow,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarBg,
                  child: Text(
                    _userInitials(user),
                    style: tt.titleMedium?.copyWith(
                      color: avatarFg,
                      fontWeight: FontWeight.w700,
                    ),
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
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (user.studentAccess) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 18,
                              color: scheme.primary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.teacherUserId != null
                                    ? '${l10n.adminAssignedTeacher}: ${_adminTeacherLabel(user)}'
                                    : '${l10n.adminAssignedTeacher}: ${l10n.adminNoTeacher}',
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.studentAccess)
                            _RolePill(
                              label: l10n.adminStudentAccess,
                              bg: scheme.secondaryContainer,
                              fg: scheme.onSecondaryContainer,
                            ),
                          if (user.isTeacher)
                            _RolePill(
                              label: l10n.adminRoleTeacher,
                              bg: scheme.tertiaryContainer,
                              fg: scheme.onTertiaryContainer,
                            ),
                          if (user.isAdmin)
                            _RolePill(
                              label: l10n.adminRoleAdmin,
                              bg: scheme.errorContainer,
                              fg: scheme.onErrorContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.85),
                        scheme.tertiaryContainer.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fg.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

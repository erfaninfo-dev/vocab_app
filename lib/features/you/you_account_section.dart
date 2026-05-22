import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../l10n/app_localizations.dart';
import 'student_code_dialogs.dart';

/// Account card moved from Settings — sign-in, profile, student code, sign-out.
class YouAccountSection extends ConsumerWidget {
  const YouAccountSection({super.key});

  static BoxDecoration _cardDecoration(ColorScheme scheme) {
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final authAsync = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final signOutTitleStyle =
        (ListTileTheme.of(context).titleTextStyle ??
                theme.textTheme.titleMedium)
            ?.copyWith(color: scheme.onError);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: l10n.sectionAccount),
        authAsync.when(
          data: (session) {
            if (session == null) {
              return Container(
                decoration: _cardDecoration(scheme),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.login_rounded, color: scheme.primary),
                      title: Text(l10n.signIn),
                      subtitle: Text(l10n.signInSubtitle),
                      onTap: () => context.push('/login'),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: scheme.secondary,
                      ),
                      title: Text(l10n.createAccount),
                      onTap: () => context.push('/register'),
                    ),
                  ],
                ),
              );
            }
            return Container(
              decoration: _cardDecoration(scheme),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/profile'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              avatarId: session.user.avatar,
                              userId: session.user.id,
                              size: 48,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.profile,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    session.user.displayName != null &&
                                            session.user
                                                .displayName!
                                                .trim()
                                                .isNotEmpty
                                        ? '${session.user.displayName!.trim()}\n${session.user.email}'
                                        : session.user.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: session.user.displayName !=
                                                  null &&
                                              session.user.displayName!
                                                  .trim()
                                                  .isNotEmpty
                                          ? 1.35
                                          : 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (session.user.isTeacher || session.user.isAdmin) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: Icon(
                        Icons.vpn_key_outlined,
                        color: scheme.tertiary,
                      ),
                      title: Text(l10n.createStudentCode),
                      subtitle: Text(
                        l10n.createStudentCodeSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          showCreateTeacherStudentCodeDialog(context, ref),
                    ),
                  ] else if (!session.user.studentAccess) ...[
                    const Divider(height: 0),
                    ListTile(
                      leading: Icon(
                        Icons.school_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(l10n.redeemStudentCode),
                      subtitle: Text(
                        l10n.redeemStudentCodeSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => showRedeemStudentCodeDialog(context, ref),
                    ),
                  ],
                  const Divider(height: 0),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: Material(
                      color: Color.lerp(
                        scheme.errorContainer,
                        scheme.error,
                        0.82,
                      )!,
                      child: ListTile(
                        iconColor: scheme.onError,
                        leading: const Icon(Icons.logout_rounded),
                        title: Text(
                          l10n.signOut,
                          style:
                              signOutTitleStyle ??
                              TextStyle(color: scheme.onError),
                        ),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: Text(l10n.signOutTitle),
                                content: Text(l10n.signOutBody),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(l10n.signOut),
                                  ),
                                ],
                              );
                            },
                          );
                          if (ok != true) {
                            return;
                          }
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.signedOut)),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            decoration: _cardDecoration(scheme),
            child: ListTile(
              leading: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
              title: Text(l10n.loadingAccount),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
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

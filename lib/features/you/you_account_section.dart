import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_displayed_books_provider.dart';
import '../../domain/api_providers.dart';

/// Account card moved from Settings — sign-in, profile, student code, sign-out.
class YouAccountSection extends ConsumerWidget {
  const YouAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(label: l10n.sectionAccount),
        authAsync.when(
          data: (session) {
            if (session == null) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.login_rounded,
                        color: scheme.primary,
                      ),
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
            return Card(
              child: Column(
                children: [
                  ListTile(
                    leading: ProfileAvatar(
                      avatarId: session.user.avatar,
                      userId: session.user.id,
                      size: 48,
                    ),
                    title: Text(l10n.profile),
                    subtitle: Text(
                      session.user.displayName != null &&
                              session.user.displayName!.trim().isNotEmpty
                          ? '${session.user.displayName!}\n${session.user.email}'
                          : session.user.email,
                    ),
                    isThreeLine: session.user.displayName != null &&
                        session.user.displayName!.trim().isNotEmpty,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: () => context.push('/profile'),
                  ),
                  if (!session.user.studentAccess) ...[
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
                      onTap: () async {
                        final ctrl = TextEditingController();
                        final submitted = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.redeemStudentCode),
                            content: TextField(
                              controller: ctrl,
                              decoration: InputDecoration(
                                labelText: l10n.studentCodeLabel,
                              ),
                              autofocus: true,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  ctrl.dispose();
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () {
                                  final t = ctrl.text.trim();
                                  ctrl.dispose();
                                  Navigator.of(ctx).pop(t);
                                },
                                child: Text(l10n.continueLabel),
                              ),
                            ],
                          ),
                        );
                        if (submitted == null || submitted.isEmpty) {
                          return;
                        }
                        try {
                          await ref
                              .read(authProvider.notifier)
                              .redeemStudentCode(submitted);
                          ref.invalidate(apiPublicBooksForHomeProvider);
                          ref.invalidate(apiStudentBooksForHomeProvider);
                          ref.invalidate(teacherMessagesPreviewProvider);
                          ref.invalidate(teacherMessagesUnreadFabProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.studentAccessGranted),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.invalidStudentCode),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(l10n.signOut),
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
                ],
              ),
            );
          },
          loading: () => Card(
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

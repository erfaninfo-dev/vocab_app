import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/auth_user.dart';
import '../../l10n/app_localizations.dart';

String authAccountDisplayName(AuthUser user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return user.email;
}

Future<void> showAuthAccountsSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => const _AuthAccountsSheet(),
  );
}

class _AuthAccountsSheet extends ConsumerWidget {
  const _AuthAccountsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final active = ref.watch(authProvider).valueOrNull;
    final storedSlots = ref.watch(authAccountSlotsProvider);
    final slots = effectiveAuthSlots(
      active: active,
      publishedSlots: storedSlots,
    );
    final canAdd = canAddAuthAccount(active: active, slots: slots);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.accountsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final session in slots)
              _AccountTile(
                session: session,
                isActive: active?.user.id == session.user.id,
                onSwitch: () async {
                  if (active?.user.id == session.user.id) {
                    Navigator.pop(context);
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  final name = authAccountDisplayName(session.user);
                  await ref
                      .read(authProvider.notifier)
                      .switchAccount(session.user.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.accountSwitched(name))),
                  );
                  router.go('/home');
                },
                onRemove: slots.length > 1 && active?.user.id != session.user.id
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) {
                            return AlertDialog(
                              title: Text(l10n.removeAccountTitle),
                              content: Text(l10n.removeAccountBody),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(true),
                                  child: Text(l10n.removeAccount),
                                ),
                              ],
                            );
                          },
                        );
                        if (ok != true) return;
                        if (!context.mounted) return;
                        final removed = await ref
                            .read(authProvider.notifier)
                            .removeSavedAccount(session.user.id);
                        if (!context.mounted) return;
                        if (removed) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.signedOut)),
                          );
                        }
                      }
                    : null,
              ),
            if (canAdd)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.person_add_alt_1_rounded),
                ),
                title: Text(
                  l10n.addAccount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(l10n.addAccountSubtitle),
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/login?add_account=1');
                },
              )
            else if (active?.user.isAdmin == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.addAccountLimitReached(kMaxAuthAccounts),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.session,
    required this.isActive,
    required this.onSwitch,
    this.onRemove,
  });

  final AuthSession session;
  final bool isActive;
  final VoidCallback onSwitch;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final user = session.user;
    final name = authAccountDisplayName(user);

    return ListTile(
      onTap: onSwitch,
      leading: ProfileAvatar(
        avatarId: user.avatar,
        userId: user.id,
        size: 44,
        showBorder: isActive,
      ),
      title: Text(
        name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        isActive ? l10n.currentAccountBadge : user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(Icons.check_circle_rounded, color: scheme.primary)
          else if (onRemove != null)
            IconButton(
              tooltip: l10n.removeAccount,
              onPressed: onRemove,
              icon: Icon(Icons.logout_rounded, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

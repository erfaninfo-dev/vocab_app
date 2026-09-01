import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_accounts_sheet.dart';
import '../stories/story_providers.dart';
import '../stories/story_ring.dart';
import 'student_code_dialogs.dart';
import 'you_jelly_style.dart';

/// Account card moved from Settings — sign-in, profile, student code, sign-out.
class YouAccountSection extends ConsumerWidget {
  const YouAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final authAsync = ref.watch(authProvider);
    final storedSlots = ref.watch(authAccountSlotsProvider);
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
            final slots = effectiveAuthSlots(
              active: session,
              publishedSlots: storedSlots,
            );
            if (session == null) {
              return Container(
                decoration: youJellyCardDecoration(context, scheme: scheme),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: YouJellyIconBubble(
                        color: scheme.primary,
                        size: 40,
                        child: Icon(
                          Icons.login_rounded,
                          size: 20,
                          color: scheme.onPrimary,
                        ),
                      ),
                      title: Text(
                        l10n.signIn,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(l10n.signInSubtitle),
                      onTap: () => context.push('/login'),
                    ),
                    Divider(
                      height: 0,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: YouJellyIconBubble(
                        color: scheme.secondary,
                        size: 40,
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                          color: scheme.onSecondary,
                        ),
                      ),
                      title: Text(
                        l10n.createAccount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => context.push('/register'),
                    ),
                  ],
                ),
              );
            }
            return Container(
              decoration: youJellyCardDecoration(context, scheme: scheme),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final ownStories =
                          ref
                              .watch(visibleStoriesProvider)
                              .valueOrNull
                              ?.where(
                                (story) =>
                                    story.adminUserId == session.user.id &&
                                    !story.hasGrammarGame,
                              )
                              .toList() ??
                          const [];
                      final profileAvatar = ownStories.isEmpty
                          ? ProfileAvatar(
                              avatarId: session.user.avatar,
                              userId: session.user.id,
                              size: 48,
                            )
                          : StoryRing(stories: ownStories, size: 60);
                      return Material(
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
                                profileAvatar,
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.profile,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        session.user.displayName != null &&
                                                session.user.displayName!
                                                    .trim()
                                                    .isNotEmpty
                                            ? '${session.user.displayName!.trim()}\n${session.user.email}'
                                            : session.user.email,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              height:
                                                  session.user.displayName !=
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
                                YouJellyIconBubble(
                                  color: scheme.secondary,
                                  size: 36,
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: scheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (session.user.isTeacher || session.user.isAdmin) ...[
                    Divider(
                      height: 0,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: YouJellyIconBubble(
                        color: scheme.tertiary,
                        size: 40,
                        child: Icon(
                          Icons.vpn_key_outlined,
                          size: 20,
                          color: scheme.onTertiary,
                        ),
                      ),
                      title: Text(
                        l10n.createStudentCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        l10n.createStudentCodeSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          showCreateTeacherStudentCodeDialog(context, ref),
                    ),
                  ] else if (!session.user.studentAccess) ...[
                    Divider(
                      height: 0,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: YouJellyIconBubble(
                        color: scheme.primary,
                        size: 40,
                        child: Icon(
                          Icons.school_outlined,
                          size: 20,
                          color: scheme.onPrimary,
                        ),
                      ),
                      title: Text(
                        l10n.redeemStudentCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        l10n.redeemStudentCodeSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => showRedeemStudentCodeDialog(context, ref),
                    ),
                  ],
                  if (showsAuthAccountSwitcher(
                    active: session,
                    slots: slots,
                  )) ...[
                    Divider(
                      height: 0,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: YouJellyIconBubble(
                        color: scheme.primary,
                        size: 40,
                        child: Icon(
                          slots.length > 1
                              ? Icons.switch_account_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 20,
                          color: scheme.onPrimary,
                        ),
                      ),
                      title: Text(
                        slots.length > 1 ? l10n.switchAccount : l10n.addAccount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        slots.length > 1
                            ? l10n.accountsTitle
                            : l10n.addAccountSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          showAuthAccountsSheet(context: context, ref: ref),
                    ),
                  ],
                  Divider(
                    height: 0,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(kYouJellyRadius - 1),
                      bottomRight: Radius.circular(kYouJellyRadius - 1),
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
                          final hasOthers = await ref
                              .read(authProvider.notifier)
                              .hasOtherSavedAccounts();
                          if (!context.mounted) {
                            return;
                          }
                          final choice = await showDialog<_SignOutChoice>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: Text(l10n.signOutTitle),
                                content: Text(
                                  hasOthers
                                      ? l10n.signOutCurrentBody
                                      : l10n.signOutBody,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(_SignOutChoice.cancel),
                                    child: Text(l10n.cancel),
                                  ),
                                  if (hasOthers)
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(
                                        _SignOutChoice.allAccounts,
                                      ),
                                      child: Text(l10n.signOutAllAccounts),
                                    ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(
                                      hasOthers
                                          ? _SignOutChoice.currentOnly
                                          : _SignOutChoice.allAccounts,
                                    ),
                                    child: Text(l10n.signOut),
                                  ),
                                ],
                              );
                            },
                          );
                          if (choice == null || choice == _SignOutChoice.cancel) {
                            return;
                          }
                          if (!context.mounted) {
                            return;
                          }
                          if (choice == _SignOutChoice.allAccounts) {
                            await ref
                                .read(authProvider.notifier)
                                .logoutAllAccounts();
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.signedOut)),
                            );
                            context.go('/home');
                            return;
                          }
                          final next = await ref
                              .read(authProvider.notifier)
                              .logout();
                          if (!context.mounted) {
                            return;
                          }
                          if (next != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.signedOutSwitched(
                                    authAccountDisplayName(next.user),
                                  ),
                                ),
                              ),
                            );
                            context.go('/home');
                          } else {
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
            decoration: youJellyCardDecoration(context, scheme: scheme),
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

enum _SignOutChoice { cancel, currentOnly, allAccounts }

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

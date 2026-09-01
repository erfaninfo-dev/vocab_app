import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/auth_user.dart';
import '../../l10n/app_localizations.dart';
import 'auth_accounts_sheet.dart';

const int _kYouTabIndex = 3;
const double _kSwitcherCardWidth = 248;

Future<void> showAuthAccountsBlurOverlay({
  required BuildContext context,
  double bottomBarHeight = 80,
}) async {
  await Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, animation, __) {
        return FadeTransition(
          opacity: animation,
          child: _AuthAccountsBlurOverlay(bottomBarHeight: bottomBarHeight),
        );
      },
    ),
  );
}

class _AuthAccountsBlurOverlay extends ConsumerWidget {
  const _AuthAccountsBlurOverlay({required this.bottomBarHeight});

  final double bottomBarHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final active = ref.watch(authProvider).valueOrNull;
    final storedSlots = ref.watch(authAccountSlotsProvider);
    final slots = effectiveAuthSlots(
      active: active,
      publishedSlots: storedSlots,
    );
    final canAdd = canAddAuthAccount(active: active, slots: slots);

    final tabCount = 5;
    final tabWidth = media.size.width / tabCount;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final youLeft = rtl
        ? (tabCount - 1 - _kYouTabIndex) * tabWidth
        : _kYouTabIndex * tabWidth;
    final tabCenter = youLeft + tabWidth / 2;
    final maxLeft = (media.size.width - _kSwitcherCardWidth - 12).clamp(
      12.0,
      media.size.width,
    );
    final cardLeft = (tabCenter - _kSwitcherCardWidth / 2).clamp(12.0, maxLeft);
    final bottom = media.padding.bottom + bottomBarHeight + 10;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: ColoredBox(
                    color: scheme.scrim.withValues(alpha: 0.32),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: cardLeft,
            bottom: bottom,
            width: _kSwitcherCardWidth,
            child: Material(
              color: scheme.surface,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final session in slots)
                      _SwitcherRow(
                        leading: _ActiveAvatar(
                          user: session.user,
                          isActive: active?.user.id == session.user.id,
                        ),
                        label: authAccountDisplayName(session.user),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        onTap: () async {
                          if (active?.user.id == session.user.id) {
                            Navigator.of(context).pop();
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final name = authAccountDisplayName(session.user);
                          await ref
                              .read(authProvider.notifier)
                              .switchAccount(session.user.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.accountSwitched(name))),
                          );
                          router.go('/home');
                        },
                      ),
                    if (canAdd)
                      _SwitcherRow(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Color.lerp(
                            scheme.primary,
                            Colors.white,
                            scheme.brightness == Brightness.dark ? 0.12 : 0.28,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        label: l10n.addAccount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        onTap: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push('/login?add_account=1');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAvatar extends StatelessWidget {
  const _ActiveAvatar({required this.user, required this.isActive});

  final AuthUser user;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: scheme.primary, width: 2.4)
            : Border.all(color: Colors.transparent, width: 2.4),
      ),
      child: ProfileAvatar(avatarId: user.avatar, userId: user.id, size: 40),
    );
  }
}

class _SwitcherRow extends StatelessWidget {
  const _SwitcherRow({
    required this.leading,
    required this.label,
    required this.onTap,
    this.style,
  });

  final Widget leading;
  final String label;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

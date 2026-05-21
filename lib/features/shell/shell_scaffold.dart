import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../home/widgets/home_release_notes_banner.dart';

// ─── Tab definition ───────────────────────────────────────────────────────────

class _Tab {
  const _Tab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

List<_Tab> _tabs(AppLocalizations l10n) => [
  _Tab(
    path: '/home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: l10n.tabHome,
  ),
  _Tab(
    path: '/grammar',
    icon: Icons.rule_outlined,
    activeIcon: Icons.rule_rounded,
    label: l10n.tabGrammar,
  ),
  _Tab(
    path: '/word-builder',
    icon: Icons.sort_by_alpha_outlined,
    activeIcon: Icons.sort_by_alpha_rounded,
    label: l10n.tabPlay,
  ),
  _Tab(
    path: '/you',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: l10n.tabYou,
  ),
  _Tab(
    path: '/settings',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    label: l10n.tabSettings,
  ),
];

NavigationDestination _navDestination(_Tab tab) {
  final icon = Icon(tab.icon);
  final selectedIcon = Icon(tab.activeIcon);
  return NavigationDestination(
    icon: icon,
    selectedIcon: selectedIcon,
    label: tab.label,
  );
}

bool _hideBottomBarForLocation(String location) {
  final path = location.trim();
  if (path.startsWith('/grammar/practice')) return true;
  if (path.startsWith('/word-builder')) return true;
  if (path.contains('/quiz') && !path.contains('vocab-quiz')) return true;
  if (!path.contains('/units/')) return false;
  if (path.endsWith('/words') || path.endsWith('/samples')) return true;
  return false;
}

/// Height of [ShellScaffold]'s [NavigationBar]; keep FAB offsets in sync.
const double kShellBottomNavigationBarHeight = 80;

// ─── Shell Scaffold ───────────────────────────────────────────────────────────

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = _tabs(l10n);

    final hideBottomBar = _hideBottomBarForLocation(location);

    int currentIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) {
        currentIndex = i;
        break;
      }
    }

    final onHome = location == '/home';

    return HomeReleaseNotesOverlayGate(
      show: onHome,
      child: Scaffold(
        body: child,
        bottomNavigationBar: hideBottomBar
            ? null
            : NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    context.go(tabs[0].path);
                  } else if (!location.startsWith(tabs[index].path)) {
                    context.push(tabs[index].path);
                  }
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                height: kShellBottomNavigationBarHeight,
                destinations: [
                  for (int i = 0; i < tabs.length; i++)
                    _navDestination(tabs[i]),
                ],
              ),
      ),
    );
  }
}

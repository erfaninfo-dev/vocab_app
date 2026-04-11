import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/srs/srs_provider.dart';
import '../../l10n/app_localizations.dart';

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
    path: '/review',
    icon: Icons.loop_outlined,
    activeIcon: Icons.loop_rounded,
    label: l10n.tabReview,
  ),
  _Tab(
    path: '/stats',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: l10n.tabProgress,
  ),
  _Tab(
    path: '/settings',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    label: l10n.tabSettings,
  ),
];

NavigationDestination _navDestination(_Tab tab, int dueCount) {
  final isReview = tab.path == '/review';
  final icon = isReview && dueCount > 0
      ? Badge(
          label: Text(
            dueCount > 99 ? '99+' : '$dueCount',
            style: const TextStyle(fontSize: 10),
          ),
          child: Icon(tab.icon),
        )
      : Icon(tab.icon);
  final selectedIcon = isReview && dueCount > 0
      ? Badge(
          label: Text(
            dueCount > 99 ? '99+' : '$dueCount',
            style: const TextStyle(fontSize: 10),
          ),
          child: Icon(tab.activeIcon),
        )
      : Icon(tab.activeIcon);
  return NavigationDestination(
    icon: icon,
    selectedIcon: selectedIcon,
    label: tab.label,
  );
}

// ─── Shell Scaffold ───────────────────────────────────────────────────────────

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(srsProvider.select((s) => s.dueTodayCount));
    final l10n = AppLocalizations.of(context)!;
    final tabs = _tabs(l10n);

    int currentIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
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
        destinations: [
          for (int i = 0; i < tabs.length; i++)
            _navDestination(tabs[i], dueCount),
        ],
      ),
    );
  }
}

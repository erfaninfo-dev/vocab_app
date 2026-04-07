import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/srs/srs_provider.dart';

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

const _tabs = [
  _Tab(
    path: '/home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _Tab(
    path: '/grammar',
    icon: Icons.rule_outlined,
    activeIcon: Icons.rule_rounded,
    label: 'Grammar',
  ),
  _Tab(
    path: '/review',
    icon: Icons.loop_outlined,
    activeIcon: Icons.loop_rounded,
    label: 'Review',
  ),
  _Tab(
    path: '/stats',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    label: 'Progress',
  ),
  _Tab(
    path: '/settings',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    label: 'Settings',
  ),
];

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

    int currentIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) {
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
            context.go(_tabs[0].path);
          } else if (!location.startsWith(_tabs[index].path)) {
            context.push(_tabs[index].path);
          }
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(_tabs[0].icon),
            selectedIcon: Icon(_tabs[0].activeIcon),
            label: _tabs[0].label,
          ),
          NavigationDestination(
            icon: Icon(_tabs[1].icon),
            selectedIcon: Icon(_tabs[1].activeIcon),
            label: _tabs[1].label,
          ),
          NavigationDestination(
            icon: dueCount > 0
                ? Badge(
                    label: Text(
                      dueCount > 99 ? '99+' : '$dueCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: Icon(_tabs[2].icon),
                  )
                : Icon(_tabs[2].icon),
            selectedIcon: dueCount > 0
                ? Badge(
                    label: Text(
                      dueCount > 99 ? '99+' : '$dueCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: Icon(_tabs[2].activeIcon),
                  )
                : Icon(_tabs[2].activeIcon),
            label: _tabs[2].label,
          ),
          NavigationDestination(
            icon: Icon(_tabs[3].icon),
            selectedIcon: Icon(_tabs[3].activeIcon),
            label: _tabs[3].label,
          ),
          NavigationDestination(
            icon: Icon(_tabs[4].icon),
            selectedIcon: Icon(_tabs[4].activeIcon),
            label: _tabs[4].label,
          ),
        ],
      ),
    );
  }
}

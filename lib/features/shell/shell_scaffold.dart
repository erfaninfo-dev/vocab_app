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
    icon: Icons.sports_esports_outlined,
    activeIcon: Icons.sports_esports_rounded,
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

/// Play tab index in [_tabs] — keep in sync with `/word-builder` position.
const int _playTabIndex = 2;

/// Matches Material 3 [NavigationBar] indicator width so the custom pill fills it.
const double _playTabPillMinWidth = 64;

class _PlayTabIcon extends StatefulWidget {
  const _PlayTabIcon({required this.selected, required this.isDark});

  final bool selected;
  final bool isDark;

  @override
  State<_PlayTabIcon> createState() => _PlayTabIconState();
}

class _PlayTabIconState extends State<_PlayTabIcon> {
  var _pressed = false;

  static const _warmOrange = Color(0xFFFF6D00);
  static const _warmAmber = Color(0xFFFFAB40);
  static const _deepOrange = Color(0xFFE65100);

  Color _darken(Color color, [double amount = 0.14]) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final isDark = widget.isDark;
    final iconColor = selected
        ? Colors.white
        : (isDark ? _warmAmber : _deepOrange);

    final gradientColors = selected
        ? (isDark
            ? [const Color(0xFFFF8A50), _warmOrange]
            : [const Color(0xFFFF7043), _warmAmber])
        : null;

    final unselectedColor = isDark
        ? _warmOrange.withValues(alpha: 0.2)
        : const Color(0xFFFFE0B2).withValues(alpha: 0.9);

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: _playTabPillMinWidth),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            gradient: gradientColors != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _pressed
                        ? gradientColors.map((c) => _darken(c)).toList()
                        : gradientColors,
                  )
                : null,
            color: selected
                ? null
                : (_pressed ? _darken(unselectedColor, 0.1) : unselectedColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            selected
                ? Icons.sports_esports_rounded
                : Icons.sports_esports_outlined,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

NavigationDestination _navDestination(
  _Tab tab, {
  required bool isPlayTab,
  required bool isDark,
}) {
  if (isPlayTab) {
    return NavigationDestination(
      icon: _PlayTabIcon(selected: false, isDark: isDark),
      selectedIcon: _PlayTabIcon(selected: true, isDark: isDark),
      label: tab.label,
    );
  }

  return NavigationDestination(
    icon: Icon(tab.icon),
    selectedIcon: Icon(tab.activeIcon),
    label: tab.label,
  );
}

bool _hideBottomBarForLocation(String location) {
  final path = location.trim();
  if (path.startsWith('/grammar/practice')) return true;
  if (path.startsWith('/word-builder')) return true;
  if (path.contains('vocab-quiz') || path.contains('/quiz')) return true;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                indicatorColor: currentIndex == _playTabIndex
                    ? Colors.transparent
                    : null,
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
                    _navDestination(
                      tabs[i],
                      isPlayTab: tabs[i].path == '/word-builder',
                      isDark: isDark,
                    ),
                ],
              ),
      ),
    );
  }
}

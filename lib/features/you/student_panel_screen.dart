import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../review/review_screen.dart';
import '../stats/stats_screen.dart';
import 'student_class_sessions_screen.dart';

enum StudentPanelTab { progress, classSessions, review }

class StudentPanelScreen extends ConsumerStatefulWidget {
  const StudentPanelScreen({
    super.key,
    this.initialTab = StudentPanelTab.progress,
  });

  final StudentPanelTab initialTab;

  @override
  ConsumerState<StudentPanelScreen> createState() => _StudentPanelScreenState();
}

class _StudentPanelScreenState extends ConsumerState<StudentPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (widget.initialTab) {
        StudentPanelTab.classSessions => 1,
        StudentPanelTab.review => 2,
        StudentPanelTab.progress => 0,
      },
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.myPanelFab),
        ),
        body: Center(child: Text(l10n.signIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.88),
        surfaceTintColor: scheme.primary.withValues(alpha: 0.12),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.myPanelFab),
        bottom: TabBar(
          controller: _tabs,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              icon: const Icon(Icons.insights_rounded),
              text: l10n.statsMyProgress,
            ),
            Tab(
              icon: const Icon(Icons.school_outlined),
              text: l10n.youClassSessionsTitle,
            ),
            Tab(
              icon: const Icon(Icons.loop_rounded),
              text: l10n.tabReview,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          StatsScreen(embedded: true),
          StudentClassSessionsScreen(embedded: true),
          ReviewScreen(embedded: true),
        ],
      ),
    );
  }
}

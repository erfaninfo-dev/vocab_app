import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_result.dart';
import 'grammar_practice_result_card.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'grammar_practice_leaderboard_merge.dart';

class GrammarResultsScreen extends ConsumerStatefulWidget {
  const GrammarResultsScreen({super.key});

  @override
  ConsumerState<GrammarResultsScreen> createState() =>
      _GrammarResultsScreenState();
}

class _GrammarResultsScreenState extends ConsumerState<GrammarResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: scheme.primary, size: 26),
            const SizedBox(width: 10),
            Text(
              l10n.grammarResultsScreenTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              unselectedLabelStyle: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
              tabs: [
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.myResults),
                    ],
                  ),
                ),
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.users),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const _GrammarSortBar(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.09),
                    scheme.secondary.withValues(alpha: 0.05),
                    scheme.surface,
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [_MyResultsTab(), _PublicResultsTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarSortBar extends ConsumerWidget {
  const _GrammarSortBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final options = <({String label, GrammarResultsListSort value})>[
      (label: l10n.grammarSortNewest, value: GrammarResultsListSort.newest),
      (
        label: l10n.grammarSortMostPractice,
        value: GrammarResultsListSort.mostPractice,
      ),
    ];
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(grammarResultsListSortProvider);
    final match = options.firstWhere(
      (o) => o.value == current,
      orElse: () => options.first,
    );

    final tt = Theme.of(context).textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
    return Material(
      color: scheme.surface.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.sort_rounded, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              l10n.grammarSortLabel,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                isDense: true,
                value: match.label,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: scheme.surface,
                style: tt.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: scheme.surface,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
                items: [
                  for (final o in options)
                    DropdownMenuItem(
                      value: o.label,
                      child: Text(o.label),
                    ),
                ],
                onChanged: (label) {
                  if (label == null) return;
                  final o = options.firstWhere((x) => x.label == label);
                  ref.read(grammarResultsListSortProvider.notifier).state =
                      o.value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyResultsTab extends ConsumerWidget {
  const _MyResultsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    if (session == null) {
      final from = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      return _EmptyStateScaffold(
        icon: Icons.lock_person_rounded,
        iconColor: scheme.tertiary,
        title: l10n.grammarSignInRequiredTitle,
        subtitle: l10n.grammarSignInRequiredBody,
        actionLabel: l10n.goToAuth,
        onAction: () => context.push('/auth?from=$from'),
      );
    }

    final async = ref.watch(myGrammarResultsProvider);
    final sort = ref.watch(grammarResultsListSortProvider);
    return async.when(
      loading: () => _LoadingState(message: l10n.grammarLoadingYourResults),
      error: (_, __) =>
          _ErrorState(onRetry: () => ref.invalidate(myGrammarResultsProvider)),
      data: (items) {
        final sorted = _sortGrammarResultRows(
          List<GrammarResult>.of(items),
          sort,
        );
        if (sorted.isEmpty) {
          return _EmptyStateScaffold(
            icon: Icons.quiz_outlined,
            iconColor: scheme.primary,
            title: l10n.grammarNoPersonalResultsTitle,
            subtitle: l10n.grammarNoPersonalResultsBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await refreshAllRemoteApiData(ref);
            await ref.read(myGrammarResultsProvider.future);
          },
          color: scheme.primary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = sorted[i];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/grammar/result/${r.id}'),
                child: GrammarPracticeResultCard(
                  r: r,
                  style: GrammarPracticeResultCardStyle.personal,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PublicResultsTab extends ConsumerWidget {
  const _PublicResultsTab();

  void _maybeLoadMore(ScrollMetrics m, WidgetRef ref) {
    if (!m.hasViewportDimension) return;
    if (m.maxScrollExtent <= 0) return;
    if (m.pixels < m.maxScrollExtent - 280) return;
    ref.read(publicGrammarCommunityProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(publicGrammarCommunityProvider);
    final sort = ref.watch(grammarResultsListSortProvider);
    final practiceMode = sort == GrammarResultsListSort.mostPractice;
    return async.when(
      loading: () =>
          _LoadingState(message: l10n.grammarLoadingCommunityResults),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(publicGrammarCommunityProvider),
      ),
      data: (state) {
        final raw = state.rawItems;
        final items = practiceMode
            ? mergeGrammarPracticeLeaderboard(raw)
            : raw;
        if (raw.isEmpty) {
          return _EmptyStateScaffold(
            icon: Icons.public_off_rounded,
            iconColor: scheme.onSurfaceVariant,
            title: l10n.grammarCommunityEmptyTitle,
            subtitle: l10n.grammarCommunityEmptyBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await refreshAllRemoteApiData(ref);
            ref.invalidate(publicGrammarCommunityProvider);
            try {
              await ref.read(publicGrammarCommunityProvider.future);
            } catch (_) {}
          },
          color: scheme.primary,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (ScrollMetricsNotification n) {
              final m = n.metrics;
              if (m.hasViewportDimension &&
                  m.maxScrollExtent <= 8 &&
                  m.axis == Axis.vertical) {
                final s = ref.read(publicGrammarCommunityProvider).valueOrNull;
                if (s != null &&
                    s.hasMore &&
                    !s.isLoadingMore &&
                    s.rawItems.isNotEmpty) {
                  ref.read(publicGrammarCommunityProvider.notifier).loadMore();
                }
              }
              return false;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification n) {
                if (n is ScrollUpdateNotification ||
                    n is ScrollEndNotification) {
                  _maybeLoadMore(n.metrics, ref);
                }
                return false;
              },
              child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
              itemCount:
                  items.length + ((state.hasMore || state.isLoadingMore) ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: state.isLoadingMore
                            ? CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: scheme.primary,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }
                final r = items[i];
                final rank = i + 1;
                GrammarLeaderboardMedal? medal;
                if (practiceMode && rank <= 3) {
                  medal = rank == 1
                      ? GrammarLeaderboardMedal.gold
                      : rank == 2
                          ? GrammarLeaderboardMedal.silver
                          : GrammarLeaderboardMedal.bronze;
                }
                final totalsLabel = practiceMode && r.grammarQuizTotal != null
                    ? l10n.grammarCommunityQuizTotal(r.grammarQuizTotal!)
                    : null;
                return GrammarPracticeResultCard(
                  r: r,
                  style: GrammarPracticeResultCardStyle.community,
                  rank: rank,
                  leaderboardMedal: medal,
                  practiceTotalsLabel: totalsLabel,
                );
              },
            ),
            ),
          ),
        );
      },
    );
  }
}

DateTime _grammarResultCreatedAt(GrammarResult r) {
  final t = r.createdAt.trim();
  if (t.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

List<GrammarResult> _sortGrammarResultRows(
  List<GrammarResult> items,
  GrammarResultsListSort sort,
) {
  int cmp(GrammarResult a, GrammarResult b) {
    switch (sort) {
      case GrammarResultsListSort.newest:
        return _grammarResultCreatedAt(b).compareTo(_grammarResultCreatedAt(a));
      case GrammarResultsListSort.mostPractice:
        final ta = a.totalQuestions ?? 0;
        final tb = b.totalQuestions ?? 0;
        final c = tb.compareTo(ta);
        if (c != 0) return c;
        return _grammarResultCreatedAt(b).compareTo(_grammarResultCreatedAt(a));
    }
  }

  items.sort(cmp);
  return items;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: tt.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: scheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorGeneric,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.errorConnectionTryAgain,
              style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgainResults),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateScaffold extends StatelessWidget {
  const _EmptyStateScaffold({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(alpha: 0.12),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(icon, size: 48, color: iconColor),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Stats → Grammar tab: same list + sort as Grammar results → My results.
class GrammarStatsTabPanel extends ConsumerWidget {
  const GrammarStatsTabPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GrammarSortBar(),
        Expanded(child: _MyResultsTab()),
      ],
    );
  }
}

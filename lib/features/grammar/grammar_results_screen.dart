import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
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
                    DropdownMenuItem(value: o.label, child: Text(o.label)),
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

  void _showCommunityProfile(
    BuildContext context,
    GrammarResult result,
    String? practiceTotalsLabel,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, __) => _CommunityProfileDialog(
        result: result,
        practiceTotalsLabel: practiceTotalsLabel,
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showLegacyLinkSheet(
    BuildContext context,
    WidgetRef ref,
    GrammarResult result,
  ) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _LegacyGrammarLinkSheet(legacyName: (result.userName ?? '').trim()),
    );
    if (changed == true && context.mounted) {
      ref.invalidate(publicGrammarCommunityProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Legacy grammar results linked.')),
      );
    }
  }

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
    final session = ref.watch(authProvider).valueOrNull;
    final isAdmin = session?.user.isAdmin == true;
    final practiceMode = sort == GrammarResultsListSort.mostPractice;
    return async.when(
      loading: () =>
          _LoadingState(message: l10n.grammarLoadingCommunityResults),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(publicGrammarCommunityProvider),
      ),
      data: (state) {
        final raw = state.rawItems;
        final items = practiceMode ? mergeGrammarPracticeLeaderboard(raw) : raw;
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
                    items.length +
                    ((state.hasMore || state.isLoadingMore) ? 1 : 0),
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
                  final legacyName = (r.userName ?? '').trim();
                  return GrammarPracticeResultCard(
                    r: r,
                    style: GrammarPracticeResultCardStyle.community,
                    rank: rank,
                    leaderboardMedal: medal,
                    practiceTotalsLabel: totalsLabel,
                    onUserTap: r.userId != null
                        ? () => _showCommunityProfile(context, r, totalsLabel)
                        : isAdmin && legacyName.isNotEmpty
                        ? () => _showLegacyLinkSheet(context, ref, r)
                        : null,
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

class _LegacyGrammarLinkSheet extends ConsumerStatefulWidget {
  const _LegacyGrammarLinkSheet({required this.legacyName});

  final String legacyName;

  @override
  ConsumerState<_LegacyGrammarLinkSheet> createState() =>
      _LegacyGrammarLinkSheetState();
}

class _LegacyGrammarLinkSheetState
    extends ConsumerState<_LegacyGrammarLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _displayNameController;
  LegacyGrammarResultLinkPreview? _preview;
  Object? _error;
  bool _isPreviewing = false;
  bool _isLinking = false;

  String get _legacyName => widget.legacyName.trim();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _displayNameController = TextEditingController(text: _legacyName);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
    return null;
  }

  Future<void> _previewMatches() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isPreviewing = true;
      _error = null;
      _preview = null;
    });
    try {
      final preview = await ref
          .read(apiServiceProvider)
          .linkLegacyGrammarResults(
            legacyName: _legacyName,
            email: _emailController.text,
            displayName: _displayNameController.text,
          );
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _linkMatches() async {
    if (!_formKey.currentState!.validate()) return;
    final preview = _preview;
    if (preview == null) {
      await _previewMatches();
      return;
    }
    if (preview.matchedResultCount < 1) {
      setState(() => _error = 'No unlinked results found for this full name.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm link'),
        content: Text(
          'Link ${preview.matchedResultCount} grammar result(s) for "$_legacyName" to ${_emailController.text.trim()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _isLinking = true;
      _error = null;
    });
    try {
      await ref
          .read(apiServiceProvider)
          .linkLegacyGrammarResults(
            legacyName: _legacyName,
            email: _emailController.text,
            displayName: _displayNameController.text,
            confirm: true,
          );
      await refreshAllRemoteApiData(ref);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final preview = _preview;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.manage_accounts_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Link legacy grammar results',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exact full-name match only',
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _legacyName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Only rows with user_id = NULL and this exact full name will be linked. A first-name-only match is never used here.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                onChanged: (_) => setState(() => _preview = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Display name is required'
                    : null,
                onChanged: (_) => setState(() => _preview = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _LegacyLinkNotice(
                  icon: Icons.error_outline_rounded,
                  color: scheme.error,
                  text: _error.toString().replaceFirst('Exception: ', ''),
                ),
              ],
              if (preview != null) ...[
                const SizedBox(height: 16),
                _LegacyLinkPreviewCard(preview: preview),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPreviewing || _isLinking
                          ? null
                          : _previewMatches,
                      icon: _isPreviewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isPreviewing || _isLinking || preview == null
                          ? null
                          : _linkMatches,
                      icon: _isLinking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_rounded),
                      label: const Text('Link results'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyLinkNotice extends StatelessWidget {
  const _LegacyLinkNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyLinkPreviewCard extends StatelessWidget {
  const _LegacyLinkPreviewCard({required this.preview});

  final LegacyGrammarResultLinkPreview preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final shownCount = preview.samples.length;
    final totalCount = preview.matchedResultCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$totalCount matching result(s)',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (preview.samples.isEmpty)
            Text(
              'No unlinked result was found for this exact full name.',
              style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else ...[
            Text(
              shownCount == totalCount
                  ? 'Showing all matched results.'
                  : 'Showing $shownCount sample(s) of $totalCount. All $totalCount will be linked after confirmation.',
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            ...preview.samples.map((sample) {
              final score =
                  sample.score != null && sample.totalQuestions != null
                  ? '${sample.score}/${sample.totalQuestions}'
                  : '-';
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        score,
                        style: tt.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sample.quizName.isEmpty
                            ? 'Grammar quiz'
                            : sample.quizName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CommunityProfileDialog extends StatelessWidget {
  const _CommunityProfileDialog({
    required this.result,
    required this.practiceTotalsLabel,
  });

  final GrammarResult result;
  final String? practiceTotalsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final displayName = (result.userName ?? '').trim().isEmpty
        ? l10n.guestUser
        : result.userName!.trim();
    final bio = (result.bio ?? '').trim();
    final avatarId = (result.avatar ?? '').trim().isEmpty
        ? 'm1'
        : result.avatar!.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.95),
                scheme.surface,
                scheme.secondaryContainer.withValues(alpha: 0.68),
              ],
            ),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfileAvatar(
                      avatarId: avatarId,
                      userId: result.userId,
                      size: 104,
                      showBorder: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (practiceTotalsLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          practiceTotalsLabel!,
                          style: tt.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.74),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.profileBio,
                                style: tt.labelLarge?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio.isEmpty ? l10n.profileBioEmpty : bio,
                            style: tt.bodyMedium?.copyWith(
                              color: bio.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                              height: 1.45,
                              fontStyle: bio.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
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

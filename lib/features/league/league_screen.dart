import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/league.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

const _kVisibleLeagueTypes = <LeagueType>[
  LeagueType.all,
  LeagueType.grammar,
  LeagueType.vocab,
];

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key, this.initialType = LeagueType.all});

  final LeagueType initialType;

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  late LeagueType _type;
  late final PageController _pageController;
  LeaguePeriod _period = LeaguePeriod.monthly;
  LeagueSort _sort = LeagueSort.points;

  LeagueQuery get _query => (type: _type, period: _period, sort: _sort);

  int get _typePageIndex {
    final index = _kVisibleLeagueTypes.indexOf(_type);
    return index >= 0 ? index : 0;
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _pageController = PageController(initialPage: _typePageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LeagueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      final index = _kVisibleLeagueTypes.indexOf(widget.initialType);
      setState(() => _type = widget.initialType);
      if (index >= 0 && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  void _onLeagueTypeSelected(LeagueType type) {
    final index = _kVisibleLeagueTypes.indexOf(type);
    if (index < 0) return;
    if (type != _type) {
      setState(() => _type = type);
    }
    if (_pageController.hasClients &&
        (_pageController.page?.round() ?? _typePageIndex) != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onLeaguePageChanged(int index) {
    if (index < 0 || index >= _kVisibleLeagueTypes.length) return;
    final nextType = _kVisibleLeagueTypes[index];
    if (nextType == _type) return;
    setState(() => _type = nextType);
  }

  Future<void> _refresh() async {
    ref.invalidate(leagueProvider(_query));
    try {
      await ref.read(leagueProvider(_query).future);
    } catch (_) {}
  }

  void _showLeagueProfile(LeagueEntry entry) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, __) =>
          _LeagueProfileDialog(entry: entry, type: _type, sort: _sort),
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

  void _showSortInfo() {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (_type) {
      LeagueType.grammar => 'Grammar league sorting',
      LeagueType.vocab => 'Vocab league sorting',
      LeagueType.challenge => 'Challenge league sorting',
      LeagueType.wordBuilder => 'Word Builder sorting',
      LeagueType.all => 'All league sorting',
    };
    final body = switch (_type) {
      LeagueType.grammar =>
        'Points ranks learners by Grammar score. The score blends adjusted accuracy, answered questions and active days, so both quality and real practice volume matter.\n\nAccuracy ranks by correct-answer percentage. It only shows learners with at least 100 answered grammar questions so small samples do not jump to the top.',
      LeagueType.vocab =>
        'Points ranks learners by Vocabulary quiz points. Each correct vocab answer gives +2 pts.\n\nAccuracy ranks by correct-answer percentage. It only shows learners with at least 100 answered vocab questions so small samples do not jump to the top.',
      LeagueType.challenge =>
        'Points ranks learners by Grammar Challenge activity and results.\n\nAccuracy ranks by correct-answer percentage. It only shows learners with at least 100 answered challenge questions so small samples do not jump to the top.',
      LeagueType.wordBuilder =>
        'Word Builder ranks learners by game progress: higher difficulty progress first, then level, then coins.',
      LeagueType.all =>
        'Points ranks learners by total learning activity across the app for this period.\n\nAccuracy ranks by correct-answer percentage. It only shows learners with at least 100 answered questions so small samples do not jump to the top.',
    };
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.help_outline_rounded, color: scheme.primary),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _leagueScreenBackground(
            _type,
            Theme.of(context).colorScheme,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _LeagueAppBar(period: _period, onBack: () => context.pop()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _LeagueTypeTabs(
                  selected: _type,
                  onChanged: _onLeagueTypeSelected,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _LeaguePeriodTabs(
                  selected: _period,
                  onChanged: (period) => setState(() => _period = period),
                ),
              ),
              Expanded(
                child: session == null
                    ? const _LeagueSignedOutState()
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onLeaguePageChanged,
                        itemCount: _kVisibleLeagueTypes.length,
                        itemBuilder: (context, index) {
                          final type = _kVisibleLeagueTypes[index];
                          return _LeagueTypePage(
                            type: type,
                            period: _period,
                            sort: _sort,
                            onRefresh: _refresh,
                            onSortChanged: (sort) =>
                                setState(() => _sort = sort),
                            onSortInfo: _showSortInfo,
                            onProfileTap: _showLeagueProfile,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueTypePage extends ConsumerWidget {
  const _LeagueTypePage({
    required this.type,
    required this.period,
    required this.sort,
    required this.onRefresh,
    required this.onSortChanged,
    required this.onSortInfo,
    required this.onProfileTap,
  });

  final LeagueType type;
  final LeaguePeriod period;
  final LeagueSort sort;
  final Future<void> Function() onRefresh;
  final ValueChanged<LeagueSort> onSortChanged;
  final VoidCallback onSortInfo;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(
      leagueProvider((type: type, period: period, sort: sort)),
    );

    return async.when(
      loading: () => _LeagueSkeleton(type: type),
      error: (error, _) => RefreshIndicator(
        onRefresh: onRefresh,
        child: _LeagueErrorState(
          message: userFriendlyErrorMessage(error, l10n),
          isOffline: isNetworkFailureError(error),
          onRetry: onRefresh,
        ),
      ),
      data: (league) => RefreshIndicator(
        onRefresh: onRefresh,
        child: _LeagueContent(
          response: league,
          sort: sort,
          onSortChanged: onSortChanged,
          onSortInfo: onSortInfo,
          onProfileTap: onProfileTap,
        ),
      ),
    );
  }
}

class _LeagueAppBar extends StatelessWidget {
  const _LeagueAppBar({required this.period, required this.onBack});

  final LeaguePeriod period;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'League',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  period.compactLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaguePeriodTabs extends StatelessWidget {
  const _LeaguePeriodTabs({required this.selected, required this.onChanged});

  final LeaguePeriod selected;
  final ValueChanged<LeaguePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: LeaguePeriod.values.map((period) {
          final active = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? scheme.onSurface.withValues(alpha: 0.92)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  period.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? scheme.surface : scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeagueTypeTabs extends StatelessWidget {
  const _LeagueTypeTabs({required this.selected, required this.onChanged});

  final LeagueType selected;
  final ValueChanged<LeagueType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const visibleTypes = _kVisibleLeagueTypes;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: visibleTypes.map((type) {
          final active = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active ? _leagueGradient(type) : null,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: _leagueAccent(type).withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Text(
                  type.label,
                  style: TextStyle(
                    color: active ? Colors.white : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeagueContent extends StatelessWidget {
  const _LeagueContent({
    required this.response,
    required this.sort,
    required this.onSortChanged,
    required this.onSortInfo,
    required this.onProfileTap,
  });

  final LeagueResponse response;
  final LeagueSort sort;
  final ValueChanged<LeagueSort> onSortChanged;
  final VoidCallback onSortInfo;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final entries = response.leaderboard;
    final hasActivity = entries.any((entry) {
      return entry.points > 0 ||
          entry.answeredCount > 0 ||
          entry.completedCount > 0 ||
          entry.activeDays > 0;
    });
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 28),
      children: [
        _LeagueHeader(response: response),
        const SizedBox(height: 18),
        if (entries.isEmpty || !hasActivity)
          _LeagueEmptyState(type: response.type, sort: sort)
        else ...[
          _LeaguePodium(
            entries: entries.take(3).toList(),
            type: response.type,
            sort: sort,
            onProfileTap: onProfileTap,
          ),
          const SizedBox(height: 14),
          _LeagueLeaderboardCard(
            type: response.type,
            sort: sort,
            minimumAnswered: response.minimumAnswered,
            entries: entries,
            onSortChanged: onSortChanged,
            onSortInfo: onSortInfo,
            onProfileTap: onProfileTap,
          ),
        ],
      ],
    );
  }
}

class _LeagueLeaderboardCard extends StatelessWidget {
  const _LeagueLeaderboardCard({
    required this.type,
    required this.sort,
    required this.minimumAnswered,
    required this.entries,
    required this.onSortChanged,
    required this.onSortInfo,
    required this.onProfileTap,
  });

  final LeagueType type;
  final LeagueSort sort;
  final int minimumAnswered;
  final List<LeagueEntry> entries;
  final ValueChanged<LeagueSort> onSortChanged;
  final VoidCallback onSortInfo;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _LeaderboardSortControl(
                  selected: sort,
                  onChanged: onSortChanged,
                  onInfo: onSortInfo,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _LeagueRankTile(
                    entry: entries[i],
                    type: type,
                    sort: sort,
                    minimumAnswered: minimumAnswered,
                    onProfileTap: onProfileTap,
                  ),
                  if (i != entries.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSortControl extends StatelessWidget {
  const _LeaderboardSortControl({
    required this.selected,
    required this.onChanged,
    required this.onInfo,
  });

  final LeagueSort selected;
  final ValueChanged<LeagueSort> onChanged;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<LeagueSort>(
          tooltip: 'Sort leaderboard',
          initialValue: selected,
          onSelected: onChanged,
          itemBuilder: (context) => LeagueSort.values
              .map(
                (sort) => PopupMenuItem<LeagueSort>(
                  value: sort,
                  child: Row(
                    children: [
                      Icon(
                        sort == LeagueSort.points
                            ? Icons.bolt_rounded
                            : Icons.percent_rounded,
                        size: 18,
                        color: sort == selected ? scheme.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(sort.label),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected == LeagueSort.points
                      ? Icons.bolt_rounded
                      : Icons.percent_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  selected.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onInfo,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader({required this.response});

  final LeagueResponse response;

  @override
  Widget build(BuildContext context) {
    final type = response.type;
    final sort = response.sort;
    final current = response.currentUserRank;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: _leagueGradient(type),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _leagueAccent(type).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LeagueIconBubble(type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.season.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: sort == LeagueSort.accuracy
                      ? 'Accuracy'
                      : type == LeagueType.grammar
                      ? 'Score'
                      : 'Points',
                  value: current == null
                      ? '-'
                      : sort == LeagueSort.accuracy
                      ? '${current.accuracy.toStringAsFixed(1)}%'
                      : type == LeagueType.grammar
                      ? '${current.points}'
                      : '${current.points}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetric(
                  label: 'Your rank',
                  value: current?.rank == null ? '-' : '#${current!.rank}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetric(
                  label: 'Players',
                  value: '${response.summary.participants}',
                ),
              ),
            ],
          ),
          if (type == LeagueType.challenge && response.activeChallenges == 0)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No grammar challenges are active in this season yet.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          if (type == LeagueType.grammar)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Rank blends adjusted accuracy, answered questions and active days.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueIconBubble extends StatelessWidget {
  const _LeagueIconBubble({required this.type});

  final LeagueType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Icon(_leagueIcon(type), color: Colors.white, size: 30),
    );
  }
}

class _LeaguePodium extends StatelessWidget {
  const _LeaguePodium({
    required this.entries,
    required this.type,
    required this.sort,
    required this.onProfileTap,
  });

  final List<LeagueEntry> entries;
  final LeagueType type;
  final LeagueSort sort;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final slots = <LeagueEntry?>[
      entries.length > 1 ? entries[1] : null,
      entries.isNotEmpty ? entries[0] : null,
      entries.length > 2 ? entries[2] : null,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumSlot(
            entry: slots[0],
            type: type,
            sort: sort,
            height: 132,
            onProfileTap: onProfileTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PodiumSlot(
            entry: slots[1],
            type: type,
            sort: sort,
            height: 154,
            onProfileTap: onProfileTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PodiumSlot(
            entry: slots[2],
            type: type,
            sort: sort,
            height: 124,
            onProfileTap: onProfileTap,
          ),
        ),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.type,
    required this.sort,
    required this.height,
    required this.onProfileTap,
  });

  final LeagueEntry? entry;
  final LeagueType type;
  final LeagueSort sort;
  final double height;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = entry;
    final compact = height < 132;
    final avatarSize = compact ? 40.0 : 46.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: e == null ? null : () => onProfileTap(e),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: height,
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: e == null
              ? Icon(
                  Icons.emoji_events_outlined,
                  color: scheme.outline,
                  size: 30,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        ProfileAvatar(
                          avatarId: e.avatar,
                          userId: e.userId,
                          size: avatarSize,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _RankBadge(rank: e.rank ?? 0, type: type),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 9),
                    Text(
                      e.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 12 : null,
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 9),
                    _LeagueScoreCard(
                      entry: e,
                      type: type,
                      sort: sort,
                      compact: true,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LeagueRankTile extends StatelessWidget {
  const _LeagueRankTile({
    required this.entry,
    required this.type,
    required this.sort,
    required this.minimumAnswered,
    required this.onProfileTap,
  });

  final LeagueEntry entry;
  final LeagueType type;
  final LeagueSort sort;
  final int minimumAnswered;
  final ValueChanged<LeagueEntry> onProfileTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final needs = entry.neededAnswers(minimumAnswered);
    final reportHint =
        entry.grammarReportCount > 0 &&
            (type == LeagueType.grammar || type == LeagueType.all)
        ? ' • helped ${entry.grammarReportCount}'
        : '';
    final subtitle = type == LeagueType.grammar
        ? entry.eligible
              ? '${entry.accuracy.toStringAsFixed(1)}% • ${entry.answeredCount} answered • ${entry.activeDays} days$reportHint'
              : '$needs more answers needed • ${entry.accuracy.toStringAsFixed(1)}% accuracy$reportHint'
        : '${entry.correctCount} correct • ${entry.activeDays} active days$reportHint';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onProfileTap(entry),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: _LeagueListRankBadge(rank: entry.rank, type: type),
                ),
                Align(
                  alignment: Alignment.center,
                  child: ProfileAvatar(
                    avatarId: entry.avatar,
                    userId: entry.userId,
                    size: 50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      entry.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _LeagueRankMetricsBlock(
                  entry: entry,
                  type: type,
                  sort: sort,
                  subtitle: subtitle,
                  subtitleStyle: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueRankMetricsBlock extends StatelessWidget {
  const _LeagueRankMetricsBlock({
    required this.entry,
    required this.type,
    required this.sort,
    required this.subtitle,
    required this.subtitleStyle,
  });

  final LeagueEntry entry;
  final LeagueType type;
  final LeagueSort sort;
  final String subtitle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LeagueScoreCard(entry: entry, type: type, sort: sort),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: _leagueScorePillDecoration(type),
                  child: Text(
                    _compactBadgeLabel(entry, type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            subtitle,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: subtitleStyle,
          ),
        ],
      ),
    );
  }
}

class _LeagueScoreCard extends StatelessWidget {
  const _LeagueScoreCard({
    required this.entry,
    required this.type,
    required this.sort,
    this.compact = false,
  });

  final LeagueEntry entry;
  final LeagueType type;
  final LeagueSort sort;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: _leagueScorePillDecoration(type),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _scoreIcon(type, sort),
            size: compact ? 11 : 12,
            color: Colors.white,
          ),
          SizedBox(width: compact ? 3 : 3),
          Text(
            _scoreLabel(entry, type, sort),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueProfilePill extends StatelessWidget {
  const _LeagueProfilePill({required this.type, required this.child});

  final LeagueType type;
  final Widget child;

  static const _padding = EdgeInsets.symmetric(horizontal: 9, vertical: 6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      alignment: Alignment.center,
      decoration: _leagueScorePillDecoration(type),
      child: child,
    );
  }
}

class _LeagueProfileDialog extends StatelessWidget {
  const _LeagueProfileDialog({
    required this.entry,
    required this.type,
    required this.sort,
  });

  final LeagueEntry entry;
  final LeagueType type;
  final LeagueSort sort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bio = (entry.bio ?? '').trim();
    final accent = _leagueAccent(type);
    final showCompleted =
        type == LeagueType.challenge ||
        type == LeagueType.wordBuilder ||
        entry.completedCount > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                scheme.surface,
                _leagueGradient(type).colors.last.withValues(alpha: 0.12),
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
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              ProfileAvatar(
                                avatarId: entry.avatar,
                                userId: entry.userId,
                                size: 96,
                                showBorder: true,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: _RankBadge(
                                  rank: entry.rank ?? 0,
                                  type: type,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            entry.displayName,
                            textAlign: TextAlign.center,
                            style: tt.headlineSmall?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            bio.isEmpty ? 'No bio yet.' : bio,
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(
                              color: bio.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurfaceVariant,
                              fontStyle: bio.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              height: 1.32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 308),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _LeagueProfilePill(
                                  type: type,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _scoreIcon(type, sort),
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _scoreLabel(entry, type, sort),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _LeagueProfilePill(
                                  type: type,
                                  child: Text(
                                    entry.badge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7,
                      childAspectRatio: 2.75,
                      children: [
                        _LeagueDetailMetric(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Rank',
                          value: entry.rank == null ? '-' : '#${entry.rank}',
                          color: accent,
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.percent_rounded,
                          label: 'Accuracy',
                          value: '${entry.accuracy.toStringAsFixed(1)}%',
                          color: accent,
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.check_circle_rounded,
                          label: 'Correct',
                          value: '${entry.correctCount}',
                          color: const Color(0xFF16A34A),
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.cancel_rounded,
                          label: 'Wrong',
                          value: '${entry.wrongCount}',
                          color: const Color(0xFFE11D48),
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.quiz_rounded,
                          label: 'Answered',
                          value: '${entry.answeredCount}',
                          color: accent,
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Active days',
                          value: '${entry.activeDays}',
                          color: const Color(0xFFF97316),
                        ),
                        _LeagueDetailMetric(
                          icon: Icons.playlist_add_check_rounded,
                          label: 'Sessions',
                          value: '${entry.sessionCount}',
                          color: accent,
                        ),
                        if (type != LeagueType.vocab)
                          _LeagueDetailMetric(
                            icon: Icons.outlined_flag_rounded,
                            label: 'Grammar help',
                            value: '${entry.grammarReportCount}',
                            color: const Color(0xFFEA580C),
                          ),
                        if (showCompleted)
                          _LeagueDetailMetric(
                            icon: Icons.flag_rounded,
                            label: 'Completed',
                            value: '${entry.completedCount}',
                            color: accent,
                          ),
                      ],
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

class _LeagueDetailMetric extends StatelessWidget {
  const _LeagueDetailMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.type});

  final int rank;
  final LeagueType type;

  @override
  Widget build(BuildContext context) {
    final colors = _rankBadgeColors(rank, type);
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: _rankBadgeForeground(rank),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<Color> _rankBadgeColors(int? rank, LeagueType type) {
  return switch (rank) {
    1 => const [Color(0xFFFFD54F), Color(0xFFFF9800)],
    2 => const [Color(0xFFECEFF1), Color(0xFF90A4AE)],
    3 => const [Color(0xFFFFCC80), Color(0xFFBF6D2F)],
    null => [
      _leagueAccent(type).withValues(alpha: 0.38),
      _leagueAccent(type).withValues(alpha: 0.78),
    ],
    _ => _leagueGradient(type).colors,
  };
}

Color _rankBadgeForeground(int? rank) {
  return switch (rank) {
    1 => const Color(0xFF4E342E),
    2 => const Color(0xFF263238),
    null => Colors.white,
    _ => Colors.white,
  };
}

class _LeagueListRankBadge extends StatelessWidget {
  const _LeagueListRankBadge({required this.rank, required this.type});

  final int? rank;
  final LeagueType type;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    final scheme = Theme.of(context).colorScheme;
    final colors = _rankBadgeColors(rank, type);
    final value = rank == null ? '-' : '${rank!}';
    return SizedBox(
      width: size + 8,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: scheme.surface.withValues(alpha: 0.84),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _rankBadgeForeground(rank),
              fontSize: size >= 38 ? 16 : 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueEmptyState extends StatelessWidget {
  const _LeagueEmptyState({required this.type, required this.sort});

  final LeagueType type;
  final LeagueSort sort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = sort == LeagueSort.accuracy
        ? 'Accuracy view only shows learners with at least 100 answered questions.'
        : switch (type) {
            LeagueType.all => 'Start learning today to enter the All League.',
            LeagueType.grammar =>
              'Answer 30 grammar questions this week to enter this league.',
            LeagueType.vocab =>
              'Take vocab quizzes to climb the Vocabulary League.',
            LeagueType.challenge =>
              'No grammar challenges yet. Try one from Grammar.',
            LeagueType.wordBuilder =>
              'Play Word Builder to climb by difficulty, level, and coins.',
          };
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Icon(_leagueIcon(type), size: 46, color: _leagueAccent(type)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _LeagueSkeleton extends StatelessWidget {
  const _LeagueSkeleton({required this.type});

  final LeagueType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          height: 184,
          decoration: BoxDecoration(
            gradient: _leagueGradient(type),
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          6,
          (index) => Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeagueErrorState extends StatelessWidget {
  const _LeagueErrorState({
    required this.message,
    required this.isOffline,
    required this.onRetry,
  });

  final String message;
  final bool isOffline;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOffline)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.errorContainer,
                                  scheme.primaryContainer.withValues(
                                    alpha: 0.72,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            '📡',
                            style: theme.textTheme.displaySmall,
                            semanticsLabel: l10n.errNoInternet,
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: scheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.wifi_off_rounded,
                                size: 20,
                                color: scheme.onError,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.errorContainer.withValues(alpha: 0.9),
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 40,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.couldNotLoadLeague,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.leagueErrorPullToRefresh,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeagueSignedOutState extends StatelessWidget {
  const _LeagueSignedOutState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, color: scheme.primary, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Sign in to join the league',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Your rank, points and challenge results will be saved to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _scoreLabel(LeagueEntry entry, LeagueType type, LeagueSort sort) {
  if (sort == LeagueSort.accuracy) {
    return '${entry.accuracy.toStringAsFixed(1)}%';
  }
  return switch (type) {
    LeagueType.grammar => '${entry.points} score',
    LeagueType.vocab => '${entry.points} pts',
    LeagueType.challenge => '${entry.points} pts',
    LeagueType.wordBuilder => '${entry.points} coins',
    LeagueType.all => '${entry.points} pts',
  };
}

String _compactBadgeLabel(LeagueEntry entry, LeagueType type) {
  final badge = entry.badge.trim();
  if (type == LeagueType.grammar && badge.startsWith('Grammar ')) {
    return badge.replaceFirst('Grammar ', '');
  }
  return badge;
}

BoxDecoration _leagueScorePillDecoration(LeagueType type) {
  final accent = _leagueAccent(type);
  final colors = _leagueGradient(type).colors;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.first.withValues(alpha: 0.78),
        accent.withValues(alpha: 0.88),
        colors.last.withValues(alpha: 0.72),
      ],
    ),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: accent.withValues(alpha: 0.72)),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.18),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

IconData _leagueIcon(LeagueType type) {
  return switch (type) {
    LeagueType.all => Icons.auto_awesome_rounded,
    LeagueType.grammar => Icons.menu_book_rounded,
    LeagueType.vocab => Icons.translate_rounded,
    LeagueType.challenge => Icons.psychology_alt_rounded,
    LeagueType.wordBuilder => Icons.emoji_events_rounded,
  };
}

IconData _scoreIcon(LeagueType type, LeagueSort sort) {
  if (sort == LeagueSort.accuracy) {
    return Icons.percent_rounded;
  }
  return switch (type) {
    LeagueType.grammar => Icons.insights_rounded,
    LeagueType.wordBuilder => Icons.monetization_on_rounded,
    _ => Icons.bolt_rounded,
  };
}

Color _leagueAccent(LeagueType type) {
  return switch (type) {
    LeagueType.all => const Color(0xFFE1306C),
    LeagueType.grammar => const Color(0xFF3461FF),
    LeagueType.vocab => const Color(0xFF00A86B),
    LeagueType.challenge => const Color(0xFF7F00FF),
    LeagueType.wordBuilder => const Color(0xFFE1306C),
  };
}

LinearGradient _leagueGradient(LeagueType type) {
  return switch (type) {
    LeagueType.all => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF58529), Color(0xFFE1306C), Color(0xFF8134AF)],
    ),
    LeagueType.grammar => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00C6FF), Color(0xFF3461FF), Color(0xFF6A5CFF)],
    ),
    LeagueType.vocab => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00D084), Color(0xFF00A86B), Color(0xFF007A5A)],
    ),
    LeagueType.challenge => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00C6FF), Color(0xFF7F00FF), Color(0xFFE100FF)],
    ),
    LeagueType.wordBuilder => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFB300), Color(0xFFE1306C), Color(0xFF7E57C2)],
    ),
  };
}

LinearGradient _leagueScreenBackground(LeagueType type, ColorScheme scheme) {
  final accent = _leagueAccent(type);
  final gradientColors = _leagueGradient(type).colors;
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      accent.withValues(alpha: 0.13),
      gradientColors.last.withValues(alpha: 0.07),
      scheme.surface,
    ],
  );
}

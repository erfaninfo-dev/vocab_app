import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/grammar_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

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
              unselectedLabelStyle:
                  tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
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
                children: const [
                  _MyResultsTab(),
                  _PublicResultsTab(),
                ],
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

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.sort_rounded, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              l10n.grammarSortLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: match.label,
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
      return _EmptyStateScaffold(
        icon: Icons.lock_person_rounded,
        iconColor: scheme.tertiary,
        title: l10n.grammarSignInRequiredTitle,
        subtitle: l10n.grammarSignInRequiredBody,
        actionLabel: l10n.grammarGoToSignIn,
        onAction: () => context.push('/settings'),
      );
    }

    final async = ref.watch(myGrammarResultsProvider);
    final sort = ref.watch(grammarResultsListSortProvider);
    return async.when(
      loading: () => _LoadingState(message: l10n.grammarLoadingYourResults),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(myGrammarResultsProvider),
      ),
      data: (items) {
        final sorted = _sortGrammarResultRows(List<GrammarResult>.of(items), sort);
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
            await ref
                .read(apiServiceProvider)
                .bustGrammarResultsListCaches();
            ref.invalidate(myGrammarResultsProvider);
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
                child: _ResultCard(
                  r: r,
                  variant: _ResultCardVariant.myResults,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(publicGrammarResultsProvider);
    final sort = ref.watch(grammarResultsListSortProvider);
    return async.when(
      loading: () =>
          _LoadingState(message: l10n.grammarLoadingCommunityResults),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(publicGrammarResultsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyStateScaffold(
            icon: Icons.public_off_rounded,
            iconColor: scheme.onSurfaceVariant,
            title: l10n.grammarCommunityEmptyTitle,
            subtitle: l10n.grammarCommunityEmptyBody,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(apiServiceProvider)
                .bustGrammarResultsListCaches();
            ref.invalidate(publicGrammarResultsProvider);
            await ref.read(publicGrammarResultsProvider.future);
          },
          color: scheme.primary,
          child: _UsersPracticeLeaderboard(
            results: items,
            scheme: scheme,
            sort: sort,
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

String _formatGrammarDisplayDateTime(DateTime dt) {
  if (dt.millisecondsSinceEpoch == 0) return '—';
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y/$m/$d · $h:$min';
}

String _formatCreatedAtRaw(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '—';
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized);
  if (dt == null) return raw;
  return _formatGrammarDisplayDateTime(dt);
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

class _UsersPracticeLeaderboard extends StatelessWidget {
  const _UsersPracticeLeaderboard({
    required this.results,
    required this.scheme,
    required this.sort,
  });

  final List<GrammarResult> results;
  final ColorScheme scheme;
  final GrammarResultsListSort sort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byUser = <String, List<GrammarResult>>{};
    for (final r in results) {
      final name = (r.userName ?? '').trim();
      final key = name.isEmpty ? l10n.guestUser : name;
      byUser.putIfAbsent(key, () => []).add(r);
    }

    final rows = byUser.entries.map((e) {
      final name = e.key;
      final items = e.value;
      final attempts = items.length;
      final latest = items
          .map(_grammarResultCreatedAt)
          .fold<DateTime>(
            DateTime.fromMillisecondsSinceEpoch(0),
            (a, b) => a.isAfter(b) ? a : b,
          );

      double? avgPct;
      var sum = 0.0;
      var n = 0;
      for (final r in items) {
        final s = r.score;
        final t = r.totalQuestions;
        if (s != null && t != null && t > 0) {
          sum += (s / t) * 100;
          n++;
        }
      }
      if (n > 0) avgPct = sum / n;

      return (name: name, attempts: attempts, avgPct: avgPct, latest: latest);
    }).toList()
      ..sort((a, b) {
        return switch (sort) {
          GrammarResultsListSort.newest => b.latest.compareTo(a.latest),
          GrammarResultsListSort.mostPractice =>
            b.attempts.compareTo(a.attempts),
        };
      });

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = rows[i];
        final medal = switch (sort) {
          GrammarResultsListSort.newest => null,
          GrammarResultsListSort.mostPractice => switch (i) {
              0 => '🥇',
              1 => '🥈',
              2 => '🥉',
              _ => null,
            },
        };

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Center(
                  child: medal != null
                      ? Text(medal, style: const TextStyle(fontSize: 18))
                      : Text(
                          '${i + 1}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.attempts} practice session(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatGrammarDisplayDateTime(r.latest),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (r.avgPct != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${r.avgPct!.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum _ResultCardVariant { myResults, public }

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.r,
    required this.variant,
  });

  final GrammarResult r;
  final _ResultCardVariant variant;

  /// Topic labels for chips: prefers JSON array in [GrammarResult.selectedGrammarsRaw],
  /// otherwise splits [GrammarResult.quizName] by ` + ` (same format as the quiz submitter uses).
  static List<String> _topicLabelsForResult(GrammarResult r) {
    final raw = r.selectedGrammarsRaw;
    final s = (raw ?? '').trim();
    if (s.isNotEmpty) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .take(16)
              .toList();
        }
      } catch (_) {
        return [s];
      }
    }
    final q = r.quizName.trim();
    if (q.isEmpty) return const [];
    final parts = q
        .split(RegExp(r'\s*\+\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(16)
        .toList();
    if (parts.isNotEmpty) {
      return parts;
    }
    return [q];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final chips = _topicLabelsForResult(r);
    final isPublic = r.public == 1;
    final displayName = (r.userName ?? '').trim().isEmpty
        ? l10n.guestUser
        : r.userName!.trim();

    final int? score = r.score;
    final int? total = r.totalQuestions;
    final hasScore = score != null && total != null && total > 0;
    final double ratio;
    if (score != null && total != null && total > 0) {
      ratio = score / total;
    } else {
      ratio = 0.0;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              scheme.surface.withValues(alpha: 0.98),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (variant == _ResultCardVariant.public)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _UserAvatar(
                            scheme: scheme,
                            avatarId: r.avatar,
                            userId: r.userId,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayName,
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (variant == _ResultCardVariant.public &&
                        chips.isNotEmpty)
                      const SizedBox(height: 8),
                    if (chips.isNotEmpty)
                      _GrammarTopicChipsWrap(
                        labels: chips,
                        scheme: scheme,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatCreatedAtRaw(r.createdAt),
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (variant == _ResultCardVariant.myResults)
                          _PrivacyPill(isPublic: isPublic, scheme: scheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ScoreRing(
                score: score,
                total: total,
                ratio: ratio,
                hasScore: hasScore,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact topic tags; [Wrap] + max width per tag so many topics stay readable.
class _GrammarTopicChipsWrap extends StatelessWidget {
  const _GrammarTopicChipsWrap({
    required this.labels,
    required this.scheme,
  });

  final List<String> labels;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTag = (constraints.maxWidth * 0.48).clamp(72.0, 148.0);

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.start,
          children: [
            for (final c in labels)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c,
                    style: tt.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.scheme,
    this.avatarId,
    this.userId,
  });

  final ColorScheme scheme;
  final String? avatarId;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    final id = (avatarId ?? '').trim();
    if (id.isNotEmpty) {
      return ProfileAvatar(
        avatarId: id,
        userId: userId,
        size: 40,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.85),
      foregroundColor: scheme.onPrimaryContainer,
      child: Icon(
        Icons.person_rounded,
        color: scheme.primary,
        size: 22,
      ),
    );
  }
}

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill({
    required this.isPublic,
    required this.scheme,
  });

  final bool isPublic;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublic
            ? scheme.secondaryContainer.withValues(alpha: 0.75)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: isPublic
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? l10n.resultVisibilityPublic : l10n.resultVisibilityPrivate,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPublic
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.total,
    required this.ratio,
    required this.hasScore,
    required this.scheme,
  });

  final int? score;
  final int? total;
  final double ratio;
  final bool hasScore;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pct = hasScore ? (ratio * 100).round() : null;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: hasScore ? ratio.clamp(0.0, 1.0) : null,
              strokeWidth: 4,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.9,
              ),
              color: scheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasScore) ...[
                Text(
                  '$score/$total',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  '$pct%',
                  style: tt.labelSmall?.copyWith(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
                Text(
                  '—',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

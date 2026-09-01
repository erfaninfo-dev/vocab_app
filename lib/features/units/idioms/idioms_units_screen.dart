import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_gradient_scaffold.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../domain/api_full_refresh.dart';
import '../../../domain/api_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'idioms_unit_card.dart';
import 'idioms_unit_progress.dart';
import 'idioms_units_constants.dart';

enum IdiomsUnitsFilter { all, notStarted, inProgress, completed }

class IdiomsUnitsScreen extends ConsumerStatefulWidget {
  const IdiomsUnitsScreen({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<IdiomsUnitsScreen> createState() => _IdiomsUnitsScreenState();
}

class _IdiomsUnitsScreenState extends ConsumerState<IdiomsUnitsScreen> {
  int? _loadingUnit;
  String _query = '';
  IdiomsUnitsFilter _filter = IdiomsUnitsFilter.all;

  Future<void> _onUnitTap(int unit) async {
    if (_loadingUnit != null) return;

    setState(() => _loadingUnit = unit);
    try {
      final sections = await ref.read(
        apiSectionsProvider((bookId: widget.bookId, unit: unit)).future,
      );

      if (!mounted) return;

      if (sections.isEmpty) {
        context.push('/books/${widget.bookId}/units/$unit/words');
      } else {
        context.push('/books/${widget.bookId}/units/$unit/sections');
      }
    } catch (_) {
      if (!mounted) return;
      final msg = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg.failedLoadSections)));
    } finally {
      if (mounted) setState(() => _loadingUnit = null);
    }
  }

  Future<void> _onRefreshUnits() async {
    await refreshAllRemoteApiData(ref);
    await ref.read(apiUnitsProvider(widget.bookId).future);
    ref.invalidate(apiAllWordsForBookProvider(widget.bookId));
  }

  List<UnitInfo> _applyFilters(
    List<UnitInfo> units,
    Map<int, IdiomsUnitProgress> progressMap,
  ) {
    var list = units;
    final q = _query.trim();
    if (q.isNotEmpty) {
      list = list.where((u) => u.matchesQuery(q)).toList();
    }

    switch (_filter) {
      case IdiomsUnitsFilter.all:
        return list;
      case IdiomsUnitsFilter.notStarted:
        return list.where((u) {
          final p = progressMap[u.unit];
          return p == null || p.isNotStarted;
        }).toList();
      case IdiomsUnitsFilter.inProgress:
        return list.where((u) {
          final p = progressMap[u.unit];
          return p != null && p.isInProgress;
        }).toList();
      case IdiomsUnitsFilter.completed:
        return list.where((u) {
          final p = progressMap[u.unit];
          return p != null && p.isCompleted;
        }).toList();
    }
  }

  Future<void> _openFilterSheet(AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<IdiomsUnitsFilter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.idiomsUnitsFilterTitle,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              for (final option in IdiomsUnitsFilter.values)
                RadioListTile<IdiomsUnitsFilter>(
                  value: option,
                  groupValue: _filter,
                  title: Text(_filterLabel(l10n, option)),
                  onChanged: (value) => Navigator.pop(ctx, value),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != _filter && mounted) {
      setState(() => _filter = picked);
    }
  }

  String _filterLabel(AppLocalizations l10n, IdiomsUnitsFilter filter) {
    switch (filter) {
      case IdiomsUnitsFilter.all:
        return l10n.idiomsUnitsFilterAll;
      case IdiomsUnitsFilter.notStarted:
        return l10n.idiomsUnitsFilterNotStarted;
      case IdiomsUnitsFilter.inProgress:
        return l10n.idiomsUnitsFilterInProgress;
      case IdiomsUnitsFilter.completed:
        return l10n.idiomsUnitsFilterCompleted;
    }
  }

  String? _bookTitle(List<Book>? books) {
    if (books == null) return null;
    for (final b in books) {
      if (b.id == widget.bookId) return b.title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final uiScale = idiomsScreenScale(screenWidth);
    double px(double design) => design * uiScale;
    final textScaler = TextScaler.linear(
      MediaQuery.textScalerOf(context).scale(1) * uiScale,
    );
    final unitsValue = ref.watch(apiUnitsProvider(widget.bookId));
    final booksValue = ref.watch(apiBooksProvider);
    ref.watch(apiAllWordsForBookProvider(widget.bookId));
    final progressMap = ref.watch(idiomsUnitProgressMapProvider(widget.bookId));
    final bookTitle = _bookTitle(booksValue.valueOrNull);

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.backToBooks,
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        (bookTitle != null && bookTitle.trim().isNotEmpty)
            ? bookTitle.trim()
            : 'Idioms For Speaking',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmarks_rounded),
          tooltip: l10n.favorites,
          onPressed: () => context.push('/favorites'),
        ),
        const SizedBox(width: 4),
      ],
    );
    final topInset = appGradientContentTopInset(
      context,
      appBar: appBar,
      extra: 12,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: AppGradientScaffold(
        appBar: appBar,
        body: RefreshIndicator(
          onRefresh: _onRefreshUnits,
          child: unitsValue.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: const [
                SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n.couldNotLoadUnitsWithError('$error'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            data: (units) {
              if (units.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: topInset),
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.noUnitsFound)),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _onRefreshUnits,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ),
                  ],
                );
              }

              final filtered = _applyFilters(units, progressMap);
              final gridPaddingH = px(16) * 2;
              final gridSpacing = px(12);
              final crossAxisCount = idiomsUnitsGridCrossAxisCount(
                viewportWidth: screenWidth,
                horizontalPadding: gridPaddingH,
                spacing: gridSpacing,
              );

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        px(16),
                        topInset,
                        px(16),
                        px(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SearchBar(
                              autoFocus: false,
                              hintText: l10n.searchUnitsHint,
                              hintStyle: const WidgetStatePropertyAll(
                                TextStyle(fontSize: 14),
                              ),
                              textStyle: const WidgetStatePropertyAll(
                                TextStyle(fontSize: 14),
                              ),
                              leading: Icon(Icons.search_rounded, size: px(22)),
                              trailing: [
                                if (_query.isNotEmpty)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _query = ''),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: px(20),
                                    ),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                          SizedBox(width: px(10)),
                          Material(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(px(14)),
                            child: InkWell(
                              onTap: () => _openFilterSheet(l10n),
                              borderRadius: BorderRadius.circular(px(14)),
                              child: SizedBox(
                                width: px(48),
                                height: px(48),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.tune_rounded, size: px(22)),
                                    if (_filter != IdiomsUnitsFilter.all)
                                      Positioned(
                                        top: px(10),
                                        right: px(10),
                                        child: Container(
                                          width: px(8),
                                          height: px(8),
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(px(20), 0, px(20), px(12)),
                      child: Text(
                        l10n.idiomsUnitsLearnHint(filtered.length),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.noMatchingUnits)),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(px(16), 0, px(16), px(24)),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: gridSpacing,
                          mainAxisSpacing: gridSpacing,
                          childAspectRatio: kIdiomsUnitCardAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final unitInfo = filtered[index];
                          final progress =
                              progressMap[unitInfo.unit] ??
                              const IdiomsUnitProgress(done: 0, total: 0);
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: IdiomsUnitCard(
                              l10n: l10n,
                              unitInfo: unitInfo,
                              progress: progress,
                              isLoading: _loadingUnit == unitInfo.unit,
                              onTap: () => _onUnitTap(unitInfo.unit),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

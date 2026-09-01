import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/unit_model.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/widgets/book_vocab_quiz_fab.dart';
import 'idioms/idioms_units_constants.dart';
import 'idioms/idioms_units_screen.dart';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key, required this.bookId});
  final int bookId;

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.bookId == kIdiomsSpeakingBookId) {
      return IdiomsUnitsScreen(bookId: widget.bookId);
    }
    return _DefaultUnitsScreen(bookId: widget.bookId);
  }
}

class _DefaultUnitsScreen extends ConsumerStatefulWidget {
  const _DefaultUnitsScreen({required this.bookId});
  final int bookId;

  @override
  ConsumerState<_DefaultUnitsScreen> createState() =>
      _DefaultUnitsScreenState();
}

class _DefaultUnitsScreenState extends ConsumerState<_DefaultUnitsScreen> {
  int? _loadingUnit;
  String _query = '';

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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitsValue = ref.watch(apiUnitsProvider(widget.bookId));
    final scheme = Theme.of(context).colorScheme;
    final showQuizFab = unitsValue.maybeWhen(
      data: (units) => units.isNotEmpty,
      orElse: () => false,
    );

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.backToBooks,
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        l10n.unitsTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
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
    final topInset = appGradientContentTopInset(context, appBar: appBar, extra: 12);

    return AppGradientScaffold(
      floatingActionButtonLocation:
          BookVocabQuizFab.floatingActionButtonLocation,
      floatingActionButton: showQuizFab
          ? BookVocabQuizFab(bookId: widget.bookId)
          : null,
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
                  const SizedBox(height: 24),
                ],
              );
            }

            final filtered = _query.trim().isEmpty
                ? units
                : units.where((u) => u.matchesQuery(_query)).toList();

            final width = MediaQuery.sizeOf(context).width;
            final crossAxisCount = width >= 1000
                ? 4
                : width >= 760
                ? 3
                : 2;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, topInset, 16, 8),
                    child: SearchBar(
                      autoFocus: false,
                      hintText: l10n.searchUnitsHint,
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            onPressed: () => setState(() => _query = ''),
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      l10n.unitsGridHint(filtered.length),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      showQuizFab
                          ? BookVocabQuizFab.scrollBottomPadding(context)
                          : 20,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final unitInfo = filtered[index];
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: _UnitTile(
                              l10n: l10n,
                              unitInfo: unitInfo,
                              delay: index * 20,
                              isLoading: _loadingUnit == unitInfo.unit,
                              onTap: () => _onUnitTap(unitInfo.unit),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            );
              },
            ),
          ),
    );
  }
}

// ─── Unit Tile ────────────────────────────────────────────────────────────────

class _UnitTile extends StatefulWidget {
  const _UnitTile({
    required this.l10n,
    required this.unitInfo,
    required this.onTap,
    required this.delay,
    required this.isLoading,
  });

  final AppLocalizations l10n;
  final UnitInfo unitInfo;
  final VoidCallback onTap;
  final int delay;
  final bool isLoading;

  @override
  State<_UnitTile> createState() => _UnitTileState();
}

class _UnitTileState extends State<_UnitTile> {
  var _show = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 80 + widget.delay), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitInfo = widget.unitInfo;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      opacity: _show ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        offset: _show ? Offset.zero : const Offset(0, 0.06),
        child: AppJellyCard(
          onTap: widget.isLoading ? null : widget.onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: Unit label (left) + Icons (right) ─────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.l10n.unitLabel(unitInfo.unit),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppJellyIconBubble(
                        color: scheme.primary,
                        size: 42,
                        child: widget.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.layers_rounded,
                                color: scheme.onPrimary,
                              ),
                      ),
                    ],
                  ),

                  // ── Center: unit details ───────────────────────────────────
                  Expanded(
                    child: Center(
                      child:
                          (unitInfo.unitDetails != null &&
                              unitInfo.unitDetails!.isNotEmpty)
                          ? Text(
                              unitInfo.unitDetails!,
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                            )
                          : Text(
                              widget.isLoading
                                  ? widget.l10n.checkingEllipsis
                                  : widget.l10n.tapToOpen,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}

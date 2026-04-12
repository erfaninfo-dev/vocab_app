import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/unit_model.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key, required this.bookId});
  final int bookId;

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  int? _loadingUnit;

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
    final api = ref.read(apiServiceProvider);
    await api.bustUnitsCache(widget.bookId);
    ref.invalidate(apiUnitsProvider(widget.bookId));
    await ref.read(apiUnitsProvider(widget.bookId).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitsValue = ref.watch(apiUnitsProvider(widget.bookId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
            icon: const Icon(Icons.quiz_rounded),
            tooltip: l10n.bookQuiz,
            onPressed: () => context.push('/books/${widget.bookId}/vocab-quiz'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded),
            tooltip: l10n.favorites,
            onPressed: () => context.push('/favorites'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.08),
              scheme.secondary.withValues(alpha: 0.04),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefreshUnits,
            child: unitsValue.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Could not load units.\n$error',
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
                    children: const [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('No units found in this dataset.'),
                        ),
                      ),
                    ],
                  );
                }

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
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        child: Text(
                          '${units.length} units · tap a card to open',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final unitInfo = units[index];
                            return Directionality(
                              textDirection: TextDirection.ltr,
                              child: _UnitTile(
                                unitInfo: unitInfo,
                                delay: index * 20,
                                isLoading: _loadingUnit == unitInfo.unit,
                                onTap: () => _onUnitTap(unitInfo.unit),
                              ),
                            );
                          },
                          childCount: units.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Unit Tile ────────────────────────────────────────────────────────────────

class _UnitTile extends StatefulWidget {
  const _UnitTile({
    required this.unitInfo,
    required this.onTap,
    required this.delay,
    required this.isLoading,
  });

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
        child: Card(
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
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
                          'Unit ${unitInfo.unit}',
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
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: scheme.primary,
                                ),
                              )
                            : Icon(Icons.layers_rounded, color: scheme.primary),
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
                              widget.isLoading ? 'Checking…' : 'Tap to open',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

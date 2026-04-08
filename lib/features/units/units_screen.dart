import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/unit_model.dart';
import '../../domain/api_providers.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load sections. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _loadingUnit = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitsValue = ref.watch(apiUnitsProvider(widget.bookId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to books',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Units',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_rounded),
            tooltip: 'Book quiz',
            onPressed: () =>
                context.push('/books/${widget.bookId}/vocab-quiz'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_rounded),
            tooltip: 'Favorites',
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
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
          child: unitsValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load units.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (units) {
              if (units.isEmpty) {
                return const Center(
                  child: Text('No units found in this dataset.'),
                );
              }

              final width = MediaQuery.sizeOf(context).width;
              final crossAxisCount = width >= 1000
                  ? 4
                  : width >= 760
                  ? 3
                  : 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Text(
                      '${units.length} units · tap a card to open',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.04,
                      ),
                      itemCount: units.length,
                      itemBuilder: (context, index) {
                        final unitInfo = units[index];
                        return _UnitTile(
                          unitInfo: unitInfo,
                          delay: index * 20,
                          isLoading: _loadingUnit == unitInfo.unit,
                          onTap: () => _onUnitTap(unitInfo.unit),
                          onQuiz: () => context.push(
                            '/books/${widget.bookId}/units/${unitInfo.unit}/quiz',
                          ),
                        );
                      },
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

// ─── Unit Tile ────────────────────────────────────────────────────────────────

class _UnitTile extends StatefulWidget {
  const _UnitTile({
    required this.unitInfo,
    required this.onTap,
    required this.delay,
    required this.isLoading,
    required this.onQuiz,
  });

  final UnitInfo unitInfo;
  final VoidCallback onTap;
  final VoidCallback onQuiz;
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
                      Text(
                        'Unit ${unitInfo.unit}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Quiz this unit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: widget.isLoading ? null : widget.onQuiz,
                        icon: Icon(
                          Icons.quiz_rounded,
                          color: scheme.primary,
                        ),
                      ),
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
                      child: (unitInfo.unitDetails != null &&
                              unitInfo.unitDetails!.isNotEmpty)
                          ? Text(
                              unitInfo.unitDetails!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            )
                          : Text(
                              widget.isLoading ? 'Checking…' : 'Tap to open',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
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

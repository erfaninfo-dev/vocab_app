import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── API MODE ──────────────────────────────────────────────────────────────────
import '../../domain/api_providers.dart';

// ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────────
// import '../../data/models/book_asset.dart';
// import '../../domain/vocabulary_providers.dart';
// ─────────────────────────────────────────────────────────────────────────────

class UnitsScreen extends ConsumerStatefulWidget {
  // ── API MODE ──────────────────────────────────────────────────────────────
  const UnitsScreen({super.key, required this.bookId});
  final int bookId;

  // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
  // const UnitsScreen({super.key, required this.assetPath});
  // final String assetPath;

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  // Which unit is currently being checked for sections (shows a loading
  // indicator on that tile while the async check runs).
  int? _loadingUnit;

  // Called when a unit tile is tapped.
  // Checks the API for sections; navigates to the sections page if any exist,
  // or directly to the words page if the unit has no sections.
  Future<void> _onUnitTap(int unit) async {
    if (_loadingUnit != null) return; // prevent double-tap during loading

    setState(() => _loadingUnit = unit);
    try {
      // ── API MODE ──────────────────────────────────────────────────────────
      final sections = await ref.read(
        apiSectionsProvider((bookId: widget.bookId, unit: unit)).future,
      );

      if (!mounted) return;

      if (sections.isEmpty) {
        // Unit has no sections → go straight to words
        context.push('/books/${widget.bookId}/units/$unit/words');
      } else {
        // Unit has sections → open the sections page
        context.push('/books/${widget.bookId}/units/$unit/sections');
      }

      // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────
      // Navigate directly to the sections screen (sections were hardcoded):
      // context.push(
      //   '/books/${Uri.encodeComponent(assetPath)}/units/$unit',
      // );
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
    // ── API MODE ──────────────────────────────────────────────────────────────
    final unitsValue = ref.watch(apiUnitsProvider(widget.bookId));
    const bookTitle = 'Units'; // title without an assetPath-derived name

    // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
    // final book = BookAsset(assetPath: assetPath);
    // final unitsValue = ref.watch(unitListProvider(assetPath));
    // final bookTitle = book.title;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to books',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          bookTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
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
                        final unit = units[index];
                        return _UnitTile(
                          unit: unit,
                          delay: index * 20,
                          isLoading: _loadingUnit == unit,
                          onTap: () => _onUnitTap(unit),
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
    required this.unit,
    required this.onTap,
    required this.delay,
    required this.isLoading,
  });

  final int unit;
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
                  const Spacer(),
                  Text(
                    'Unit ${widget.unit}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isLoading ? 'Checking…' : 'Tap to open',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── API MODE ──────────────────────────────────────────────────────────────────
import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';

// ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────────
// import '../../data/models/book_asset.dart';
// import '../../domain/vocabulary_providers.dart';
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── API MODE ──────────────────────────────────────────────────────────────
    final booksValue = ref.watch(apiBooksProvider);

    // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
    // final booksValue = ref.watch(bookCatalogProvider);
    // ─────────────────────────────────────────────────────────────────────────

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.secondary.withValues(alpha: 0.06),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: booksValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load books.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 64, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No books found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No books were returned by the server.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final width = MediaQuery.sizeOf(context).width;
              final crossAxisCount = width >= 1100
                  ? 3
                  : width >= 700
                  ? 2
                  : 1;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: _HomeHeader(
                        bookCount: books.length,
                        onSettingsTap: () => context.push('/settings'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            crossAxisCount == 1 ? 1.5 : 1.08,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _BookCard(
                          book: book,
                          index: index,
                          // ── API MODE ──────────────────────────────────────
                          onTap: () => context.push(
                            '/books/${book.id}/units',
                          ),
                          // ── LOCAL EXCEL MODE (commented out) ─────────────
                          // onTap: () => context.push(
                          //   '/books/${Uri.encodeComponent(book.assetPath)}/units',
                          // ),
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

// ─── Header ──────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.bookCount, required this.onSettingsTap});

  final int bookCount;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: scheme.surface.withValues(alpha: 0.76),
        border:
            Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Book',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$bookCount ${bookCount == 1 ? 'book' : 'books'} available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends ConsumerWidget {
  const _BookCard({
    required this.book,
    required this.index,
    required this.onTap,
  });

  // ── API MODE ──────────────────────────────────────────────────────────────
  final Book book;

  // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
  // final BookAsset book;

  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // ── API MODE ──────────────────────────────────────────────────────────────
    final unitsValue = ref.watch(apiUnitsProvider(book.id));

    // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
    // final unitsValue = ref.watch(unitListProvider(book.assetPath));

    final accents = _cardAccents(index);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accents.first.withValues(alpha: 0.18),
                accents.last.withValues(alpha: 0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accents.first.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: accents.first,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                unitsValue.when(
                  loading: () => 'Loading…',
                  error: (_, __) => 'Tap to open',
                  data: (units) =>
                      '${units.length} unit${units.length == 1 ? '' : 's'}',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              // ── API MODE: show description badge ───────────────────────────
              if ((book.description ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: accents.first,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          book.description!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── LOCAL EXCEL MODE badge (commented out) ─────────────────────
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              //   decoration: BoxDecoration(
              //     color: scheme.surface.withValues(alpha: 0.75),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.table_chart_rounded, size: 16, color: accents.first),
              //       const SizedBox(width: 8),
              //       Flexible(
              //         child: Text(
              //           book.filename,
              //           overflow: TextOverflow.ellipsis,
              //           style: Theme.of(context).textTheme.labelMedium
              //               ?.copyWith(color: scheme.onSurfaceVariant),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _cardAccents(int index) {
  const palettes = [
    [Color(0xFF4F7CFF), Color(0xFF7AB6FF)],
    [Color(0xFF7A5FFF), Color(0xFFB78DFF)],
    [Color(0xFF0EA5A4), Color(0xFF5EEAD4)],
    [Color(0xFFFF8A4C), Color(0xFFFFC27A)],
  ];
  return palettes[index % palettes.length];
}

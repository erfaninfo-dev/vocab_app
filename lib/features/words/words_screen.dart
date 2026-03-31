import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── API MODE ──────────────────────────────────────────────────────────────────
import '../../domain/api_providers.dart';

// ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────────
// import '../../domain/vocabulary_providers.dart';
// ─────────────────────────────────────────────────────────────────────────────

import 'widgets/word_card.dart';

class WordsScreen extends ConsumerStatefulWidget {
  // ── API MODE ──────────────────────────────────────────────────────────────
  const WordsScreen({
    super.key,
    required this.bookId,
    required this.unit,
    required this.section, // nullable: null means the unit has no sections
  });
  final int bookId;

  // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
  // const WordsScreen({
  //   super.key,
  //   required this.assetPath,
  //   required this.unit,
  //   required this.section,
  // });
  // final String assetPath;

  final int unit;
  final int? section;

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // ── API MODE ──────────────────────────────────────────────────────────────
    final data = ref.watch(
      apiWordsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );

    // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
    // final data = ref.watch(
    //   wordsByUnitSectionProvider((
    //     assetPath: widget.assetPath,
    //     unit: widget.unit,
    //     section: widget.section,
    //   )),
    // );

    final scheme = Theme.of(context).colorScheme;

    final appBarTitle = widget.section != null
        ? 'Unit ${widget.unit} • Section ${widget.section}'
        : 'Unit ${widget.unit}';

    // ── API MODE flashcard route ──────────────────────────────────────────────
    final flashcardsRoute = widget.section != null
        ? '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/flashcards'
        : '/books/${widget.bookId}/units/${widget.unit}/flashcards';

    // ── LOCAL EXCEL MODE flashcard route (commented out) ─────────────────────
    // final flashcardsRoute =
    //     '/books/${Uri.encodeComponent(widget.assetPath)}/units/${widget.unit}/sections/${widget.section}/flashcards';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            tooltip: 'Flashcards',
            onPressed: () => context.push(flashcardsRoute),
            icon: const Icon(Icons.style_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withValues(alpha: 0.07), scheme.surface],
          ),
        ),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Failed to load words: $error')),
          data: (words) {
            final filtered = words
                .where((word) => word.matchesQuery(_query))
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _InfoHeader(
                      unit: widget.unit,
                      section: widget.section,
                      total: words.length,
                      filtered: filtered.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SearchBar(
                      hintText: 'Search word, meaning, example...',
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
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No matching words found.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) =>
                          WordCard(entry: filtered[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filtered.length,
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

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.unit,
    required this.section,
    required this.total,
    required this.filtered,
  });

  final int unit;
  final int? section;
  final int total;
  final int filtered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = section != null
        ? 'Section $section in Unit $unit'
        : 'Unit $unit';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$filtered of $total words visible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

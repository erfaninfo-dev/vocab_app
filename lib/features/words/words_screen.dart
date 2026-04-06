import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/api_providers.dart';
import '../../data/models/vocab_entry.dart';
import 'widgets/word_card.dart';

class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({
    super.key,
    required this.bookId,
    required this.unit,
    required this.section,
  });

  final int bookId;
  final int unit;
  final int? section;

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final unitKey = (
      bookId: widget.bookId,
      unit: widget.unit,
      section: widget.section,
    );
    final unitAsync = ref.watch(apiWordsProvider(unitKey));
    final allBookAsync = ref.watch(apiAllWordsForBookProvider(widget.bookId));
    final searching = _query.trim().isNotEmpty;

    final scheme = Theme.of(context).colorScheme;

    final appBarTitle = widget.section != null
        ? 'Unit ${widget.unit} • Section ${widget.section}'
        : 'Unit ${widget.unit}';

    final flashcardsRoute = widget.section != null
        ? '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/flashcards'
        : '/books/${widget.bookId}/units/${widget.unit}/flashcards';

    final quizRoute = widget.section != null
        ? '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/quiz'
        : '/books/${widget.bookId}/units/${widget.unit}/quiz';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            tooltip: 'Quiz',
            onPressed: () => context.push(quizRoute),
            icon: const Icon(Icons.quiz_rounded),
          ),
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
        child: searching
            ? allBookAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load words: $error')),
                data: (allWords) {
                  final filtered = allWords
                      .where((e) => e.matchesWordQuery(_query))
                      .toList();
                  return _wordsScrollView(
                    displayList: filtered,
                    headerTotal: allWords.length,
                    isGlobalSearch: true,
                  );
                },
              )
            : unitAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load words: $error')),
                data: (unitWords) {
                  return _wordsScrollView(
                    displayList: unitWords,
                    headerTotal: unitWords.length,
                    isGlobalSearch: false,
                  );
                },
              ),
      ),
    );
  }

  Widget _wordsScrollView({
    required List<VocabEntry> displayList,
    required int headerTotal,
    required bool isGlobalSearch,
  }) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _InfoHeader(
              unit: widget.unit,
              section: widget.section,
              total: headerTotal,
              filtered: displayList.length,
              isGlobalSearch: isGlobalSearch,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              autoFocus: false,
              hintText: 'Search word (whole book)…',
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
        if (displayList.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No matching words found.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.separated(
              itemBuilder: (context, index) =>
                  WordCard(entry: displayList[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: displayList.length,
            ),
          ),
      ],
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.unit,
    required this.section,
    required this.total,
    required this.filtered,
    required this.isGlobalSearch,
  });

  final int unit;
  final int? section;
  final int total;
  final int filtered;
  final bool isGlobalSearch;

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
                  isGlobalSearch
                      ? '$filtered of $total matches (whole book)'
                      : '$filtered of $total words visible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1B5E20),
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

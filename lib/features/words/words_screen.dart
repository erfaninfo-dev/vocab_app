import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../l10n/app_localizations.dart';
import '../../core/sync/pending_word_updates.dart';
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

  Future<void> _refresh() async {
    await syncPendingImportantUpdates(ref);
    ref.invalidate(apiAllWordsForBookProvider(widget.bookId));
    ref.invalidate(
      apiWordsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );
    // Wait for at least one request so RefreshIndicator doesn't instantly stop.
    try {
      await ref.read(apiAllWordsForBookProvider(widget.bookId).future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        ? l10n.wordsUnitSection(widget.unit, widget.section!)
        : l10n.wordsUnitOnly(widget.unit);

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
            tooltip: l10n.tooltipQuiz,
            onPressed: () => context.push(quizRoute),
            icon: const Icon(Icons.quiz_rounded),
          ),
          IconButton(
            tooltip: l10n.tooltipFlashcards,
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
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: searching
              ? allBookAsync.when(
                  loading: () => ListView(
                    children: const [
                      SizedBox(height: 220),
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                  error: (error, _) => ListView(
                    children: [
                      const SizedBox(height: 220),
                      Center(child: Text(userFriendlyErrorMessage(error, l10n))),
                    ],
                  ),
                  data: (allWords) {
                    final filtered = allWords
                        .where((e) => e.matchesWordQuery(_query))
                        .toList();
                    return _wordsScrollView(
                      l10n: l10n,
                      displayList: filtered,
                      headerTotal: allWords.length,
                      isGlobalSearch: true,
                    );
                  },
                )
              : unitAsync.when(
                  loading: () => ListView(
                    children: const [
                      SizedBox(height: 220),
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                  error: (error, _) => ListView(
                    children: [
                      const SizedBox(height: 220),
                      Center(child: Text(userFriendlyErrorMessage(error, l10n))),
                    ],
                  ),
                  data: (unitWords) {
                    return _wordsScrollView(
                      l10n: l10n,
                      displayList: unitWords,
                      headerTotal: unitWords.length,
                      isGlobalSearch: false,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _wordsScrollView({
    required AppLocalizations l10n,
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
              hintText: l10n.searchWordWholeBook,
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
          SliverFillRemaining(
            child: Center(child: Text(l10n.noMatchingWords)),
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
    final l10n = AppLocalizations.of(context)!;
    final label = section != null
        ? l10n.sectionInUnit(section!, unit)
        : l10n.unitLabel(unit);

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
                      ? l10n.matchesWholeBook(filtered, total)
                      : l10n.wordsVisible(filtered, total),
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

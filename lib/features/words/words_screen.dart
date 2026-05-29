import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tts/tts_service.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../unit_samples/sample_tts_player.dart';
import '../unit_samples/unit_samples_screen.dart';
import 'important_words_controller.dart';
import 'word_preferences_controller.dart';
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
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    ref.read(sampleTtsSessionProvider.notifier).state = null;
    super.dispose();
  }

  Future<void> _refresh() async {
    final api = ref.read(apiServiceProvider);
    await refreshAllRemoteApiData(ref);
    if (api.authToken != null && api.authToken!.isNotEmpty) {
      await ref.read(wordPreferencesProvider.notifier).pullFromServer(api);
      await ref.read(importantWordsProvider.notifier).pullFromServer(api);
    }
    try {
      await ref.read(apiAllWordsForBookProvider(widget.bookId).future);
      await ref.read(
        apiWordsProvider((
          bookId: widget.bookId,
          unit: widget.unit,
          section: widget.section,
        )).future,
      );
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
    final samplesAsync = ref.watch(
      apiUnitSamplesProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );

    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appBarTitle = widget.section != null
        ? l10n.wordsUnitSection(widget.unit, widget.section!)
        : l10n.wordsUnitOnly(widget.unit);

    final flashcardsRoute = widget.section != null
        ? '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/flashcards'
        : '/books/${widget.bookId}/units/${widget.unit}/flashcards';

    final quizRoute = widget.section != null
        ? '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/quiz'
        : '/books/${widget.bookId}/units/${widget.unit}/quiz';

    final hasSamples = samplesAsync.valueOrNull?.isNotEmpty ?? false;

    Widget wordsBody() {
      return RefreshIndicator(
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
      );
    }

    final appBar = AppBar(
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
      bottom: !hasSamples
          ? null
          : TabBar(
              isScrollable: false,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book_rounded),
                        const SizedBox(width: 8),
                        Text(l10n.wordsTabLabel, maxLines: 1, softWrap: false),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_rounded),
                        const SizedBox(width: 8),
                        Text(
                          l10n.samplesTabLabel,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary.withValues(alpha: 0.07), scheme.surface],
        ),
      ),
      child: hasSamples
          ? TabBarView(
              children: [
                wordsBody(),
                UnitSamplesEmbedded(
                  bookId: widget.bookId,
                  unit: widget.unit,
                  section: widget.section,
                ),
              ],
            )
          : wordsBody(),
    );

    final scaffold = Scaffold(appBar: appBar, body: content);
    return hasSamples
        ? DefaultTabController(
            length: 2,
            child: _WordsTabTtsSilencer(child: scaffold),
          )
        : scaffold;
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
              onChanged: (value) {
                setState(() => _query = value);
                if (value.trim().isEmpty) return;
                TabController? tabs;
                try {
                  tabs = DefaultTabController.of(context);
                } catch (_) {
                  tabs = null;
                }
                if (tabs != null && tabs.index != 0) {
                  tabs.animateTo(0);
                }
              },
            ),
          ),
        ),
        if (displayList.isEmpty)
          SliverFillRemaining(child: Center(child: Text(l10n.noMatchingWords)))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.separated(
              itemBuilder: (context, index) =>
                  WordCard(entry: displayList[index], number: index + 1),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: displayList.length,
            ),
          ),
      ],
    );
  }
}

class _WordsTabTtsSilencer extends ConsumerStatefulWidget {
  const _WordsTabTtsSilencer({required this.child});

  final Widget child;

  @override
  ConsumerState<_WordsTabTtsSilencer> createState() =>
      _WordsTabTtsSilencerState();
}

class _WordsTabTtsSilencerState extends ConsumerState<_WordsTabTtsSilencer> {
  TabController? _tabs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DefaultTabController.maybeOf(context);
    if (next == _tabs) return;
    _tabs?.removeListener(_onTabChanged);
    _tabs = next;
    _tabs?.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs == null || _tabs!.indexIsChanging) return;
    if (_tabs!.index == 0) {
      unawaited(stopSampleTts(ref));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

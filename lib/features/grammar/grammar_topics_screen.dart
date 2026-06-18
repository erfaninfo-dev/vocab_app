import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/admin_story.dart';
import '../../data/models/grammar_book.dart';
import '../../data/models/grammar_question.dart';
import '../../data/models/grammar_topic_summary.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../stories/story_providers.dart';

/// Set to `true` to show the Grammar League banner above books again.
const bool kGrammarShowLeagueBannerOnTopicsScreen = true;
const bool kGrammarShowBooksOnTopicsScreen = false;

class GrammarTopicsScreen extends ConsumerStatefulWidget {
  const GrammarTopicsScreen({super.key});

  @override
  ConsumerState<GrammarTopicsScreen> createState() =>
      _GrammarTopicsScreenState();
}

class _GrammarTopicsScreenState extends ConsumerState<GrammarTopicsScreen> {
  final Set<String> _selected = {};
  final Set<String> _adminNewToggleVisible = {};
  final Set<String> _adminNewToggleFadingOut = {};
  final Set<String> _savingAdminNewTopics = {};
  bool _creatingGrammarStories = false;

  void _toggleTopic(String topic) {
    setState(() {
      if (_selected.contains(topic)) {
        _selected.remove(topic);
      } else {
        _selected.add(topic);
      }
    });
  }

  int _totalQuestionsInBank(List<GrammarTopicSummary> all) {
    var n = 0;
    for (final t in all) {
      if (_selected.contains(t.topic)) {
        n += t.questionCount;
      }
    }
    return n;
  }

  Future<void> _startPractice() async {
    if (_selected.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final topicsData = ref.read(apiGrammarTopicsProvider).valueOrNull;
    if (topicsData == null) return;

    final bank = _totalQuestionsInBank(topicsData);
    if (bank <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.grammarNoQuestions)));
      return;
    }

    final minRequired = grammarQuizMinQuestionsForTopics(_selected.length);
    if (bank < minRequired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.grammarNotEnoughInBank(minRequired))),
      );
      return;
    }

    final cap = math.min(bank, kGrammarQuizSessionSize);
    if (!mounted) return;

    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _GrammarQuestionCountSheet(
        maxQuestions: cap,
        selectedTopicCount: _selected.length,
      ),
    );

    if (count == null || !mounted) return;

    final list = _selected.toList()..sort();
    final parts = <String>[
      ...list.map((t) => 'topic=${Uri.encodeQueryComponent(t)}'),
      'count=$count',
    ];
    await context.push('/grammar/practice?${parts.join('&')}');
    if (!mounted) return;
    setState(_selected.clear);
  }

  bool _canCreateStoryFromQuestion(GrammarQuestion q) {
    final question = (q.questionText ?? '').trim();
    final correct = (q.correctAnswer ?? '').trim();
    final options = q.nonEmptyOptionKeys().length;
    return question.isNotEmpty &&
        options >= 2 &&
        correct.isNotEmpty &&
        (q.optionByKey(correct)?.trim().isNotEmpty ?? false);
  }

  Future<void> _createStoriesFromSelectedTopics() async {
    if (_creatingGrammarStories) return;
    final topics = _selected.map((topic) => topic.trim()).where((topic) {
      return topic.isNotEmpty;
    }).toList();
    if (topics.isEmpty) return;
    setState(() => _creatingGrammarStories = true);
    try {
      final api = ref.read(apiServiceProvider);
      final random = math.Random();
      final shuffledTopics = [...topics]..shuffle(random);
      var createdCount = 0;
      for (final topic in shuffledTopics) {
        final questions = await api.fetchGrammarQuestions(topic);
        final validQuestions = questions
            .where(_canCreateStoryFromQuestion)
            .toList();
        if (validQuestions.isEmpty) continue;
        final q = validQuestions[random.nextInt(validQuestions.length)];
        final clientRequestId =
            'grammar-topic-${q.id}-${DateTime.now().microsecondsSinceEpoch}';
        await api.createGrammarStoryFromQuestion(
          clientRequestId: clientRequestId,
          questionId: q.id,
        );
        createdCount++;
      }
      if (createdCount < 1) {
        throw Exception('No valid grammar questions found for story');
      }
      ref.invalidate(visibleStoriesProvider);
      ref.invalidate(adminStoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$createdCount grammar stories created')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingGrammarStories = false);
      }
    }
  }

  Future<void> _onRefreshTopics() async {
    await refreshAllRemoteApiData(ref);
    if (kGrammarShowBooksOnTopicsScreen) {
      await ref.read(apiServiceProvider).bustGrammarBooksCache();
      ref.invalidate(apiGrammarBooksProvider);
    }
    await Future.wait([
      ref.read(apiGrammarTopicsProvider.future),
      if (kGrammarShowBooksOnTopicsScreen)
        ref.read(apiGrammarBooksProvider.future),
    ]);
  }

  void _toggleAdminNewControl(String topic) {
    setState(() {
      if (_adminNewToggleVisible.contains(topic)) {
        _adminNewToggleVisible.remove(topic);
      } else {
        _adminNewToggleVisible.add(topic);
      }
    });
  }

  Future<void> _setTopicNewBadge({
    required String topic,
    required bool isNew,
  }) async {
    if (_savingAdminNewTopics.contains(topic)) return;
    setState(() => _savingAdminNewTopics.add(topic));
    try {
      final api = ref.read(apiServiceProvider);
      await api.setGrammarTopicNew(topic: topic, isNew: isNew);
      ref.invalidate(apiGrammarTopicsProvider);
      await ref.read(apiGrammarTopicsProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew ? '“$topic” marked as New' : '“$topic” New badge removed',
          ),
        ),
      );
      _fadeOutAdminNewControl(topic);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAdminNewTopics.remove(topic));
      }
    }
  }

  void _fadeOutAdminNewControl(String topic) {
    if (!_adminNewToggleVisible.contains(topic)) return;
    setState(() => _adminNewToggleFadingOut.add(topic));
    Future<void>.delayed(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      setState(() {
        _adminNewToggleFadingOut.remove(topic);
        _adminNewToggleVisible.remove(topic);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(apiGrammarTopicsProvider);
    final booksAsync = kGrammarShowBooksOnTopicsScreen
        ? ref.watch(apiGrammarBooksProvider)
        : null;
    final scheme = Theme.of(context).colorScheme;
    final session = ref.watch(authProvider).valueOrNull;
    final isAdmin = session?.user.isAdmin == true;
    final canCreateGrammarStories = isAdmin;
    final grammarStories =
        ref
            .watch(visibleStoriesProvider)
            .valueOrNull
            ?.where((story) => story.hasGrammarGame)
            .toList() ??
        const [];

    return PopScope(
      canPop: _selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selected.isNotEmpty) {
          setState(_selected.clear);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemOverlayStyleFor(context),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.back,
              onPressed: () {
                if (_selected.isNotEmpty) {
                  setState(_selected.clear);
                  return;
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: canCreateGrammarStories
                ? _GrammarStoryToolbarTitle(
                    selectedCount: _selected.length,
                    loading: _creatingGrammarStories,
                    grammarStories: grammarStories,
                    onAddTap: _selected.isEmpty
                        ? null
                        : _createStoriesFromSelectedTopics,
                  )
                : grammarStories.isNotEmpty
                ? _GrammarChallengeOnlyToolbarTitle(stories: grammarStories)
                : Text(
                    l10n.grammarPracticeAppBar,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
            centerTitle: false,
            backgroundColor: scheme.surface.withValues(alpha: 0.85),
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: AppTheme.systemOverlayStyleFor(context),
            actions: [
              if (_selected.isNotEmpty)
                IconButton(
                  tooltip: l10n.grammarTooltipUnselectAll,
                  onPressed: () => setState(_selected.clear),
                  icon: const Icon(Icons.close_rounded),
                ),
              IconButton(
                tooltip: l10n.grammarTooltipResults,
                onPressed: () => context.push('/grammar/results'),
                icon: const Icon(Icons.history_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: DecoratedBox(
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
                  child: RefreshIndicator(
                    onRefresh: _onRefreshTopics,
                    child: async.when(
                      loading: () => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 400,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      ),
                      error: (_, __) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                l10n.grammarCouldNotLoadTopics,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      data: (topics) {
                        final topInset =
                            MediaQuery.paddingOf(context).top +
                            kToolbarHeight +
                            12;
                        final practiceTopPadding =
                            kGrammarShowBooksOnTopicsScreen
                            ? 0.0
                            : kGrammarShowLeagueBannerOnTopicsScreen
                            ? 16.0
                            : topInset;
                        const showPracticeByTopicHeader =
                            kGrammarShowBooksOnTopicsScreen;
                        final topicsTopPadding = showPracticeByTopicHeader
                            ? 0.0
                            : practiceTopPadding;

                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            if (kGrammarShowLeagueBannerOnTopicsScreen)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  topInset,
                                  16,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _GrammarLeagueEntryCard(
                                    onTap: () =>
                                        context.push('/league?type=grammar'),
                                  ),
                                ),
                              ),
                            if (kGrammarShowBooksOnTopicsScreen)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  kGrammarShowLeagueBannerOnTopicsScreen
                                      ? 14
                                      : topInset,
                                  16,
                                  16,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _GrammarBooksSection(
                                    booksAsync: booksAsync!,
                                    onBookTap: (book) => context.push(
                                      '/grammar/books/${book.id}/units',
                                    ),
                                  ),
                                ),
                              ),
                            if (showPracticeByTopicHeader)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  practiceTopPadding,
                                  16,
                                  10,
                                ),
                                sliver: const SliverToBoxAdapter(
                                  child: _GrammarSectionHeader(
                                    title: 'Practice by Topic',
                                    subtitle:
                                        'Your original grammar topics stay here, separate from books.',
                                  ),
                                ),
                              ),
                            if (topics.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    24,
                                    topicsTopPadding + 24,
                                    24,
                                    24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.grammarNoTopicsEmpty,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  topicsTopPadding,
                                  16,
                                  16,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: topics.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final t = topics[index];
                                    final sel = _selected.contains(t.topic);
                                    final showAdminNewToggle =
                                        isAdmin &&
                                        (_adminNewToggleVisible.contains(
                                              t.topic,
                                            ) ||
                                            _adminNewToggleFadingOut.contains(
                                              t.topic,
                                            ));
                                    return Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: _TopicCard(
                                        title: t.topic,
                                        questionCount: t.questionCount,
                                        index: index,
                                        selected: sel,
                                        showNewBadge: t.isNew,
                                        showAdminNewToggle: showAdminNewToggle,
                                        adminNewFadingOut:
                                            _adminNewToggleFadingOut.contains(
                                              t.topic,
                                            ),
                                        adminNewChecked: t.isNew,
                                        adminNewSaving: _savingAdminNewTopics
                                            .contains(t.topic),
                                        onTap: () => _toggleTopic(t.topic),
                                        onLongPress: isAdmin
                                            ? () => _toggleAdminNewControl(
                                                t.topic,
                                              )
                                            : null,
                                        onAdminNewToggle: showAdminNewToggle
                                            ? (value) => _setTopicNewBadge(
                                                topic: t.topic,
                                                isNew: value,
                                              )
                                            : null,
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
              ),
              SafeArea(
                top: false,
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.98),
                  elevation: 6,
                  shadowColor: Colors.black26,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : _startPractice,
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      label: Text(
                        _selected.isEmpty
                            ? l10n.grammarSelectTopicsCta
                            : l10n.grammarContinueTopics(_selected.length),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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

class _GrammarLeagueEntryCard extends StatelessWidget {
  const _GrammarLeagueEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00C6FF), Color(0xFF3461FF), Color(0xFF6A5CFF)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3461FF).withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grammar League',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Practice scores and rankings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF3461FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarBooksSection extends StatelessWidget {
  const _GrammarBooksSection({
    required this.booksAsync,
    required this.onBookTap,
  });

  final AsyncValue<List<GrammarBook>> booksAsync;
  final ValueChanged<GrammarBook> onBookTap;

  @override
  Widget build(BuildContext context) {
    return booksAsync.when(
      loading: () => const _GrammarBooksLoadingCard(),
      error: (error, _) => _GrammarBooksEmptyCard(
        message: 'Could not load grammar books. Pull down to refresh.\n$error',
      ),
      data: (books) {
        if (books.isEmpty) {
          return const _GrammarBooksEmptyCard(
            message: 'No grammar books available yet.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _GrammarSectionHeader(
              title: 'Grammar Books',
              subtitle:
                  'Book lessons are separate from the original topic practice.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return SizedBox(
                    width: 280,
                    child: _GrammarBookCard(
                      book: book,
                      index: index,
                      onTap: () => onBookTap(book),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GrammarBooksLoadingCard extends StatelessWidget {
  const _GrammarBooksLoadingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _GrammarBooksEmptyCard extends StatelessWidget {
  const _GrammarBooksEmptyCard({
    this.message = 'No grammar books available yet.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GrammarSectionHeader(
          title: 'Grammar Books',
          subtitle:
              'Book lessons are separate from the original topic practice.',
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrammarSectionHeader extends StatelessWidget {
  const _GrammarSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

bool _grammarBookHasContent(GrammarBook book) => book.unitCount > 0;

class _GrammarBookCard extends StatelessWidget {
  const _GrammarBookCard({
    required this.book,
    required this.index,
    required this.onTap,
  });

  final GrammarBook book;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accents = _cardAccents(index + 2);
    final level = book.level?.trim();
    final description = book.description?.trim();
    final hasContent = _grammarBookHasContent(book);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasContent ? onTap : null,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasContent
                  ? [
                      accents.first.withValues(alpha: 0.86),
                      accents.last.withValues(alpha: 0.72),
                    ]
                  : [
                      accents.first.withValues(alpha: 0.42),
                      accents.last.withValues(alpha: 0.28),
                    ],
            ),
            border: hasContent
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
            boxShadow: [
              BoxShadow(
                color: accents.first.withValues(
                  alpha: hasContent ? 0.20 : 0.10,
                ),
                blurRadius: hasContent ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Icon(
                  hasContent
                      ? Icons.auto_stories_rounded
                      : Icons.hourglass_empty_rounded,
                  size: 112,
                  color: Colors.white.withValues(
                    alpha: hasContent ? 0.12 : 0.16,
                  ),
                ),
              ),
              if (!hasContent)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            level == null || level.isEmpty
                                ? 'Grammar Book'
                                : level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          hasContent
                              ? Icons.chevron_right_rounded
                              : Icons.hourglass_top_rounded,
                          color: Colors.white.withValues(
                            alpha: hasContent ? 1 : 0.82,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (hasContent)
                      Wrap(
                        spacing: 8,
                        children: [
                          _GrammarBookStat(
                            icon: Icons.menu_book_rounded,
                            label: '${book.unitCount} units',
                          ),
                          _GrammarBookStat(
                            icon: Icons.quiz_rounded,
                            label: '${book.questionCount} Qs',
                          ),
                        ],
                      )
                    else
                      const _GrammarBookSoonBadge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrammarBookSoonBadge extends StatefulWidget {
  const _GrammarBookSoonBadge();

  @override
  State<_GrammarBookSoonBadge> createState() => _GrammarBookSoonBadgeState();
}

class _GrammarBookSoonBadgeState extends State<_GrammarBookSoonBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 7),
            Text(
              'Soon...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarBookStat extends StatelessWidget {
  const _GrammarBookStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarStoryToolbarTitle extends StatelessWidget {
  const _GrammarStoryToolbarTitle({
    required this.selectedCount,
    required this.loading,
    required this.grammarStories,
    required this.onAddTap,
  });

  final int selectedCount;
  final bool loading;
  final List<StoryItem> grammarStories;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GrammarStoryAddToolbarButton(
            selectedCount: selectedCount,
            loading: loading,
            onTap: onAddTap,
          ),
          if (grammarStories.isNotEmpty) ...[
            const SizedBox(width: 8),
            _GrammarChallengeToolbarRing(stories: grammarStories),
            const SizedBox(width: 6),
            const Text(
              'Challenge',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrammarChallengeOnlyToolbarTitle extends StatelessWidget {
  const _GrammarChallengeOnlyToolbarTitle({required this.stories});

  final List<StoryItem> stories;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GrammarChallengeToolbarRing(stories: stories),
          const SizedBox(width: 8),
          const Text(
            'Grammar Challenge',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GrammarStoryAddToolbarButton extends StatelessWidget {
  const _GrammarStoryAddToolbarButton({
    required this.selectedCount,
    required this.loading,
    required this.onTap,
  });

  final int selectedCount;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null && !loading;
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: selectedCount > 0
            ? 'Create $selectedCount grammar stories'
            : 'Select topics first',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled || loading ? 1 : 0.44,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF58529),
                          Color(0xFFDD2A7B),
                          Color(0xFF8134AF),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFDD2A7B,
                          ).withValues(alpha: 0.26),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.auto_stories_rounded,
                                  color: scheme.onSurface,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                  if (!loading)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1306C),
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 14,
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

class _GrammarChallengeToolbarRing extends StatelessWidget {
  const _GrammarChallengeToolbarRing({required this.stories});

  final List<StoryItem> stories;

  @override
  Widget build(BuildContext context) {
    final first = stories.first;
    final hasUnseen = stories.any((story) => !story.seen);
    final count = stories.length;
    return Tooltip(
      message: 'Grammar challenge',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            context.push('/stories/viewer?storyId=${first.id}&scope=grammar'),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasUnseen
                      ? const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color(0xFF00C6FF),
                            Color(0xFF7F00FF),
                            Color(0xFFE100FF),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.outlineVariant,
                            Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.7),
                          ],
                        ),
                  boxShadow: [
                    if (hasUnseen)
                      BoxShadow(
                        color: const Color(0xFF7F00FF).withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 23,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -1,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (count > 1)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1306C),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
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

/// Bottom sheet: pick how many questions in this session (clamped to bank size).
class _GrammarQuestionCountSheet extends StatefulWidget {
  const _GrammarQuestionCountSheet({
    required this.maxQuestions,
    required this.selectedTopicCount,
  });

  final int maxQuestions;
  final int selectedTopicCount;

  @override
  State<_GrammarQuestionCountSheet> createState() =>
      _GrammarQuestionCountSheetState();
}

class _GrammarQuestionCountSheetState
    extends State<_GrammarQuestionCountSheet> {
  late int _count;

  int get _effectiveMin {
    final minQ = grammarQuizMinQuestionsForTopics(widget.selectedTopicCount);
    return math.min(minQ, widget.maxQuestions);
  }

  @override
  void initState() {
    super.initState();
    final lo = _effectiveMin;
    final def = math.min(kGrammarQuizDefaultQuestionCount, widget.maxQuestions);
    _count = def.clamp(lo, widget.maxQuestions);
  }

  void _setCount(int v) {
    final c = v.clamp(_effectiveMin, widget.maxQuestions);
    setState(() => _count = c);
  }

  List<int> get _quickPicks {
    const presets = [5, 10, 15, 20, 25, 30, 40, 50, 100];
    final set = <int>{};
    final lo = _effectiveMin;
    final hi = widget.maxQuestions;
    for (final p in presets) {
      if (p >= lo && p <= hi) {
        set.add(p);
      }
    }
    set.add(hi);
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final single = widget.selectedTopicCount == 1;
    final hint = single
        ? l10n.grammarSheetHintSingleTopic
        : l10n.grammarSheetHintMultiTopic;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.grammarSheetSessionTitle,
                textAlign: TextAlign.center,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.grammarSheetUpToInBank(widget.maxQuestions),
                textAlign: TextAlign.center,
                style: tt.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.grammarSheetMinSession(
                  _effectiveMin,
                  kGrammarQuizMinBaseQuestions,
                ),
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_count',
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.grammarQuestionNoun(_count),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _count.toDouble(),
                min: _effectiveMin.toDouble(),
                max: widget.maxQuestions.toDouble(),
                divisions: widget.maxQuestions > _effectiveMin
                    ? widget.maxQuestions - _effectiveMin
                    : null,
                label: '$_count',
                onChanged: (v) => _setCount(v.round()),
              ),
              Text(
                l10n.grammarSheetQuickPick,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final n in _quickPicks)
                    FilterChip(
                      label: Text('$n'),
                      selected: _count == n,
                      onSelected: (_) => _setCount(n),
                      showCheckmark: false,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_count),
                      child: Text(l10n.startQuiz),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Same accent rotation as Home book cards ─────────────────────────────────

List<Color> _cardAccents(int index) {
  const colors = [
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];
  return [colors[index % colors.length], colors[(index + 1) % colors.length]];
}

class _AdminNewToggleChip extends StatelessWidget {
  const _AdminNewToggleChip({
    required this.checked,
    required this.saving,
    required this.fadingOut,
    required this.onToggle,
    required this.scheme,
    required this.textTheme,
  });

  final bool checked;
  final bool saving;
  final bool fadingOut;
  final ValueChanged<bool>? onToggle;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: saving || fadingOut ? null : () => onToggle?.call(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: checked
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.55),
            width: checked ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            else
              Icon(
                checked
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: checked ? scheme.primary : scheme.onSurfaceVariant,
              ),
            const SizedBox(width: 4),
            Text(
              'New',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: checked ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.questionCount,
    required this.index,
    required this.selected,
    required this.showNewBadge,
    required this.onTap,
    this.showAdminNewToggle = false,
    this.adminNewFadingOut = false,
    this.adminNewChecked = false,
    this.adminNewSaving = false,
    this.onLongPress,
    this.onAdminNewToggle,
  });

  final String title;
  final int questionCount;
  final int index;
  final bool selected;
  final bool showNewBadge;
  final bool showAdminNewToggle;
  final bool adminNewFadingOut;
  final bool adminNewChecked;
  final bool adminNewSaving;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onAdminNewToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = _cardAccents(index);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accents.first.withValues(alpha: 0.20),
                accents.last.withValues(alpha: 0.08),
                scheme.surface.withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.45),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: showAdminNewToggle ? 8 : 30,
                        top: 4,
                        bottom: 36,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: accents.first.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.rule_rounded,
                                color: accents.first,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (showAdminNewToggle) ...[
                              const SizedBox(width: 10),
                              AnimatedOpacity(
                                opacity: adminNewFadingOut ? 0 : 1,
                                duration: const Duration(milliseconds: 480),
                                curve: Curves.easeOut,
                                child: _AdminNewToggleChip(
                                  checked: adminNewChecked,
                                  saving: adminNewSaving,
                                  fadingOut: adminNewFadingOut,
                                  onToggle: onAdminNewToggle,
                                  scheme: scheme,
                                  textTheme: textTheme,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!showAdminNewToggle)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.arrow_outward_rounded,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$questionCount question${questionCount == 1 ? '' : 's'}',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (showNewBadge)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD166),
                              Color(0xFFFF6B6B),
                              Color(0xFF9B5DE5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: scheme.surface.withValues(alpha: 0.92),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
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

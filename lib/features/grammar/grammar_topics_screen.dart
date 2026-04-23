import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/grammar_topic_summary.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

class GrammarTopicsScreen extends ConsumerStatefulWidget {
  const GrammarTopicsScreen({super.key});

  @override
  ConsumerState<GrammarTopicsScreen> createState() =>
      _GrammarTopicsScreenState();
}

class _GrammarTopicsScreenState extends ConsumerState<GrammarTopicsScreen> {
  final Set<String> _selected = {};

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.grammarNoQuestions)),
      );
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

    final cap = min(bank, kGrammarQuizSessionSize);
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

  Future<void> _onRefreshTopics() async {
    await refreshAllRemoteApiData(ref);
    await ref.read(apiGrammarTopicsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(apiGrammarTopicsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.back,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          l10n.grammarPracticeAppBar,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: scheme.surface.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
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
            icon: const Icon(Icons.emoji_events_rounded),
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
                    if (topics.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                l10n.grammarNoTopicsEmpty,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final topInset =
                        MediaQuery.paddingOf(context).top + kToolbarHeight + 12;

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, topInset, 16, 16),
                        sliver: SliverList.separated(
                          itemCount: topics.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final t = topics[index];
                            final sel = _selected.contains(t.topic);
                            return Directionality(
                              textDirection: TextDirection.ltr,
                              child: _TopicCard(
                                title: t.topic,
                                questionCount: t.questionCount,
                                index: index,
                                selected: sel,
                                onTap: () => _toggleTopic(t.topic),
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

class _GrammarQuestionCountSheetState extends State<_GrammarQuestionCountSheet> {
  late int _count;

  int get _effectiveMin {
    final minQ = grammarQuizMinQuestionsForTopics(widget.selectedTopicCount);
    return min(minQ, widget.maxQuestions);
  }

  @override
  void initState() {
    super.initState();
    final lo = _effectiveMin;
    final def = min(kGrammarQuizDefaultQuestionCount, widget.maxQuestions);
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
                        onPressed: () =>
                            Navigator.of(context).pop(_count),
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
  return [
    colors[index % colors.length],
    colors[(index + 1) % colors.length],
  ];
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.questionCount,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int questionCount;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = _cardAccents(index);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                      padding: const EdgeInsets.only(right: 30, top: 4, bottom: 36),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.arrow_outward_rounded,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

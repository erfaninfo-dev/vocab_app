import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/api_providers.dart';

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

  void _startPractice() {
    if (_selected.isEmpty) return;
    final list = _selected.toList()..sort();
    final q = list.map((t) => 'topic=${Uri.encodeQueryComponent(t)}').join('&');
    context.push('/grammar/practice?$q');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apiGrammarTopicsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Grammar practice'),
        backgroundColor: scheme.surface.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Results',
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
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'دریافت لیست گرامر انجام نشد. لطفاً دوباره تلاش کنید',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (topics) {
                  if (topics.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No grammar topics yet.\n'
                          'Add rows to your questions table (column content = topic name).',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  final topInset =
                      MediaQuery.paddingOf(context).top + kToolbarHeight + 12;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, topInset, 20, 8),
                          child: Text(
                            'Select one or more topics. Each session uses 20 random questions.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList.separated(
                          itemCount: topics.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final t = topics[index];
                            final sel = _selected.contains(t.topic);
                            return _TopicCard(
                              title: t.topic,
                              questionCount: t.questionCount,
                              index: index,
                              selected: sel,
                              onTap: () => _toggleTopic(t.topic),
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
                        ? 'Select topics to start'
                        : 'Start (${_selected.length} topic${_selected.length == 1 ? '' : 's'})',
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

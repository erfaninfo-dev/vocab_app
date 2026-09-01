import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/speaking_model_summary.dart';
import '../../data/models/speaking_topic.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'speaking_constants.dart';
import 'speaking_model_question_row_card.dart';
import 'speaking_topic_card.dart';

class SpeakingPart1TopicsScreen extends ConsumerStatefulWidget {
  const SpeakingPart1TopicsScreen({super.key});

  @override
  ConsumerState<SpeakingPart1TopicsScreen> createState() =>
      _SpeakingPart1TopicsScreenState();
}

class _SpeakingPart1TopicsScreenState
    extends ConsumerState<SpeakingPart1TopicsScreen> {
  String _query = '';
  SpeakingPart1BrowseMode _mode = SpeakingPart1BrowseMode.topics;

  Future<void> _onRefresh() async {
    await refreshAllRemoteApiData(ref);
    if (_mode == SpeakingPart1BrowseMode.topics) {
      await ref.read(apiSpeakingTopicsProvider(kSpeakingPart1).future);
    } else {
      await ref.read(apiSpeakingModelQuestionsProvider(kSpeakingPart1).future);
    }
  }

  List<SpeakingTopic> _filterTopics(List<SpeakingTopic> topics) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return topics;
    return topics
        .where((t) => t.title.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<SpeakingModelSummary> _filterModels(List<SpeakingModelSummary> models) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return models;
    return models.where((m) {
      final haystack =
          '${m.modelNumber} ${m.title} ${m.formula} ${m.template}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final uiScale = speakingScreenScale(screenWidth);
    double px(double design) => design * uiScale;
    final topicsValue = ref.watch(apiSpeakingTopicsProvider(kSpeakingPart1));
    final modelsValue = ref.watch(
      apiSpeakingModelQuestionsProvider(kSpeakingPart1),
    );

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.back,
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        l10n.speakingPart1Title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      centerTitle: false,
    );
    final topInset = appGradientContentTopInset(
      context,
      appBar: appBar,
      extra: 12,
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppGradientScaffold(
        appBar: appBar,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(px(16), topInset, px(16), px(12)),
                  child: _SpeakingPart1HeroBanner(l10n: l10n),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(px(16), 0, px(16), px(10)),
                  child: _SpeakingBrowseModeSwitcher(
                    mode: _mode,
                    onChanged: (mode) => setState(() {
                      _mode = mode;
                      _query = '';
                    }),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(px(16), 0, px(16), px(10)),
                  child: SearchBar(
                    autoFocus: false,
                    hintText: _mode == SpeakingPart1BrowseMode.topics
                        ? l10n.speakingSearchTopicsHint
                        : l10n.speakingSearchModelsHint,
                    hintStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 14),
                    ),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 14),
                    ),
                    leading: Icon(Icons.search_rounded, size: px(22)),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() => _query = ''),
                          icon: Icon(Icons.close_rounded, size: px(20)),
                        ),
                    ],
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
              if (_mode == SpeakingPart1BrowseMode.topics)
                ..._buildTopicsSlivers(
                  context,
                  l10n: l10n,
                  scheme: scheme,
                  screenWidth: screenWidth,
                  px: px,
                  topicsValue: topicsValue,
                )
              else
                ..._buildModelsSlivers(
                  context,
                  l10n: l10n,
                  scheme: scheme,
                  px: px,
                  modelsValue: modelsValue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTopicsSlivers(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required double screenWidth,
    required double Function(double) px,
    required AsyncValue<List<SpeakingTopic>> topicsValue,
  }) {
    return topicsValue.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  l10n.speakingTopicsLoadError('$error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (topics) {
        final filtered = _filterTopics(topics);
        final gridPaddingH = px(16) * 2;
        final gridSpacing = px(12);
        final crossAxisCount = speakingTopicsGridCrossAxisCount(
          viewportWidth: screenWidth,
          horizontalPadding: gridPaddingH,
          spacing: gridSpacing,
        );

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(px(20), 0, px(20), px(12)),
              child: Text(
                l10n.speakingTopicsLearnHint(filtered.length),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.speakingNoTopics)),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(px(16), 0, px(16), px(24)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  childAspectRatio: kSpeakingTopicCardAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final topic = filtered[index];
                  return SpeakingTopicCard(
                    l10n: l10n,
                    topic: topic,
                    onTap: () => context.push(
                      '/speaking/part1/topics/${topic.id}',
                    ),
                  );
                }, childCount: filtered.length),
              ),
            ),
        ];
      },
    );
  }

  List<Widget> _buildModelsSlivers(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme scheme,
    required double Function(double) px,
    required AsyncValue<List<SpeakingModelSummary>> modelsValue,
  }) {
    return modelsValue.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  l10n.speakingModelsLoadError('$error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (models) {
        final filtered = _filterModels(models);

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(px(20), 0, px(20), px(12)),
              child: Text(
                l10n.speakingModelsLearnHint(filtered.length),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.speakingNoModels)),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(px(16), 0, px(16), px(24)),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return SpeakingModelQuestionRowCard(
                    l10n: l10n,
                    model: model,
                    onTap: () => context.push(
                      '/speaking/part1/models/${model.id}',
                    ),
                  );
                },
              ),
            ),
        ];
      },
    );
  }
}

class _SpeakingBrowseModeSwitcher extends StatelessWidget {
  const _SpeakingBrowseModeSwitcher({
    required this.mode,
    required this.onChanged,
  });

  final SpeakingPart1BrowseMode mode;
  final ValueChanged<SpeakingPart1BrowseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SegmentedButton<SpeakingPart1BrowseMode>(
      segments: [
        ButtonSegment(
          value: SpeakingPart1BrowseMode.topics,
          label: Text(l10n.speakingViewTopics),
          icon: const Icon(Icons.grid_view_rounded, size: 18),
        ),
        ButtonSegment(
          value: SpeakingPart1BrowseMode.modelQuestions,
          label: Text(l10n.speakingViewModelQuestions),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimaryContainer;
          }
          return scheme.onSurfaceVariant;
        }),
      ),
    );
  }
}

class _SpeakingPart1HeroBanner extends StatelessWidget {
  const _SpeakingPart1HeroBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kSpeakingBrandTeal, kSpeakingBrandCyan],
        ),
        boxShadow: [
          BoxShadow(
            color: kSpeakingBrandTeal.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.speakingPart1HeroTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.speakingPart1HeroSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.graphic_eq_rounded,
              color: scheme.onPrimary.withValues(alpha: 0.85),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

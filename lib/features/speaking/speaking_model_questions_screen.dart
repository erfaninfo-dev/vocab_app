import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_gradient_scaffold.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'speaking_constants.dart';
import 'widgets/speaking_questions_list_view.dart';

class SpeakingModelQuestionsScreen extends ConsumerStatefulWidget {
  const SpeakingModelQuestionsScreen({super.key, required this.modelId});

  final int modelId;

  @override
  ConsumerState<SpeakingModelQuestionsScreen> createState() =>
      _SpeakingModelQuestionsScreenState();
}

class _SpeakingModelQuestionsScreenState
    extends ConsumerState<SpeakingModelQuestionsScreen> {
  final ValueNotifier<bool> _expandAll = ValueNotifier(false);

  @override
  void dispose() {
    _expandAll.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await refreshAllRemoteApiData(ref);
    await ref.read(apiSpeakingModelQuestionItemsProvider(widget.modelId).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final theme = speakingThemeForTopic(widget.modelId);
    final dataValue = ref.watch(
      apiSpeakingModelQuestionItemsProvider(widget.modelId),
    );

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.back,
        onPressed: () => context.pop(),
      ),
      title: dataValue.maybeWhen(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.speakingModelNumber(data.model.modelNumber),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: speakingCardTitleColor(context),
                            ),
            ),
            Text(
              l10n.speakingModelQuestionsSubtitle(data.questions.length),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        orElse: () => Text(
          l10n.speakingViewModelQuestions,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: speakingCardTitleColor(context),
                            ),
        ),
      ),
      centerTitle: false,
      actions: [
        dataValue.maybeWhen(
          data: (data) => ValueListenableBuilder<bool>(
            valueListenable: _expandAll,
            builder: (context, expanded, _) {
              return IconButton(
                tooltip: expanded
                    ? l10n.speakingCollapseAll
                    : l10n.speakingExpandAll,
                onPressed: data.questions.isEmpty
                    ? null
                    : () => _expandAll.value = !expanded,
                icon: Icon(
                  expanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                ),
              );
            },
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 4),
      ],
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppGradientScaffold(
        extendBodyBehindAppBar: false,
        appBar: appBar,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: dataValue.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Text(
                    l10n.speakingQuestionsLoadError('$error'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ),
              ],
            ),
            data: (data) {
              if (data.questions.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(child: Text(l10n.speakingNoQuestions)),
                  ],
                );
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: _ModelSummaryCard(
                        l10n: l10n,
                        title: data.model.title,
                        formula: data.model.formula,
                        template: data.model.template,
                        accent: theme.accent,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: SpeakingQuestionsListView(
                        questions: data.questions,
                        showTopicOnCards: true,
                        expandAllNotifier: _expandAll,
                      ),
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

class _ModelSummaryCard extends StatelessWidget {
  const _ModelSummaryCard({
    required this.l10n,
    required this.title,
    required this.formula,
    required this.template,
    required this.accent,
  });

  final AppLocalizations l10n;
  final String title;
  final String formula;
  final String template;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.22 : 0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: isDark
              ? scheme.surfaceContainerHigh.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.98),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.1 : 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.22),
                                accent.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              title.trim().isEmpty
                                  ? l10n.speakingModelAnswer
                                  : title.trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                height: 1.3,
                                letterSpacing: -0.2,
                                color: speakingQuestionsTitleColor(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ModelSummaryInfoBlock(
                      label: l10n.speakingFormula,
                      text: formula,
                      accent: accent,
                      monospace: true,
                    ),
                    const SizedBox(height: 10),
                    _ModelSummaryInfoBlock(
                      label: l10n.speakingTemplate,
                      text: template,
                      accent: accent,
                      italic: true,
                    ),
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

class _ModelSummaryInfoBlock extends StatelessWidget {
  const _ModelSummaryInfoBlock({
    required this.label,
    required this.text,
    required this.accent,
    this.monospace = false,
    this.italic = false,
  });

  final String label;
  final String text;
  final Color accent;
  final bool monospace;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.55)
            : accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.42,
              fontFamily: monospace ? 'monospace' : null,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontWeight: monospace ? FontWeight.w500 : FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

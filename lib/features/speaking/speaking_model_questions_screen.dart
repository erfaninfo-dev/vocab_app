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
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
          child: dataValue.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: const [
                SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: topInset),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n.speakingQuestionsLoadError('$error'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                  padding: EdgeInsets.only(top: topInset),
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
                      padding: EdgeInsets.fromLTRB(16, topInset, 16, 12),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(
              title.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            l10n.speakingFormula,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formula,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.speakingTemplate,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            template,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

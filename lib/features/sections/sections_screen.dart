import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../data/models/section_info.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/widgets/book_vocab_quiz_fab.dart';

class SectionsScreen extends ConsumerStatefulWidget {
  const SectionsScreen({super.key, required this.bookId, required this.unit});

  final int bookId;
  final int unit;

  @override
  ConsumerState<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends ConsumerState<SectionsScreen> {
  Future<void> _onRefreshSections() async {
    await reloadSectionsFromNetwork(
      ref,
      bookId: widget.bookId,
      unit: widget.unit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sectionsValue = ref.watch(
      apiSectionsProvider((bookId: widget.bookId, unit: widget.unit)),
    );

    final showQuizFab = sectionsValue.maybeWhen(
      data: (sections) => sections.isNotEmpty,
      orElse: () => false,
    );

    final appBar = styledAppGradientAppBar(
      context: context,
      title: Text(l10n.unitLabel(widget.unit)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.backToUnits,
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/home'),
      ),
    );
    final topInset = appGradientContentTopInset(context, appBar: appBar, extra: 2);

    return AppGradientScaffold(
      floatingActionButtonLocation:
          BookVocabQuizFab.floatingActionButtonLocation,
      floatingActionButton: showQuizFab
          ? BookVocabQuizFab(bookId: widget.bookId, unit: widget.unit)
          : null,
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: _onRefreshSections,
        child: sectionsValue.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: topInset),
            children: const [
              SizedBox(
                height: 320,
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
                    l10n.couldNotLoadSectionsWithError('$error'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _onRefreshSections,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          data: (sections) {
            if (sections.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.go('/books/${widget.bookId}/units/${widget.unit}/words');
              });
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: topInset),
                children: const [
                  SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            return _SectionList(
              l10n: l10n,
              sections: sections,
              bookId: widget.bookId,
              unit: widget.unit,
              showQuizFab: showQuizFab,
              topInset: topInset,
            );
          },
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.l10n,
    required this.sections,
    required this.bookId,
    required this.unit,
    required this.showQuizFab,
    required this.topInset,
  });

  final AppLocalizations l10n;
  final List<SectionInfo> sections;
  final int bookId;
  final int unit;
  final bool showQuizFab;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          topInset,
          16,
          showQuizFab ? BookVocabQuizFab.scrollBottomPadding(context) : 18,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final info = sections[index];
          return _SectionTile(
            l10n: l10n,
            unit: unit,
            info: info,
            onTap: () => context.push(
              '/books/$bookId/units/$unit/sections/${info.section}/words',
            ),
          );
        },
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.l10n,
    required this.unit,
    required this.info,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final int unit;
  final SectionInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = _sectionAccents(info.section);
    final titleLabel = _sectionTitleLabel(l10n, info);

    return AppJellyCard(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kAppJellyRadius),
                gradient: LinearGradient(
                  colors: [
                    accents.first.withValues(alpha: 0.16),
                    accents.last.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                AppJellyIconBubble(
                  color: accents.first,
                  size: 48,
                  child: Text(
                    '${info.section}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.unitSectionLine(unit, info.section),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

String _sectionTitleLabel(AppLocalizations l10n, SectionInfo info) {
  final d = info.sectionDetails?.trim();
  if (d != null && d.isNotEmpty) return d;
  return l10n.sectionNumberLabel(info.section);
}

List<Color> _sectionAccents(int section) {
  switch (section) {
    case 1:
      return const [Color(0xFF5B6CFF), Color(0xFF7AA2FF)];
    case 2:
      return const [Color(0xFF7C5CFF), Color(0xFFB78DFF)];
    default:
      return const [Color(0xFF4D8DFF), Color(0xFF79C0FF)];
  }
}

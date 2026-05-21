import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/section_info.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/widgets/book_vocab_quiz_fab.dart';

class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key, required this.bookId, required this.unit});

  final int bookId;
  final int unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final sectionsValue = ref.watch(
      apiSectionsProvider((bookId: bookId, unit: unit)),
    );

    final showQuizFab = sectionsValue.maybeWhen(
      data: (sections) => sections.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      floatingActionButtonLocation:
          BookVocabQuizFab.floatingActionButtonLocation,
      floatingActionButton: showQuizFab
          ? BookVocabQuizFab(bookId: bookId, unit: unit)
          : null,
      appBar: AppBar(
        title: Text(l10n.unitLabel(unit)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.backToUnits,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withValues(alpha: 0.08), scheme.surface],
          ),
        ),
        child: sectionsValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.couldNotLoadSectionsWithError('$error'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (sections) {
            if (sections.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                context.go('/books/$bookId/units/$unit/words');
              });
              return const Center(child: CircularProgressIndicator());
            }
            return _SectionList(
              l10n: l10n,
              sections: sections,
              bookId: bookId,
              unit: unit,
              showQuizFab: showQuizFab,
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
  });

  final AppLocalizations l10n;
  final List<SectionInfo> sections;
  final int bookId;
  final int unit;
  final bool showQuizFab;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                accents.first.withValues(alpha: 0.16),
                accents.last.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accents.first.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${info.section}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accents.first,
                    ),
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

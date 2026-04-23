import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/api_providers.dart';

class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key, required this.bookId, required this.unit});

  final int bookId;
  final int unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sectionsValue = ref.watch(
      apiSectionsProvider((bookId: bookId, unit: unit)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit $unit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to units',
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
                'Could not load sections.\n$error',
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
              sections: sections,
              bookId: bookId,
              unit: unit,
            );
          },
        ),
      ),
    );
  }
}

// ─── Section list ─────────────────────────────────────────────────────────────

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.sections,
    required this.bookId,
    required this.unit,
  });

  final List<int> sections;
  final int bookId;
  final int unit;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final section = sections[index];
          return _SectionTile(
            unit: unit,
            section: section,
            onTap: () => context.push(
              '/books/$bookId/units/$unit/sections/$section/words',
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Tile ─────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.unit,
    required this.section,
    required this.onTap,
  });

  final int unit;
  final int section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = _sectionAccents(section);

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
                    '$section',
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
                      'Section $section',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit $unit · Section $section',
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

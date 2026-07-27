import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_jelly_style.dart';
import '../../data/models/grammar_book.dart';
import '../../data/models/grammar_unit.dart';
import '../../domain/api_providers.dart';

class GrammarBookUnitsScreen extends ConsumerWidget {
  const GrammarBookUnitsScreen({super.key, required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(apiGrammarUnitsProvider(bookId));
    final book = ref
        .watch(apiGrammarBooksProvider)
        .valueOrNull
        ?.firstWhere(
          (b) => b.id == bookId,
          orElse: () => const GrammarBook(
            id: 0,
            title: 'Grammar Book',
            sortOrder: 0,
            isActive: true,
            unitCount: 0,
            questionCount: 0,
          ),
        );
    final title = book?.title ?? 'Grammar Book';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withValues(alpha: 0.08), scheme.surface],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(apiGrammarUnitsProvider(bookId));
            await ref.read(apiGrammarUnitsProvider(bookId).future);
          },
          child: unitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const _GrammarUnitsMessage(
              icon: Icons.error_outline_rounded,
              title: 'Could not load lessons',
              subtitle: 'Pull down to try again.',
            ),
            data: (units) {
              if (units.isEmpty) {
                return const _GrammarUnitsMessage(
                  icon: Icons.menu_book_outlined,
                  title: 'No lessons yet',
                  subtitle:
                      'Add grammar units on the server to show them here.',
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final quizCount = math.min(
                    kGrammarQuizDefaultQuestionCount,
                    math.max(unit.questionCount, 1),
                  );
                  final encodedTitle = Uri.encodeQueryComponent(
                    unit.displayTitle,
                  );
                  return _GrammarUnitCard(
                    unit: unit,
                    index: index,
                    onLessonTap: () =>
                        context.push('/grammar/books/$bookId/units/${unit.id}'),
                    onQuizTap: unit.questionCount > 0
                        ? () => context.push(
                            '/grammar/practice?unit_id=${unit.id}&count=$quizCount&title=$encodedTitle',
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GrammarUnitsMessage extends StatelessWidget {
  const _GrammarUnitsMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 54, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _GrammarUnitCard extends StatelessWidget {
  const _GrammarUnitCard({
    required this.unit,
    required this.index,
    required this.onLessonTap,
    required this.onQuizTap,
  });

  final GrammarUnit unit;
  final int index;
  final VoidCallback onLessonTap;
  final VoidCallback? onQuizTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _lessonAccent(index);
    final subtitle = unit.subtitle?.trim();
    final hasQuiz = onQuizTap != null;

    return AppJellyShell(
      decoration: appJellyAccentCardSurfaceDecoration(
        context,
        accent: accent,
        intensity: 0.16,
        scheme: scheme,
      ),
      shadows: appJellyCardShadows(context, glowColor: accent),
      padding: const EdgeInsets.all(14),
      child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.92),
                            accent.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${unit.unitNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
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
                            unit.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _GrammarUnitActionTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Lesson',
                      subtitle: _lessonCountLabel(unit.textCount),
                      color: accent,
                      onTap: onLessonTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GrammarUnitActionTile(
                      icon: hasQuiz
                          ? Icons.quiz_rounded
                          : Icons.lock_clock_rounded,
                      title: 'Quiz',
                      subtitle: hasQuiz
                          ? _questionCountLabel(unit.questionCount)
                          : 'Soon',
                      color: const Color(0xFF8B5CF6),
                      onTap: onQuizTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _GrammarUnitActionTile extends StatelessWidget {
  const _GrammarUnitActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final foreground = enabled ? color : scheme.onSurfaceVariant;

    return AppJellyShell(
      onTap: onTap,
      decoration: enabled
          ? appJellyCardSurfaceDecoration(context).copyWith(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.82)!,
                  Color.lerp(color, Colors.white, 0.92)!,
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 1.3,
              ),
            )
          : appJellyInsetDecoration(context),
      shadows: enabled
          ? appJellyCardShadows(context, glowColor: color)
          : const [],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
              children: [
                AppJellyIconBubble(
                  color: enabled ? color : scheme.outline,
                  size: 34,
                  child: Icon(
                    icon,
                    color: enabled ? Colors.white : foreground,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: enabled
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.hourglass_empty_rounded,
                  color: foreground,
                  size: 15,
                ),
              ],
            ),
    );
  }
}

String _lessonCountLabel(int count) {
  return count == 1 ? '1 lesson' : '$count lessons';
}

String _questionCountLabel(int count) {
  return count == 1 ? '1 question' : '$count questions';
}

Color _lessonAccent(int index) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFF97316),
    Color(0xFFDC2626),
  ];
  return colors[index % colors.length];
}

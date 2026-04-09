import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/srs/srs_provider.dart';
import '../../data/models/book_model.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

final searchControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  controller.addListener(() {
    ref.read(bookSearchQueryProvider.notifier).state = controller.text;
  });
  ref.onDispose(() => controller.dispose());
  return controller;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksValue = ref.watch(apiSearchBooksProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
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
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header جدا از booksValue — ری‌بیلد نمی‌شه
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: const _HomeHeader(),
                ),
              ),

              // ── Review Today banner ───────────────────────────────────────
              const SliverToBoxAdapter(child: _ReviewBanner()),

              // ── Grammar practice ──────────────────────────────────────────
              const SliverToBoxAdapter(child: _GrammarPracticeBanner()),

              booksValue.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.couldNotLoadBooksWithError(error.toString()),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                data: (books) {
                  if (books.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Center(
                          child: Text(
                            l10n.noBooksFound,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 1100
                            ? 3
                            : width >= 700
                            ? 2
                            : 1;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio:
                                    crossAxisCount == 1 ? 1.5 : 1.08,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return _BookCard(
                                  book: book,
                                  index: index,
                                  onTap: () =>
                                      context.push('/books/${book.id}/units'),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Header ─────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final bookCount = ref.watch(
      apiSearchBooksProvider.select((v) => v.valueOrNull?.length ?? 0),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: scheme.surface.withValues(alpha: 0.58),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseYourBook,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.booksAvailable(bookCount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const _SearchField(),
        ],
      ),
    );
  }
}

// ───────────────────── Search Field (ایزوله) ─────────────────────

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.watch(searchControllerProvider);

    return TextField(
      controller: controller,
      autofocus: false,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.searchBooksHint,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ───────────────────── Book Card ─────────────────────

class _BookCard extends ConsumerWidget {
  const _BookCard({
    required this.book,
    required this.index,
    required this.onTap,
  });

  final Book book;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final unitsValue = ref.watch(apiUnitsProvider(book.id));
    final accents = _cardAccents(index);
    final locale = Localizations.localeOf(context);
    final rtlUnitLine =
        locale.languageCode == 'fa' || locale.languageCode == 'ckb';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accents.first.withValues(alpha: 0.18),
                accents.last.withValues(alpha: 0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accents.first.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: accents.first,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),

              const Spacer(),

              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment:
                    rtlUnitLine ? Alignment.centerRight : Alignment.centerLeft,
                child: Directionality(
                  textDirection:
                      rtlUnitLine ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    unitsValue.when(
                      loading: () => l10n.loadingEllipsis,
                      error: (_, __) => l10n.tapToOpen,
                      data: (units) {
                        final n = units.length;
                        return '$n ${n == 1 ? l10n.unitSingular : l10n.unitPlural}';
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if ((book.description ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: accents.first,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          book.description!,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
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

// helper
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

// ───────────────────── Grammar practice banner ─────────────────────

class _GrammarPracticeBanner extends StatelessWidget {
  const _GrammarPracticeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/grammar'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.secondary.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rule_rounded,
                  color: scheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.grammarPracticeTitle,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.grammarPracticeSubtitle,
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: scheme.onPrimary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Review Banner ─────────────────────

class _ReviewBanner extends ConsumerWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dueCount = ref.watch(
      srsProvider.select((s) => s.dueTodayCount),
    );

    if (dueCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/review'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade400,
                ],
              ),
            ),
            child: Row(
              children: [
                const Text('🔁', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reviewWordsDue(dueCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        l10n.reviewTapStart,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

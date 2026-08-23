import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/api_providers.dart';
import '../../../domain/api_remote_data_epoch.dart';
import '../application/word_builder_theme_categories_provider.dart';
import '../data/word_builder_theme_categories.dart';
import 'theme/word_builder_tokens.dart';
import 'widgets/magic_background.dart';

class WordBuilderCategoryPickerScreen extends ConsumerStatefulWidget {
  const WordBuilderCategoryPickerScreen({super.key});

  @override
  ConsumerState<WordBuilderCategoryPickerScreen> createState() =>
      _WordBuilderCategoryPickerScreenState();
}

class _WordBuilderCategoryPickerScreenState
    extends ConsumerState<WordBuilderCategoryPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(apiGameWordCategoriesProvider);
    });
  }

  Future<void> _refreshTopics() async {
    ref.invalidate(apiGameWordCategoriesProvider);
    ref.read(apiRemoteDataEpochProvider.notifier).state++;
    await ref.read(apiGameWordCategoriesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final canPop = context.canPop();

    final funTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
    );

    final categoriesAsync = ref.watch(wordBuilderThemeCategoriesProvider);
    final categories = categoriesAsync.valueOrNull;

    final query = _query.trim().toLowerCase();
    final filtered = categories == null
        ? const <(int, WordBuilderThemeCategory)>[]
        : query.isEmpty
        ? categories.indexed.toList()
        : categories.indexed.where((entry) {
            final c = entry.$2;
            return c.nameEn.toLowerCase().contains(query) ||
                c.nameFa.toLowerCase().contains(query) ||
                c.nameCkb.toLowerCase().contains(query);
          }).toList();

    return Theme(
      data: funTheme,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MagicBackground(isDark: isDark),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: kToolbarHeight,
              centerTitle: false,
              automaticallyImplyLeading: false,
              titleSpacing: canPop ? 0 : WbTokens.s4,
              leading: canPop
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark
                            ? scheme.onSurface
                            : const Color(0xFF5D4037),
                      ),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: Text(
                l10n.wordBuilderCategoryPickerTitle,
                style: GoogleFonts.fredoka(
                  fontSize: WbTokens.tLg,
                  fontWeight: FontWeight.w900,
                  color: isDark ? scheme.onSurface : const Color(0xFF5D4037),
                ),
              ),
            ),
            body: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: const Color(0xFFFFB300),
                onRefresh: _refreshTopics,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      WbTokens.s4,
                      WbTokens.s1,
                      WbTokens.s4,
                      WbTokens.s3,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (l10n.wordBuilderCategoryPickerSubtitle
                              .trim()
                              .isNotEmpty) ...[
                            Text(
                              l10n.wordBuilderCategoryPickerSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                            const SizedBox(height: WbTokens.s4),
                          ],
                          _CategorySearchField(
                            controller: _searchController,
                            hintText: l10n.wordBuilderCategorySearchHint,
                            isDark: isDark,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: WbTokens.s4),
                          _NormalTrackCard(
                            title: l10n.wordBuilderNormalTitle,
                            subtitle: l10n.wordBuilderNormalSubtitle,
                            onTap: () => context.push('/word-builder/normal'),
                          ),
                          const SizedBox(height: WbTokens.s6),
                          if (categoriesAsync.isLoading && categories == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: WbTokens.s4),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            )
                          else if (filtered.isNotEmpty)
                            Text(
                              l10n.wordBuilderCategorySectionTitle,
                              style: GoogleFonts.fredoka(
                                fontSize: WbTokens.tMd,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? scheme.onSurface.withValues(alpha: 0.9)
                                    : const Color(0xFF5D4037),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (categoriesAsync.isLoading && categories == null)
                    const SliverToBoxAdapter(child: SizedBox.shrink())
                  else if (categoriesAsync.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyResults(
                        message: l10n.wordBuilderCategoryTopicsLoadFailed,
                        isDark: isDark,
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyResults(
                        message: query.isEmpty
                            ? l10n.wordBuilderCategoryTopicsLoadFailed
                            : l10n.wordBuilderCategoryEmptyResults,
                        isDark: isDark,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        WbTokens.s4,
                        WbTokens.s2,
                        WbTokens.s4,
                        WbTokens.s6,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: WbTokens.s3,
                          crossAxisSpacing: WbTokens.s3,
                          childAspectRatio: 0.86,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final (index, category) = filtered[i];
                            return _CategoryTile(
                              label: category.displayName(languageCode),
                              icon: category.icon,
                              enabled: themeCategoryHasPlayableWords(
                                category,
                                index,
                              ),
                              disabledHint: l10n.wordBuilderCategoryNoWordsYet,
                              onTap: () {
                                context.push(
                                  '/word-builder/theme?index=$index',
                                );
                              },
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySearchField extends StatelessWidget {
  const _CategorySearchField({
    required this.controller,
    required this.hintText,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.fredoka(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF5D4037),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.fredoka(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF8D6E63),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFFFFB300),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.75),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WbTokens.s4,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WbTokens.rPill),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.7),
            width: 1.4,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WbTokens.rPill),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.7),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WbTokens.rPill),
          borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.8),
        ),
      ),
    );
  }
}

class _NormalTrackCard extends StatelessWidget {
  const _NormalTrackCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WbTokens.rLg),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WbTokens.rLg),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.32),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WbTokens.s5,
              vertical: WbTokens.s5,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 26,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
                const SizedBox(width: WbTokens.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8D6E63),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8D6E63),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.disabledHint,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.42;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(WbTokens.rMd),
          onTap: enabled ? onTap : null,
          child: Tooltip(
            message: enabled ? label : disabledHint ?? label,
            child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WbTokens.rMd),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFF3E0)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WbTokens.s2,
              vertical: WbTokens.s3,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFCC80), Color(0xFFFF9800)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: WbTokens.s2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbTokens.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
            ),
            const SizedBox(height: WbTokens.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

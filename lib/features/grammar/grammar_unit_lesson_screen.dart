import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/language/language_provider.dart';
import '../../data/models/vocab_entry.dart';
import '../../data/models/grammar_unit.dart';
import '../../data/models/grammar_unit_text.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../unit_samples/sample_text_highlight_rendering.dart';
import '../unit_samples/sample_vocab_lookup.dart';
import '../words/widgets/word_card.dart';

const double _kGrammarLessonRailWidth = 56;
const double _kGrammarLessonBodyInset = 16;
const double _kGrammarLessonHeaderBaseHeight = 132;
const double _kGrammarRailCornerRadius = 22;
const double _kGrammarSectionHeaderExtent = 32;
const double _kGrammarWordSheetMaxHeightFraction = 0.78;
const LinearGradient _kGrammarRailGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
);

class GrammarUnitLessonScreen extends ConsumerWidget {
  const GrammarUnitLessonScreen({
    super.key,
    required this.bookId,
    required this.unitId,
  });

  final int bookId;
  final int unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(apiGrammarUnitsProvider(bookId));
    final unit = _unitFromAsync(unitsAsync, unitId);
    final title = unit?.displayTitle ?? 'Grammar Lesson';

    return Scaffold(
      body: _GrammarLessonBody(
        unitId: unitId,
        unitNumber: unit?.unitNumber,
        lessonTitle: title,
      ),
    );
  }
}

GrammarUnit? _unitFromAsync(AsyncValue<List<GrammarUnit>> async, int unitId) {
  final units = async.valueOrNull;
  if (units == null) return null;
  for (final unit in units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

class _GrammarLessonBody extends ConsumerWidget {
  const _GrammarLessonBody({
    required this.unitId,
    required this.lessonTitle,
    this.unitNumber,
  });

  final int unitId;
  final String lessonTitle;
  final int? unitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textsAsync = ref.watch(apiGrammarUnitTextsProvider(unitId));
    final lang = ref.watch(langProvider);

    return textsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _CenteredLessonMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load lesson',
        subtitle: 'Please try again later.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _CenteredLessonMessage(
            icon: Icons.article_outlined,
            title: 'No lesson text yet',
            subtitle: 'Add text blocks for this grammar unit on the server.',
          );
        }
        return SizedBox.expand(
          child: _GrammarTextCard(
            texts: items,
            lang: lang,
            lessonTitle: lessonTitle,
            unitNumber: unitNumber,
            showNavigation: true,
            onLangChanged: (value) {
              if (!context.mounted) return;
              ref.read(langProvider.notifier).setLang(value);
            },
          ),
        );
      },
    );
  }
}

class _GrammarTextCard extends StatefulWidget {
  const _GrammarTextCard({
    required this.texts,
    required this.lang,
    required this.lessonTitle,
    required this.showNavigation,
    required this.onLangChanged,
    this.unitNumber,
  });

  final List<GrammarUnitText> texts;
  final TranslationLang lang;
  final String lessonTitle;
  final bool showNavigation;
  final ValueChanged<TranslationLang> onLangChanged;
  final int? unitNumber;

  @override
  State<_GrammarTextCard> createState() => _GrammarTextCardState();
}

class _GrammarTextCardState extends State<_GrammarTextCard> {
  final _scrollController = ScrollController();
  final _bodyViewportKey = GlobalKey();
  final _sectionHeaderKeys = <GlobalKey>[];
  String? _stickySectionLabel;
  double _stickySectionOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateStickySectionLabel);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateStickySectionLabel)
      ..dispose();
    super.dispose();
  }

  void _ensureSectionHeaderKeys(int length) {
    if (_sectionHeaderKeys.length == length) return;
    _sectionHeaderKeys
      ..clear()
      ..addAll(List.generate(length, (_) => GlobalKey()));
  }

  void _scheduleStickyUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateStickySectionLabel();
    });
  }

  void _updateStickySectionLabel() {
    final viewportContext = _bodyViewportKey.currentContext;
    final viewportBox = viewportContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize) return;

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportHeight = viewportBox.size.height;
    var activeIndex = -1;

    for (var i = 0; i < _sectionHeaderKeys.length; i++) {
      final context = _sectionHeaderKeys[i].currentContext;
      final box = context?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy - viewportTop;
      if (top <= 0) activeIndex = i;
    }

    var nextTop = double.infinity;
    if (activeIndex >= 0 && activeIndex + 1 < _sectionHeaderKeys.length) {
      final nextContext = _sectionHeaderKeys[activeIndex + 1].currentContext;
      final nextBox = nextContext?.findRenderObject() as RenderBox?;
      if (nextBox != null && nextBox.hasSize) {
        nextTop = nextBox.localToGlobal(Offset.zero).dy - viewportTop;
      }
    }

    final nextStickyLabel = activeIndex < 0
        ? null
        : _currentSections[activeIndex].label;
    var nextStickyOffset = 0.0;
    if (nextStickyLabel != null && nextTop < viewportHeight && nextTop > 0) {
      final progress = ((viewportHeight - nextTop) / viewportHeight).clamp(
        0.0,
        1.0,
      );
      nextStickyOffset = -progress * _kGrammarSectionHeaderExtent;
    }

    if (_stickySectionLabel == nextStickyLabel &&
        (_stickySectionOffset - nextStickyOffset).abs() < 0.5) {
      return;
    }
    setState(() {
      _stickySectionLabel = nextStickyLabel;
      _stickySectionOffset = nextStickyOffset;
    });
  }

  late List<_GrammarLessonSectionData> _currentSections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryText = widget.texts.first;
    final body = widget.texts
        .map(
          (text) => widget.lang == TranslationLang.kur
              ? text.textEnKur
              : text.textEnFa,
        )
        .join('\n\n');
    final sections = _parseGrammarLessonSections(body);
    _currentSections = sections;
    _ensureSectionHeaderKeys(sections.length);
    _scheduleStickyUpdate();
    final railUnitNumber =
        widget.unitNumber ??
        _extractGrammarUnitNumber('${primaryText.title}\n$body');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadiusDirectional.only(
          topEnd: Radius.circular(22),
          bottomEnd: Radius.circular(22),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: _GrammarUnitRail(
              unitNumber: railUnitNumber,
              showBackButton: widget.showNavigation,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: _kGrammarLessonRailWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GrammarLessonHeader(
                  title: primaryText.title.trim().isEmpty
                      ? widget.lessonTitle
                      : primaryText.title,
                  lang: widget.lang,
                  onLangChanged: widget.onLangChanged,
                ),
                Expanded(
                  child: Container(
                    key: _bodyViewportKey,
                    color: scheme.surface,
                    child: ClipPath(
                      clipper: const _GrammarLessonBodyClipper(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _grammarLessonSectionWidgets(
                                sections,
                                lang: widget.lang,
                                headerKeys: _sectionHeaderKeys,
                              ),
                            ),
                          ),
                          if (_stickySectionLabel != null)
                            PositionedDirectional(
                              start: -_kGrammarLessonRailWidth,
                              top: _stickySectionOffset,
                              child: _GrammarSectionRailMarker(
                                label: _stickySectionLabel!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _grammarLessonSectionWidgets(
  List<_GrammarLessonSectionData> sections, {
  required TranslationLang lang,
  required List<GlobalKey> headerKeys,
}) {
  if (sections.isEmpty) {
    return const [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 18, 22),
        child: SelectableText('—'),
      ),
    ];
  }

  return [
    for (var i = 0; i < sections.length; i++) ...[
      _GrammarNaturalSectionHeader(
        key: headerKeys[i],
        sectionLabel: sections[i].label,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 18, 22),
        child: _GrammarLessonSection(lines: sections[i].lines, lang: lang),
      ),
    ],
  ];
}

class _GrammarLessonBodyClipper extends CustomClipper<Path> {
  const _GrammarLessonBodyClipper();

  @override
  Path getClip(Size size) {
    const horizontalOverflow =
        _kGrammarLessonRailWidth + _kGrammarLessonBodyInset + 16;
    final path = Path()
      // The body text area clips normally from the top edge.
      ..addRect(
        Rect.fromLTRB(0, 0, size.width + horizontalOverflow, size.height),
      )
      // The rail side follows the rounded top corner, so section markers slide
      // under the curve instead of disappearing behind the white notch.
      ..moveTo(-horizontalOverflow, 0)
      ..lineTo(-_kGrammarRailCornerRadius, 0)
      ..quadraticBezierTo(0, 0, 0, _kGrammarRailCornerRadius)
      ..lineTo(0, size.height)
      ..lineTo(-horizontalOverflow, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _GrammarLessonBodyClipper oldClipper) => false;
}

class _GrammarLessonHeader extends StatelessWidget {
  const _GrammarLessonHeader({
    required this.title,
    required this.lang,
    required this.onLangChanged,
  });

  final String title;
  final TranslationLang lang;
  final ValueChanged<TranslationLang> onLangChanged;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF4C160F),
        borderRadius: BorderRadiusDirectional.only(
          bottomStart: Radius.circular(22),
          bottomEnd: Radius.circular(22),
        ),
      ),
      constraints: BoxConstraints(
        minHeight: topPadding + _kGrammarLessonHeaderBaseHeight,
      ),
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 14, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 16.5,
                height: 1.22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _GrammarLanguageToggle(lang: lang, onChanged: onLangChanged),
        ],
      ),
    );
  }
}

class _GrammarLanguageToggle extends StatelessWidget {
  const _GrammarLanguageToggle({required this.lang, required this.onChanged});

  final TranslationLang lang;
  final ValueChanged<TranslationLang> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GrammarLanguageOption(
            label: 'FA',
            selected: lang == TranslationLang.fa,
            onTap: () => onChanged(TranslationLang.fa),
          ),
          _GrammarLanguageOption(
            label: 'KU',
            selected: lang == TranslationLang.kur,
            onTap: () => onChanged(TranslationLang.kur),
          ),
        ],
      ),
    );
  }
}

class _GrammarLanguageOption extends StatelessWidget {
  const _GrammarLanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? const Color(0xFF4C160F) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GrammarUnitRail extends StatelessWidget {
  const _GrammarUnitRail({
    required this.unitNumber,
    required this.showBackButton,
  });

  final int? unitNumber;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: _kGrammarLessonRailWidth,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            width: _kGrammarLessonRailWidth,
            height: topPadding + _kGrammarLessonHeaderBaseHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: _kGrammarRailGradient,
                borderRadius: BorderRadiusDirectional.only(
                  bottomEnd: Radius.circular(_kGrammarRailCornerRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: topPadding + _kGrammarLessonHeaderBaseHeight,
            bottom: 0,
            width: _kGrammarLessonRailWidth,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: _kGrammarRailGradient,
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(_kGrammarRailCornerRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              width: _kGrammarLessonRailWidth,
              child: Padding(
                padding: EdgeInsets.only(
                  top: showBackButton ? topPadding + 8 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBackButton) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 38,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 22),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Text(
                        unitNumber == null ? '-' : '$unitNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'Unit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
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

class _GrammarLessonSection extends StatelessWidget {
  const _GrammarLessonSection({required this.lines, required this.lang});

  final List<_GrammarLessonLine> lines;
  final TranslationLang lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          _GrammarLessonLineText(line: lines[i], lang: lang),
          if (i != lines.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GrammarNaturalSectionHeader extends StatelessWidget {
  const _GrammarNaturalSectionHeader({super.key, required this.sectionLabel});

  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    if (sectionLabel == null) return const SizedBox.shrink();

    final label = sectionLabel!;
    final isSectionA = label.toUpperCase() == 'A';

    return SizedBox(
      height: _kGrammarSectionHeaderExtent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: -_kGrammarLessonRailWidth,
            top: 0,
            child: _GrammarSectionRailMarker(label: label),
          ),
          if (!isSectionA)
            PositionedDirectional(
              start: 16,
              end: 18,
              top: 0,
              child: Container(
                height: 1.6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GrammarSectionRailMarker extends StatelessWidget {
  const _GrammarSectionRailMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kGrammarLessonRailWidth,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF4C160F),
        borderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(16),
          bottomEnd: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _GrammarLessonLineText extends StatelessWidget {
  const _GrammarLessonLineText({required this.line, required this.lang});

  final _GrammarLessonLine line;
  final TranslationLang lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEnglish = line.kind == _GrammarLessonLineKind.english;
    final isLocal = line.kind == _GrammarLessonLineKind.local;
    final isHeading = line.kind == _GrammarLessonLineKind.heading;
    final style =
        (isHeading
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyLarge)
            ?.copyWith(
              height: isEnglish ? 1.45 : 1.68,
              fontSize: isHeading ? 17 : 16.5,
              fontWeight: isHeading || line.hasExplicitLabel
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: isLocal
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.92),
            );

    if (!isLocal) {
      return _GrammarClickableEnglishText(
        text: line.text,
        style: style,
        textAlign: line.textAlign,
        lang: lang,
      );
    }

    return Directionality(
      textDirection: line.direction,
      child: SelectableText(line.text, textAlign: line.textAlign, style: style),
    );
  }
}

class _GrammarClickableEnglishText extends ConsumerStatefulWidget {
  const _GrammarClickableEnglishText({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.lang,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TranslationLang lang;

  @override
  ConsumerState<_GrammarClickableEnglishText> createState() =>
      _GrammarClickableEnglishTextState();
}

class _GrammarClickableEnglishTextState
    extends ConsumerState<_GrammarClickableEnglishText> {
  final _tapRecognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _GrammarClickableEnglishText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (final r in _tapRecognizers) {
        r.dispose();
      }
      _tapRecognizers.clear();
    }
  }

  void _ensureTapRecognizerCount(int count) {
    while (_tapRecognizers.length < count) {
      _tapRecognizers.add(TapGestureRecognizer());
    }
    while (_tapRecognizers.length > count) {
      _tapRecognizers.removeLast().dispose();
    }
  }

  void _openMatchesSheet(List<VocabEntry> entries, {String? tappedText}) {
    if (entries.isEmpty) return;
    final theme = Theme.of(context);
    final uiLang = Localizations.localeOf(context).languageCode;
    final count = entries.length;
    final lemma = entries.first.word;
    final title = (uiLang == 'fa' || uiLang == 'ckb')
        ? '$count مورد یافت شد'
        : (count == 1 ? '1 match' : '$count matches');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final maxH =
            MediaQuery.sizeOf(ctx).height * _kGrammarWordSheetMaxHeightFraction;
        final padBottom = MediaQuery.paddingOf(ctx).bottom;
        final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tappedText == null || tappedText.trim().isEmpty
                          ? lemma
                          : tappedText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        final divider = Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        );

        if (count == 1) {
          return Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      divider,
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          padBottom + 16,
                        ),
                        child: WordCard(
                          entry: entries.first,
                          translationLang: widget.lang,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: SizedBox(
              height: maxH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  divider,
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, padBottom + 16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => WordCard(
                        entry: entries[i],
                        translationLang: widget.lang,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onWordTap(
    int startTokenIndex,
    List<EnWordToken> tokens,
    List<VocabEntry> catalog,
  ) {
    final catalogAsync = ref.read(apiAllWordsCatalogProvider);
    if (catalogAsync.isLoading) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.unitSamplesLoadingCatalog,
          ),
        ),
      );
      return;
    }
    if (catalogAsync.hasError) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('${catalogAsync.error}')));
      return;
    }

    final matches = lookupCatalogMatches(
      tokens: tokens,
      startTokenIndex: startTokenIndex,
      catalog: catalogAsync.value ?? catalog,
      preferredBookId: -1,
      preferredUnit: -1,
    );
    if (matches.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n!.noMatchingWords)));
      return;
    }
    _openMatchesSheet(
      matches,
      tappedText: bestTappedPhrase(
        tokens: tokens,
        startTokenIndex: startTokenIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = tokenizeEnglishWords(widget.text);
    _ensureTapRecognizerCount(tokens.length);
    final catalogAsync = ref.watch(apiAllWordsCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? const <VocabEntry>[];
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (cursor < token.start) {
        spans.add(TextSpan(text: widget.text.substring(cursor, token.start)));
      }
      spans.add(
        TextSpan(
          text: widget.text.substring(token.start, token.end),
          recognizer: _tapRecognizers[i]
            ..onTap = () => _onWordTap(i, tokens, catalog),
        ),
      );
      cursor = token.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SelectableText.rich(
        TextSpan(style: widget.style, children: spans),
        textAlign: widget.textAlign,
        textWidthBasis: TextWidthBasis.parent,
      ),
    );
  }
}

enum _GrammarLessonLineKind { english, local, heading }

class _GrammarLessonLine {
  const _GrammarLessonLine({
    required this.text,
    required this.kind,
    required this.hasExplicitLabel,
  });

  final String text;
  final _GrammarLessonLineKind kind;
  final bool hasExplicitLabel;

  TextDirection get direction {
    if (kind == _GrammarLessonLineKind.local) return TextDirection.rtl;
    return TextDirection.ltr;
  }

  TextAlign get textAlign {
    if (kind == _GrammarLessonLineKind.local) return TextAlign.right;
    return TextAlign.left;
  }
}

class _GrammarLessonSectionData {
  const _GrammarLessonSectionData({required this.label, required this.lines});

  final String? label;
  final List<_GrammarLessonLine> lines;
}

List<_GrammarLessonSectionData> _parseGrammarLessonSections(String raw) {
  final sections = <_GrammarLessonSectionData>[];
  var current = <_GrammarLessonLine>[];
  String? currentLabel;
  final lines = raw.replaceAll('\r\n', '\n').split('\n');

  void flush() {
    if (current.isEmpty) return;
    sections.add(
      _GrammarLessonSectionData(label: currentLabel, lines: current),
    );
    current = <_GrammarLessonLine>[];
    currentLabel = null;
  }

  for (final rawLine in lines) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final marker = _grammarLessonSectionMarker(trimmed);
    if (marker != null) {
      flush();
      currentLabel = marker.label;
      final title = marker.title;
      if (title != null && title.isNotEmpty) {
        current.add(
          _GrammarLessonLine(
            text: title,
            kind: _dominantDirectionIsRtl(title)
                ? _GrammarLessonLineKind.local
                : _GrammarLessonLineKind.heading,
            hasExplicitLabel: false,
          ),
        );
      }
      continue;
    }
    final line = _classifyGrammarLessonLine(trimmed);
    if (line != null) current.add(line);
  }
  flush();
  return sections;
}

_GrammarLessonLine? _classifyGrammarLessonLine(String text) {
  final lower = text.toLowerCase();
  final startsEnglish = RegExp(
    r'^\s*english\s*:?',
    caseSensitive: false,
  ).hasMatch(text);
  final startsPersian = RegExp(
    r'^\s*فارسی\s*[:：]?\s*',
    unicode: true,
  ).hasMatch(text);
  final startsUnit = RegExp(
    r'^\s*unit\s+\d+',
    caseSensitive: false,
  ).hasMatch(text);

  if (startsEnglish) {
    return _GrammarLessonLine(
      text: text,
      kind: _GrammarLessonLineKind.english,
      hasExplicitLabel: true,
    );
  }
  if (startsPersian) {
    final displayText = text
        .replaceFirst(RegExp(r'^\s*فارسی\s*[:：]?\s*', unicode: true), '')
        .trim();
    if (displayText.isEmpty) return null;
    return _GrammarLessonLine(
      text: displayText,
      kind: _GrammarLessonLineKind.local,
      hasExplicitLabel: true,
    );
  }
  if (startsUnit || lower.startsWith('title:') || text.startsWith('عنوان')) {
    return _GrammarLessonLine(
      text: text,
      kind: _dominantDirectionIsRtl(text)
          ? _GrammarLessonLineKind.local
          : _GrammarLessonLineKind.heading,
      hasExplicitLabel: false,
    );
  }
  if (_dominantDirectionIsRtl(text)) {
    return _GrammarLessonLine(
      text: text,
      kind: _GrammarLessonLineKind.local,
      hasExplicitLabel: false,
    );
  }
  return _GrammarLessonLine(
    text: text,
    kind: _GrammarLessonLineKind.english,
    hasExplicitLabel: false,
  );
}

class _GrammarLessonSectionMarker {
  const _GrammarLessonSectionMarker({required this.label, this.title});

  final String label;
  final String? title;
}

_GrammarLessonSectionMarker? _grammarLessonSectionMarker(String text) {
  final trimmed = text.trim();
  final marker = RegExp(
    r'^\s*([a-zA-Z])(?:\s*[\):,]|\s*[-_]+)?\s*(.*)$',
  ).firstMatch(trimmed);
  if (marker != null) {
    final hasSeparator = RegExp(
      r'^\s*[a-zA-Z]\s*(?:[\):,]|[-_]+)',
    ).hasMatch(trimmed);
    final title = marker.group(2)?.trim();
    if (!hasSeparator && (title == null || title.isNotEmpty)) return null;
    return _GrammarLessonSectionMarker(
      label: marker.group(1)!.toUpperCase(),
      title: title == null || title.isEmpty ? null : title,
    );
  }
  return null;
}

bool _dominantDirectionIsRtl(String text) {
  var rtl = 0;
  var latin = 0;
  for (final r in text.runes) {
    if ((r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      rtl++;
    } else if ((r >= 0x0041 && r <= 0x005A) || (r >= 0x0061 && r <= 0x007A)) {
      latin++;
    }
  }
  return rtl > latin;
}

int? _extractGrammarUnitNumber(String raw) {
  final match = RegExp(r'\bunit\s+(\d+)', caseSensitive: false).firstMatch(raw);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

class _CenteredLessonMessage extends StatelessWidget {
  const _CenteredLessonMessage({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
        ),
      ),
    );
  }
}

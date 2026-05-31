import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../l10n/app_localizations.dart';
import 'sample_aligned_text.dart';
import 'sample_english_word_tap_text.dart';
import 'sample_text_highlight_ui.dart';
import 'sample_book_page_sound.dart';
import 'sample_text_highlights_controller.dart';
import 'sample_text_scale.dart';
import 'sample_tts_player.dart';

class SampleBookPageContent {
  const SampleBookPageContent({
    required this.english,
    required this.local,
    required this.paragraphIndex,
  });

  final String english;
  final String local;
  final int paragraphIndex;

  bool get isEmpty => english.trim().isEmpty && local.trim().isEmpty;
}

List<SampleBookPageContent> buildSampleBookPages(String combinedText) {
  final pairs = mergeOrphanBookPairs(parseSampleAlignedPairs(combinedText));
  return pairs
      .asMap()
      .entries
      .map(
        (e) => SampleBookPageContent(
          english: e.value.en,
          local: e.value.local,
          paragraphIndex: e.key,
        ),
      )
      .where((p) => !p.isEmpty)
      .toList();
}

void openSampleBookReader(
  BuildContext context, {
  required String title,
  required String textEnFa,
  required String textEnKur,
  required TranslationLang initialLang,
  required int bookId,
  required int unit,
  required int sampleId,
}) {
  final faPages = buildSampleBookPages(textEnFa);
  final kurPages = buildSampleBookPages(textEnKur);
  if (faPages.isEmpty && kurPages.isEmpty) return;

  Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SampleBookReaderScreen(
            title: title,
            textEnFa: textEnFa,
            textEnKur: textEnKur,
            initialLang: initialLang,
            bookId: bookId,
            unit: unit,
            sampleId: sampleId,
          ),
        );
      },
    ),
  );
}

class SampleBookReaderScreen extends ConsumerStatefulWidget {
  const SampleBookReaderScreen({
    super.key,
    required this.title,
    required this.textEnFa,
    required this.textEnKur,
    required this.initialLang,
    required this.bookId,
    required this.unit,
    required this.sampleId,
  });

  final String title;
  final String textEnFa;
  final String textEnKur;
  final TranslationLang initialLang;
  final int bookId;
  final int unit;
  final int sampleId;

  @override
  ConsumerState<SampleBookReaderScreen> createState() =>
      _SampleBookReaderScreenState();
}

class _SampleBookReaderScreenState
    extends ConsumerState<SampleBookReaderScreen> {
  late final PageController _pageController;
  late TranslationLang _bookLang;
  int _pageIndex = 0;
  bool _pageTurnSoundReady = false;
  int? _pageTurnSoundArmedFor;
  int? _programmaticTurnTarget;

  @override
  void initState() {
    super.initState();
    _bookLang = widget.initialLang;
    _pageController = PageController();
    _pageController.addListener(_onPageControllerScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(sampleBookPageSoundServiceProvider).warmUp());
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageControllerScroll);
    unawaited(stopSampleTts(ref));
    _pageController.dispose();
    super.dispose();
  }

  void _onPageControllerScroll() {
    if (!_pageTurnSoundReady || !_pageController.hasClients) return;
    if (_programmaticTurnTarget != null) return;
    final position = _pageController.position;
    if (!position.isScrollingNotifier.value) return;

    final page = _pageController.page;
    if (page == null) return;

    final from = _pageIndex;
    final offset = page - from;
    if (offset.abs() < 0.12) return;

    final to = offset > 0 ? from + 1 : from - 1;
    if (to < 0 || to >= _activePages.length) return;
    _armPageTurnSound(to: to, forward: to > from);
  }

  void _armPageTurnSound({required int to, required bool forward}) {
    if (!_pageTurnSoundReady) return;
    if (_pageTurnSoundArmedFor == to) return;
    _pageTurnSoundArmedFor = to;
    _playPageTurnSound(forward: forward);
  }

  SampleBookPageContent? get _currentPage {
    final pages = _activePages;
    if (_pageIndex < 0 || _pageIndex >= pages.length) return null;
    return pages[_pageIndex];
  }

  String get _currentParagraphEnglish => _currentPage?.english.trim() ?? '';

  Future<void> _onPlayTap() async {
    if (widget.sampleId <= 0) return;
    final page = _currentPage;
    final paragraphText = page?.english.trim() ?? '';
    if (paragraphText.isEmpty) return;

    final notifier = ref.read(ttsProvider.notifier);
    final tts = ref.read(ttsProvider);

    if (tts.hasActivePlayback && tts.activeText == paragraphText) {
      if (tts.isPaused) {
        await notifier.resume();
      } else {
        await notifier.pause();
      }
      return;
    }

    openSampleParagraphSession(
      ref,
      sampleId: widget.sampleId,
      sampleTitle: widget.title,
      paragraphIndex: page!.paragraphIndex,
      paragraphEnglishText: paragraphText,
    );
    await notifier.speak(paragraphText, showMiniPlayer: false);
  }

  List<SampleBookPageContent> get _activePages => buildSampleBookPages(
    _bookLang == TranslationLang.fa ? widget.textEnFa : widget.textEnKur,
  );

  String get _activeLangKey => sampleTextLangKey(_bookLang);

  void _onBookLangChanged(Set<TranslationLang> set) {
    if (set.isEmpty) return;
    final next = set.first;
    if (next == _bookLang) return;
    ref.read(langProvider.notifier).setLang(next);
    setState(() {
      _bookLang = next;
      _pageIndex = 0;
      _pageTurnSoundReady = false;
      _pageTurnSoundArmedFor = null;
    });
    unawaited(stopSampleTts(ref));
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _goToPage(int index) async {
    if (index < 0 || index >= _activePages.length) return;
    if (index == _pageIndex) return;

    _programmaticTurnTarget = index;
    _armPageTurnSound(to: index, forward: index > _pageIndex);
    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    } finally {
      _programmaticTurnTarget = null;
    }
    HapticFeedback.selectionClick();
  }

  void _previousPage() => _goToPage(_pageIndex - 1);

  void _nextPage() => _goToPage(_pageIndex + 1);

  void _playPageTurnSound({required bool forward}) {
    if (!_pageTurnSoundReady) return;
    final enabled = ref.read(sampleBookPageSoundEnabledProvider);
    unawaited(
      ref.read(sampleBookPageSoundServiceProvider).playPageTurn(
            enabled: enabled,
            forward: forward,
            isStillEnabled: () =>
                ref.read(sampleBookPageSoundEnabledProvider),
          ),
    );
  }

  void _togglePageTurnSound() {
    final wasEnabled = ref.read(sampleBookPageSoundEnabledProvider);
    if (wasEnabled) {
      unawaited(ref.read(sampleBookPageSoundServiceProvider).stop());
    }
    unawaited(ref.read(sampleBookPageSoundEnabledProvider.notifier).toggle());
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pages = _activePages;
    final total = pages.length;
    final canPrev = _pageIndex > 0;
    final canNext = _pageIndex < total - 1;
    final paragraphText = _currentParagraphEnglish;
    final canPlay = widget.sampleId > 0 && paragraphText.isNotEmpty;
    final playSlice = ref.watch(
      ttsProvider.select(
        (s) => (
          active: s.hasActivePlayback && s.activeText == paragraphText,
          paused: s.isPaused,
        ),
      ),
    );
    final pageSoundEnabled = ref.watch(sampleBookPageSoundEnabledProvider);
    final segmentTextStyle = tt.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(stopSampleTts(ref));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2C1810),
        body: SafeArea(
          child: SampleTtsPlayerScope(
            child: Column(
              children: [
                ColoredBox(
                  color: scheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SegmentedButton<TranslationLang>(
                          segments: [
                            ButtonSegment(
                              value: TranslationLang.fa,
                              label: Text(
                                l10n.translationLangPersian,
                                style: segmentTextStyle,
                              ),
                            ),
                            ButtonSegment(
                              value: TranslationLang.kur,
                              label: Text(
                                l10n.translationLangKurdiTab,
                                style: segmentTextStyle,
                              ),
                            ),
                          ],
                          selected: {_bookLang},
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.standard,
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            minimumSize: WidgetStateProperty.all(
                              const Size(0, 42),
                            ),
                          ),
                          onSelectionChanged: _onBookLangChanged,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: IconButton(
                            tooltip: l10n.close,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: tt.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              total == 0
                                  ? l10n.unitSamplesEmpty
                                  : l10n.sampleBookPageOf(
                                      _pageIndex + 1,
                                      total,
                                    ),
                              style: tt.labelSmall?.copyWith(
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: total == 0
                      ? Center(
                          child: Text(
                            l10n.unitSamplesEmpty,
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Stack(
                            children: [
                              PageView.builder(
                                key: ValueKey(_bookLang),
                                controller: _pageController,
                                itemCount: total,
                                onPageChanged: (i) {
                                  final pages = _activePages;
                                  final session = ref.read(
                                    sampleTtsSessionProvider,
                                  );
                                  if (session != null &&
                                      i < pages.length &&
                                      (session.paragraphIndex !=
                                              pages[i].paragraphIndex ||
                                          session.paragraphEnglishText !=
                                              pages[i].english.trim())) {
                                    unawaited(stopSampleTts(ref));
                                  }
                                  if (!_pageTurnSoundReady) {
                                    _pageTurnSoundReady = true;
                                  }
                                  setState(() => _pageIndex = i);
                                  HapticFeedback.selectionClick();
                                },
                                itemBuilder: (context, index) {
                                  return _BookPageSheet(
                                    page: pages[index],
                                    pageNumber: index + 1,
                                    bookId: widget.bookId,
                                    unit: widget.unit,
                                    sampleId: widget.sampleId,
                                    sampleTitle: widget.title,
                                    langKey: _activeLangKey,
                                  );
                                },
                              ),
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: canPrev ? _previousPage : null,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: AnimatedOpacity(
                                            opacity: canPrev ? 0.55 : 0.0,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(
                                                Icons.chevron_left_rounded,
                                                size: 36,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: SizedBox()),
                                    SizedBox(
                                      width: 52,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: canNext ? _nextPage : null,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: AnimatedOpacity(
                                            opacity: canNext ? 0.55 : 0.0,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                right: 4,
                                              ),
                                              child: Icon(
                                                Icons.chevron_right_rounded,
                                                size: 36,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      Text(
                        l10n.sampleBookTurnHint,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.05),
                                  disabledForegroundColor: Colors.white30,
                                ),
                                onPressed: canPrev ? _previousPage : null,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Text(
                                  '${_pageIndex + 1} / $total',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                tooltip: playSlice.active && !playSlice.paused
                                    ? l10n.samplePauseFullText
                                    : l10n.samplePlayFullText,
                                style: IconButton.styleFrom(
                                  backgroundColor: playSlice.active
                                      ? scheme.primary.withValues(alpha: 0.85)
                                      : Colors.white.withValues(alpha: 0.12),
                                  foregroundColor: playSlice.active
                                      ? scheme.onPrimary
                                      : Colors.white,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.05),
                                  disabledForegroundColor: Colors.white30,
                                ),
                                onPressed: canPlay ? _onPlayTap : null,
                                icon: Icon(
                                  playSlice.active && !playSlice.paused
                                      ? Icons.pause_rounded
                                      : Icons.headphones_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: scheme.primary.withValues(
                                    alpha: 0.85,
                                  ),
                                  foregroundColor: scheme.onPrimary,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.05),
                                  disabledForegroundColor: Colors.white30,
                                ),
                                onPressed: canNext ? _nextPage : null,
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: IconButton.filledTonal(
                              tooltip: pageSoundEnabled
                                  ? l10n.sampleBookPageSoundOff
                                  : l10n.sampleBookPageSoundOn,
                              style: IconButton.styleFrom(
                                backgroundColor: pageSoundEnabled
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.06),
                                foregroundColor: pageSoundEnabled
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              onPressed: _togglePageTurnSound,
                              icon: Icon(
                                pageSoundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPageSheet extends ConsumerStatefulWidget {
  const _BookPageSheet({
    required this.page,
    required this.pageNumber,
    required this.bookId,
    required this.unit,
    required this.sampleId,
    required this.sampleTitle,
    required this.langKey,
  });

  final SampleBookPageContent page;
  final int pageNumber;
  final int bookId;
  final int unit;
  final int sampleId;
  final String sampleTitle;
  final String langKey;

  @override
  ConsumerState<_BookPageSheet> createState() => _BookPageSheetState();
}

class _ActiveBookHighlight {
  const _ActiveBookHighlight({
    required this.selection,
    required this.plainText,
    required this.langKey,
    required this.paragraphIndex,
    required this.textKey,
    required this.textStyle,
    required this.textDirection,
    required this.textAlign,
  });

  final TextSelection selection;
  final String plainText;
  final String langKey;
  final int paragraphIndex;
  final GlobalKey textKey;
  final TextStyle textStyle;
  final TextDirection textDirection;
  final TextAlign textAlign;
}

class _BookPageSheetState extends ConsumerState<_BookPageSheet> {
  static const _paper = Color(0xFFFAF3E8);
  static const _paperShadow = Color(0xFFDFD3C0);

  final _scrollController = ScrollController();
  final _pageStackKey = GlobalKey();
  final _englishAnchorKey = GlobalKey();
  final _localAnchorKey = GlobalKey();
  final _englishTextKey = GlobalKey<SampleEnglishWordTapTextState>();
  final _localTextKey = GlobalKey<SampleLocalHighlightTextState>();

  _ActiveBookHighlight? _activeHighlight;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_activeHighlight != null && mounted) setState(() {});
  }

  void _scheduleOverlayLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onEnglishSelectionChanged(TextSelection? selection, String plainText) {
    _localTextKey.currentState?.dismissHighlightUi();
    setState(() {
      if (selection == null || !selection.isValid || selection.isCollapsed) {
        _activeHighlight = null;
        return;
      }
      _activeHighlight = _ActiveBookHighlight(
        selection: selection,
        plainText: plainText,
        langKey: widget.langKey,
        paragraphIndex: widget.page.paragraphIndex,
        textKey: _englishAnchorKey,
        textStyle: _englishStyle(
          Theme.of(context).textTheme,
          ref.read(samplesTextScaleProvider),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );
    });
    _scheduleOverlayLayout();
  }

  void _onLocalSelectionChanged(TextSelection? selection, String plainText) {
    _englishTextKey.currentState?.dismissHighlightUi();
    setState(() {
      if (selection == null || !selection.isValid || selection.isCollapsed) {
        _activeHighlight = null;
        return;
      }
      _activeHighlight = _ActiveBookHighlight(
        selection: selection,
        plainText: plainText,
        langKey: sampleLocalHighlightLangKey(widget.langKey),
        paragraphIndex: widget.page.paragraphIndex,
        textKey: _localAnchorKey,
        textStyle: _localStyle(
          Theme.of(context).textTheme,
          ref.read(samplesTextScaleProvider),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      );
    });
    _scheduleOverlayLayout();
  }

  void _clearActiveHighlight() {
    final active = _activeHighlight;
    if (active == null) return;
    if (active.textDirection == TextDirection.ltr) {
      _englishTextKey.currentState?.dismissHighlightUi();
    } else {
      _localTextKey.currentState?.dismissHighlightUi();
    }
    setState(() => _activeHighlight = null);
  }

  void _dismissAllHighlightUi() {
    _englishTextKey.currentState?.dismissHighlightUi();
    _localTextKey.currentState?.dismissHighlightUi();
    setState(() => _activeHighlight = null);
  }

  TextStyle _englishStyle(TextTheme tt, double textScale) {
    final baseEn = (tt.bodyLarge?.fontSize ?? 16) * textScale;
    return TextStyle(
      fontFamily: 'serif',
      fontSize: baseEn,
      height: 1.75,
      color: const Color(0xFF2A2118),
      letterSpacing: 0.15,
    );
  }

  TextStyle _localStyle(TextTheme tt, double textScale) {
    final baseLocal = (tt.bodyMedium?.fontSize ?? 14) * textScale;
    return TextStyle(
      fontFamily: 'serif',
      fontSize: baseLocal,
      height: 1.85,
      color: const Color(0xFF3D342A),
    );
  }

  Offset? _highlightBarOffset(_ActiveBookHighlight active) {
    final stackContext = _pageStackKey.currentContext;
    final textBox =
        active.textKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = stackContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || textBox == null || !textBox.hasSize) return null;

    final maxWidth = textBox.size.width;
    if (maxWidth <= 0) return null;

    final painter = TextPainter(
      text: TextSpan(text: active.plainText, style: active.textStyle),
      textDirection: active.textDirection,
      textAlign: active.textAlign,
      textWidthBasis: TextWidthBasis.parent,
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    final boxes = painter.getBoxesForSelection(
      TextSelection(
        baseOffset: active.selection.start,
        extentOffset: active.selection.end,
      ),
    );
    if (boxes.isEmpty) return null;

    final anchor = boxes.last;
    final textTopLeft = stackBox.globalToLocal(
      textBox.localToGlobal(Offset.zero),
    );
    final barTop = textTopLeft.dy + anchor.bottom + 6;
    final metrics = SampleHighlightBarMetrics.forWidth(stackBox.size.width);
    final barWidthEstimate = metrics.estimatedBarWidth(hasTrailing: true);
    final maxLeft = (stackBox.size.width - barWidthEstimate - 8).clamp(
      8.0,
      double.infinity,
    );
    final barLeft = (textTopLeft.dx + anchor.left).clamp(8.0, maxLeft);

    return Offset(barLeft, barTop);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final textScale = ref.watch(samplesTextScaleProvider);
    final en = widget.page.english.trim();
    final local = widget.page.local.trim();
    final enStyle = _englishStyle(tt, textScale);
    final localStyle = _localStyle(tt, textScale);
    final active = _activeHighlight;
    final barOffset = active == null ? null : _highlightBarOffset(active);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _paperShadow.withValues(alpha: 0.8),
                  blurRadius: 0,
                  spreadRadius: 1,
                  offset: const Offset(-3, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ColoredBox(
                color: _paper,
                child: Stack(
                  key: _pageStackKey,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 10,
                      child: Text(
                        '${widget.pageNumber}',
                        style: tt.labelSmall?.copyWith(
                          color: const Color(0xFF8D7B68),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TapRegion(
                      groupId: sampleHighlightTapRegionGroup,
                      onTapOutside: (_) => _dismissAllHighlightUi(),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          22,
                          28,
                          18,
                          24 + kSampleBookTextSizeBarHeight,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight -
                                28 -
                                (24 + kSampleBookTextSizeBarHeight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (en.isNotEmpty)
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: KeyedSubtree(
                                    key: _englishAnchorKey,
                                    child: SampleEnglishWordTapText(
                                      key: _englishTextKey,
                                      plainEn: en,
                                      baseStyle: enStyle,
                                      scheme: scheme,
                                      bookId: widget.bookId,
                                      unit: widget.unit,
                                      sampleId: widget.sampleId,
                                      sampleTitle: widget.sampleTitle,
                                      langKey: widget.langKey,
                                      paragraphIndex:
                                          widget.page.paragraphIndex,
                                      textAlign: TextAlign.left,
                                      useExternalHighlightBar: true,
                                      onHighlightSelectionChanged:
                                          _onEnglishSelectionChanged,
                                    ),
                                  ),
                                ),
                              if (en.isNotEmpty && local.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Divider(
                                  color: const Color(
                                    0xFF8D7B68,
                                  ).withValues(alpha: 0.35),
                                  height: 1,
                                ),
                                const SizedBox(height: 18),
                              ],
                              if (local.isNotEmpty)
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: KeyedSubtree(
                                      key: _localAnchorKey,
                                      child: SampleLocalHighlightText(
                                        key: _localTextKey,
                                        plainLocal: local,
                                        baseStyle: localStyle,
                                        sampleId: widget.sampleId,
                                        langKey: sampleLocalHighlightLangKey(
                                          widget.langKey,
                                        ),
                                        paragraphIndex:
                                            widget.page.paragraphIndex,
                                        useExternalHighlightBar: true,
                                        onHighlightSelectionChanged:
                                            _onLocalSelectionChanged,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SampleBookHorizontalTextSizeSlider(),
                    ),
                    if (active != null &&
                        barOffset != null &&
                        widget.sampleId > 0)
                      Positioned(
                        left: barOffset.dx,
                        top: barOffset.dy,
                        child: TapRegion(
                          groupId: sampleHighlightTapRegionGroup,
                          child: SampleHighlightSelectionBar(
                            floating: true,
                            sampleId: widget.sampleId,
                            langKey: active.langKey,
                            paragraphIndex: active.paragraphIndex,
                            plainText: active.plainText,
                            selection: active.selection,
                            onClearSelection: _clearActiveHighlight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

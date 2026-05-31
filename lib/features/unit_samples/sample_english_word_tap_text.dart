import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tts/tts_service.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/widgets/word_card.dart';
import 'sample_text_highlight_rendering.dart';
import 'sample_text_highlight_ui.dart';
import 'sample_text_highlights_controller.dart';
import 'sample_tts_player.dart';
import 'sample_vocab_lookup.dart';

class SampleEnglishWordTapText extends ConsumerStatefulWidget {
  const SampleEnglishWordTapText({
    super.key,
    required this.plainEn,
    required this.baseStyle,
    required this.scheme,
    required this.bookId,
    required this.unit,
    required this.sampleId,
    required this.sampleTitle,
    required this.langKey,
    required this.paragraphIndex,
    this.onTextSelectionActive,
    this.onHighlightSelectionChanged,
    this.useExternalHighlightBar = false,
    this.textAlign = TextAlign.justify,
  });

  final String plainEn;
  final TextStyle? baseStyle;
  final ColorScheme scheme;
  final int bookId;
  final int unit;
  final int sampleId;
  final String sampleTitle;
  final String langKey;
  final int paragraphIndex;
  final VoidCallback? onTextSelectionActive;
  final void Function(TextSelection? selection, String plainText)?
      onHighlightSelectionChanged;
  final bool useExternalHighlightBar;
  final TextAlign textAlign;

  @override
  ConsumerState<SampleEnglishWordTapText> createState() =>
      SampleEnglishWordTapTextState();
}

class SampleEnglishWordTapTextState
    extends ConsumerState<SampleEnglishWordTapText> {
  final List<TapGestureRecognizer> _tapRecognizers = [];
  TextSelection? _textSelection;
  (int start, int end)? _lastAutoHighlighted;
  int? _lastTappedTokenIndex;
  Key _selectableKey = UniqueKey();

  @override
  void dispose() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SampleEnglishWordTapText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plainEn != widget.plainEn) {
      for (final r in _tapRecognizers) {
        r.dispose();
      }
      _tapRecognizers.clear();
      _lastTappedTokenIndex = null;
    }
  }

  void _ensureTapRecognizerCount(int count) {
    if (count < 0) return;
    while (_tapRecognizers.length < count) {
      _tapRecognizers.add(TapGestureRecognizer());
    }
    while (_tapRecognizers.length > count) {
      _tapRecognizers.removeLast().dispose();
    }
  }

  void _openVocabMatchesSheet(List<VocabEntry> entries, {String? tappedText}) {
    if (entries.isEmpty) return;
    final theme = Theme.of(context);
    final uiLang = Localizations.localeOf(context).languageCode;
    final cardLang = sampleTranslationLangFromKey(widget.langKey);
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
        final maxH = MediaQuery.sizeOf(ctx).height * 0.88;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    divider,
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, padBottom + 16),
                      child: WordCard(
                        entry: entries.first,
                        translationLang: cardLang,
                      ),
                    ),
                  ],
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
                        translationLang: cardLang,
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

  void dismissHighlightUi() {
    setState(() {
      _textSelection = null;
      _lastAutoHighlighted = null;
      _selectableKey = UniqueKey();
    });
  }

  void _clearTextSelection() {
    dismissHighlightUi();
    widget.onHighlightSelectionChanged?.call(null, widget.plainEn);
  }

  Future<void> _autoHighlightSelection(TextSelection sel) async {
    if (widget.sampleId <= 0) return;
    final preview = sampleHighlightSelectionPreview(widget.plainEn, sel);
    if (preview.isEmpty) return;

    final range = (sel.start, sel.end);
    if (_lastAutoHighlighted == range) return;

    final color = ref.read(sampleTextHighlightsProvider).defaultColor;
    await ref
        .read(sampleTextHighlightsProvider.notifier)
        .replaceHighlightForSelection(
          sampleId: widget.sampleId,
          langKey: widget.langKey,
          paragraphIndex: widget.paragraphIndex,
          start: sel.start,
          end: sel.end,
          plainText: widget.plainEn,
          color: color,
        );
    _lastAutoHighlighted = range;
    HapticFeedback.selectionClick();
  }

  bool _isSamplePlayerContext() {
    if (isSamplePlayerActiveFor(ref, sampleId: widget.sampleId)) {
      return true;
    }
    final tts = ref.read(ttsProvider);
    return tts.hasActivePlayback && tts.activeText == widget.plainEn;
  }

  void _onWordTap(
    int startTokenIndex,
    List<EnWordToken> tokens,
    List<VocabEntry> catalog,
  ) {
    if (startTokenIndex < 0 || startTokenIndex >= tokens.length) return;

    if (_isSamplePlayerContext()) {
      if (_lastTappedTokenIndex == startTokenIndex) {
        _lastTappedTokenIndex = null;
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
          preferredBookId: widget.bookId,
          preferredUnit: widget.unit,
        );
        if (matches.isEmpty) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text(l10n!.noMatchingWords)));
          return;
        }
        _openVocabMatchesSheet(
          matches,
          tappedText: bestTappedPhrase(
            tokens: tokens,
            startTokenIndex: startTokenIndex,
          ),
        );
        return;
      }

      _lastTappedTokenIndex = startTokenIndex;
      final token = tokens[startTokenIndex];
      openSampleParagraphSession(
        ref,
        sampleId: widget.sampleId,
        sampleTitle: widget.sampleTitle,
        paragraphIndex: widget.paragraphIndex,
        paragraphEnglishText: widget.plainEn,
      );
      HapticFeedback.lightImpact();
      unawaited(
        ref.read(ttsProvider.notifier).speakFrom(
          widget.plainEn,
          token.start,
          showMiniPlayer: false,
          allowToggleStop: false,
        ),
      );
      return;
    }

    _lastTappedTokenIndex = null;
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
      preferredBookId: widget.bookId,
      preferredUnit: widget.unit,
    );
    if (matches.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n!.noMatchingWords)));
      return;
    }
    _openVocabMatchesSheet(
      matches,
      tappedText: bestTappedPhrase(
        tokens: tokens,
        startTokenIndex: startTokenIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.plainEn;
    final catalogAsync = ref.watch(apiAllWordsCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? const <VocabEntry>[];
    final userHighlights = ref.watch(
      sampleTextHighlightsProvider.select(
        (s) => s.forParagraph(
          sampleId: widget.sampleId,
          langKey: widget.langKey,
          paragraphIndex: widget.paragraphIndex,
        ),
      ),
    );

    if (en.isEmpty) return const SizedBox.shrink();

    final tokens = tokenizeEnglishWords(en);
    _ensureTapRecognizerCount(tokens.length);

    final spanChildren = buildEnglishSpans(
      en: en,
      tokens: tokens,
      userHighlights: userHighlights,
      baseStyle: widget.baseStyle,
      ttsReadStyle: widget.baseStyle,
      ttsCurrentStyle: widget.baseStyle,
      ttsLingering: false,
      ttsKaraoke: false,
      ttsA: 0,
      ttsB: 0,
      tapRecognizers: _tapRecognizers,
      onWordTap: (i) => _onWordTap(i, tokens, catalog),
      bidiWrap: (s) => s,
    );
    final rootSpan = spanChildren.isEmpty
        ? TextSpan(text: en, style: widget.baseStyle)
        : TextSpan(style: widget.baseStyle, children: spanChildren);

    final selection = _textSelection;
    final showHighlightBar =
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed &&
        widget.sampleId > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText.rich(
          key: _selectableKey,
          rootSpan,
          textDirection: TextDirection.ltr,
          textAlign: widget.textAlign,
          textWidthBasis: TextWidthBasis.parent,
          onSelectionChanged: (sel, _) {
            if (!mounted) return;
            if (!sel.isValid || sel.isCollapsed) {
              setState(() {
                _textSelection = null;
                _lastAutoHighlighted = null;
              });
              widget.onHighlightSelectionChanged?.call(null, en);
              return;
            }
            setState(() => _textSelection = sel);
            widget.onTextSelectionActive?.call();
            widget.onHighlightSelectionChanged?.call(sel, en);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final current = _textSelection;
              if (current == null ||
                  current.start != sel.start ||
                  current.end != sel.end) {
                return;
              }
              _autoHighlightSelection(sel);
            });
          },
        ),
        if (showHighlightBar && !widget.useExternalHighlightBar)
          SampleHighlightSelectionBar(
            sampleId: widget.sampleId,
            langKey: widget.langKey,
            paragraphIndex: widget.paragraphIndex,
            plainText: en,
            selection: selection,
            onClearSelection: _clearTextSelection,
          ),
      ],
    );
  }
}

String sampleLocalHighlightLangKey(String baseLangKey) => '${baseLangKey}_local';

class SampleLocalHighlightText extends ConsumerStatefulWidget {
  const SampleLocalHighlightText({
    super.key,
    required this.plainLocal,
    required this.baseStyle,
    required this.sampleId,
    required this.langKey,
    required this.paragraphIndex,
    this.onHighlightSelectionChanged,
    this.useExternalHighlightBar = false,
  });

  final String plainLocal;
  final TextStyle? baseStyle;
  final int sampleId;
  final String langKey;
  final int paragraphIndex;
  final void Function(TextSelection? selection, String plainText)?
      onHighlightSelectionChanged;
  final bool useExternalHighlightBar;

  @override
  ConsumerState<SampleLocalHighlightText> createState() =>
      SampleLocalHighlightTextState();
}

class SampleLocalHighlightTextState
    extends ConsumerState<SampleLocalHighlightText> {
  TextSelection? _textSelection;
  (int start, int end)? _lastAutoHighlighted;
  Key _selectableKey = UniqueKey();

  void dismissHighlightUi() {
    setState(() {
      _textSelection = null;
      _lastAutoHighlighted = null;
      _selectableKey = UniqueKey();
    });
  }

  void _clearTextSelection() {
    dismissHighlightUi();
    widget.onHighlightSelectionChanged?.call(null, widget.plainLocal);
  }

  Future<void> _autoHighlightSelection(TextSelection sel) async {
    if (widget.sampleId <= 0) return;
    final preview = sampleHighlightSelectionPreview(widget.plainLocal, sel);
    if (preview.isEmpty) return;

    final range = (sel.start, sel.end);
    if (_lastAutoHighlighted == range) return;

    final color = ref.read(sampleTextHighlightsProvider).defaultColor;
    await ref
        .read(sampleTextHighlightsProvider.notifier)
        .replaceHighlightForSelection(
          sampleId: widget.sampleId,
          langKey: widget.langKey,
          paragraphIndex: widget.paragraphIndex,
          start: sel.start,
          end: sel.end,
          plainText: widget.plainLocal,
          color: color,
        );
    _lastAutoHighlighted = range;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.plainLocal;
    if (local.isEmpty) return const SizedBox.shrink();

    final userHighlights = ref.watch(
      sampleTextHighlightsProvider.select(
        (s) => s.forParagraph(
          sampleId: widget.sampleId,
          langKey: widget.langKey,
          paragraphIndex: widget.paragraphIndex,
        ),
      ),
    );

    final spanChildren = buildEnglishSpans(
      en: local,
      tokens: const [],
      userHighlights: userHighlights,
      baseStyle: widget.baseStyle,
      ttsReadStyle: widget.baseStyle,
      ttsCurrentStyle: widget.baseStyle,
      ttsLingering: false,
      ttsKaraoke: false,
      ttsA: 0,
      ttsB: 0,
      tapRecognizers: const [],
      onWordTap: (_) {},
      bidiWrap: bidiWrapRtlText,
    );
    final rootSpan = spanChildren.isEmpty
        ? TextSpan(text: bidiWrapRtlText(local), style: widget.baseStyle)
        : TextSpan(style: widget.baseStyle, children: spanChildren);

    final selection = _textSelection;
    final showHighlightBar =
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed &&
        widget.sampleId > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText.rich(
          key: _selectableKey,
          rootSpan,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          textWidthBasis: TextWidthBasis.parent,
          onSelectionChanged: (sel, _) {
            if (!mounted) return;
            if (!sel.isValid || sel.isCollapsed) {
              setState(() {
                _textSelection = null;
                _lastAutoHighlighted = null;
              });
              widget.onHighlightSelectionChanged?.call(null, local);
              return;
            }
            setState(() => _textSelection = sel);
            widget.onHighlightSelectionChanged?.call(sel, local);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final current = _textSelection;
              if (current == null ||
                  current.start != sel.start ||
                  current.end != sel.end) {
                return;
              }
              _autoHighlightSelection(sel);
            });
          },
        ),
        if (showHighlightBar && !widget.useExternalHighlightBar)
          SampleHighlightSelectionBar(
            sampleId: widget.sampleId,
            langKey: widget.langKey,
            paragraphIndex: widget.paragraphIndex,
            plainText: local,
            selection: selection,
            onClearSelection: _clearTextSelection,
          ),
      ],
    );
  }
}

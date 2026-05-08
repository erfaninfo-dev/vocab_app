import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/unit_sample.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/widgets/word_card.dart';

typedef _BookUnitKey = ({int bookId, int unit});

final _expandedSampleIdProvider = StateProvider.family
    .autoDispose<int?, _BookUnitKey>((ref, _) => null);

final _samplesTextScaleProvider = StateProvider.family
    .autoDispose<double, _BookUnitKey>((ref, _) => 1.0);

class UnitSamplesScreen extends ConsumerStatefulWidget {
  const UnitSamplesScreen({
    super.key,
    required this.bookId,
    required this.unit,
  });

  final int bookId;
  final int unit;

  @override
  ConsumerState<UnitSamplesScreen> createState() => _UnitSamplesScreenState();
}

class _UnitSamplesScreenState extends ConsumerState<UnitSamplesScreen> {
  @override
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(langProvider); // keep screen reactive to language changes
    final screenKey = (bookId: widget.bookId, unit: widget.unit);
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final async = ref.watch(
      apiUnitSamplesProvider((bookId: widget.bookId, unit: widget.unit)),
    );
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(ttsProvider.notifier).stop();
        if (!context.mounted) return;
        if (context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.unitSamplesTitle(widget.unit)),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primary.withValues(alpha: 0.07), scheme.surface],
            ),
          ),
          child: SafeArea(
            child: async.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.unitSamplesEmpty));
                }
                if (items.length == 1 &&
                    expandedId == null &&
                    items.first.id > 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final current = ref.read(
                      _expandedSampleIdProvider(screenKey),
                    );
                    if (current == null) {
                      ref
                          .read(_expandedSampleIdProvider(screenKey).notifier)
                          .state = items
                          .first
                          .id;
                    }
                  });
                }
                return _SamplesList(
                  screenKey: screenKey,
                  bookId: widget.bookId,
                  unit: widget.unit,
                  items: items,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.unitSamplesLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(
                          apiUnitSamplesProvider((
                            bookId: widget.bookId,
                            unit: widget.unit,
                          )),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.aboutRetryUpdateCheck),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Embedded version of the unit sample texts UI.
///
/// Use this when you want to show sample texts inside another screen (e.g.
/// as a tab in `WordsScreen`) without a separate route or AppBar.
class UnitSamplesEmbedded extends ConsumerStatefulWidget {
  const UnitSamplesEmbedded({
    super.key,
    required this.bookId,
    required this.unit,
    this.listPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final int bookId;
  final int unit;
  final EdgeInsets listPadding;

  @override
  ConsumerState<UnitSamplesEmbedded> createState() =>
      _UnitSamplesEmbeddedState();
}

class _UnitSamplesEmbeddedState extends ConsumerState<UnitSamplesEmbedded> {
  @override
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(langProvider); // keep reactive to language changes
    final screenKey = (bookId: widget.bookId, unit: widget.unit);
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final async = ref.watch(
      apiUnitSamplesProvider((bookId: widget.bookId, unit: widget.unit)),
    );

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          // This embedded widget is usually not shown when empty, but keep
          // a safe fallback.
          return Center(child: Text(l10n.unitSamplesEmpty));
        }
        if (items.length == 1 && expandedId == null && items.first.id > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final current = ref.read(_expandedSampleIdProvider(screenKey));
            if (current == null) {
              ref.read(_expandedSampleIdProvider(screenKey).notifier).state =
                  items.first.id;
            }
          });
        }
        return _SamplesList(
          screenKey: screenKey,
          bookId: widget.bookId,
          unit: widget.unit,
          items: items,
          padding: widget.listPadding,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.unitSamplesLoadFailed)),
    );
  }
}

class _SamplesList extends ConsumerStatefulWidget {
  const _SamplesList({
    required this.screenKey,
    required this.bookId,
    required this.unit,
    required this.items,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 18),
  });

  final _BookUnitKey screenKey;
  final int bookId;
  final int unit;
  final List<UnitSample> items;
  final EdgeInsets padding;

  @override
  ConsumerState<_SamplesList> createState() => _SamplesListState();
}

class _SamplesListState extends ConsumerState<_SamplesList> {
  late final ScrollController _listController;

  @override
  void initState() {
    super.initState();
    _listController = ScrollController();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expandedId = ref.watch(_expandedSampleIdProvider(widget.screenKey));
    final scale = ref.watch(_samplesTextScaleProvider(widget.screenKey));
    return ListView.separated(
      // These sample cards have very dynamic heights (long SelectableText).
      // Laying out a larger cache reduces scroll-metric "jumps" on desktop.
      controller: _listController,
      cacheExtent: 2400,
      padding: widget.padding,
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final i = index;
        return _UnitSampleCard(
          sample: widget.items[i],
          screenKey: widget.screenKey,
          expandedId: expandedId,
          textScale: scale,
          constrainExpandedBody: widget.items.length > 1,
          parentScrollController: _listController,
          onExpandedChanged: (isExpanded) {
            final id = widget.items[i].id;
            if (id <= 0) return;
            final n = ref.read(
              _expandedSampleIdProvider(widget.screenKey).notifier,
            );
            if (isExpanded) {
              n.state = id;
            } else if (expandedId == id) {
              n.state = null;
            }
          },
        );
      },
    );
  }
}

class _UnitSampleCard extends ConsumerStatefulWidget {
  const _UnitSampleCard({
    required this.sample,
    required this.screenKey,
    required this.expandedId,
    required this.textScale,
    required this.constrainExpandedBody,
    required this.parentScrollController,
    required this.onExpandedChanged,
  });
  final UnitSample sample;
  final _BookUnitKey screenKey;
  final int? expandedId;
  final double textScale;

  /// When true (several unit samples), cap expanded body height so the next
  /// sample header stays visible; scroll inside the card for long text.
  final bool constrainExpandedBody;
  final ScrollController parentScrollController;
  final ValueChanged<bool> onExpandedChanged;

  @override
  ConsumerState<_UnitSampleCard> createState() => _UnitSampleCardState();
}

class _UnitSampleCardState extends ConsumerState<_UnitSampleCard> {
  ScrollController? _innerScrollController;
  final GlobalKey _cardLeadKey = GlobalKey();

  void _alignExpandedSampleStart() {
    final inner = _innerScrollController;
    if (inner != null && inner.hasClients) {
      inner.jumpTo(inner.position.minScrollExtent);
    }
    final ctx = _cardLeadKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _propagateOverscrollToParent(double overscroll) {
    final parent = widget.parentScrollController;
    if (!parent.hasClients) return;
    final p = parent.position;
    final next = (p.pixels + overscroll).clamp(0.0, p.maxScrollExtent);
    if (next == p.pixels) return;
    parent.jumpTo(next);
  }

  bool _maybePassEdgeScrollToParent(double delta) {
    final c = _innerScrollController;
    if (c == null || !c.hasClients) return false;
    final pos = c.position;
    final atTop = pos.pixels <= pos.minScrollExtent + 0.5;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 0.5;
    final wantsUp = delta < 0;
    final wantsDown = delta > 0;
    if (!((atTop && wantsUp) || (atBottom && wantsDown))) return false;
    c.jumpTo(atTop ? pos.minScrollExtent : pos.maxScrollExtent);
    _propagateOverscrollToParent(delta);
    return true;
  }

  double _verticalPointerScrollDelta(
    PointerScrollEvent event,
    BuildContext context,
  ) {
    final configuration = ScrollConfiguration.of(context);
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final flipAxes =
        pressed.any(configuration.pointerAxisModifiers.contains) &&
        event.kind == PointerDeviceKind.mouse;
    final axis = flipAxes ? flipAxis(Axis.vertical) : Axis.vertical;
    final raw = switch (axis) {
      Axis.horizontal => event.scrollDelta.dx,
      Axis.vertical => event.scrollDelta.dy,
    };
    return axisDirectionIsReversed(AxisDirection.down) ? -raw : raw;
  }

  void _chainPointerScrollToParentIfInnerFull(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent) return;
    final event = signal;
    final c = _innerScrollController;
    if (c == null || !c.hasClients) return;
    final delta = _verticalPointerScrollDelta(event, context);
    if (delta == 0.0) return;
    final pos = c.position;
    final target = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (target != pos.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _propagateOverscrollToParent(delta);
    });
  }

  void _handleExpansionChanged(bool expanded) {
    widget.onExpandedChanged(expanded);
    if (!expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _alignExpandedSampleStart();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.constrainExpandedBody) {
      _innerScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _innerScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isExpanded =
        widget.expandedId != null && widget.expandedId == widget.sample.id;
    final lang = ref.watch(langProvider);
    final segmentTextStyle = tt.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final cardColor = isExpanded ? scheme.surfaceContainerLow : scheme.surface;
    return Card(
      key: _cardLeadKey,
      elevation: isExpanded ? 0.6 : 2.2,
      shadowColor: scheme.primary.withValues(alpha: 0.12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isExpanded
              ? scheme.outlineVariant.withValues(alpha: 0.55)
              : scheme.primary.withValues(alpha: 0.18),
        ),
      ),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('sample-${widget.sample.id}-expanded-$isExpanded'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: _handleExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.article_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.sample.title.isEmpty ? 'Sample' : widget.sample.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(width: 10),
                SegmentedButton<TranslationLang>(
                  segments: [
                    ButtonSegment(
                      value: TranslationLang.fa,
                      label: Text('فارسی', style: segmentTextStyle),
                    ),
                    ButtonSegment(
                      value: TranslationLang.kur,
                      label: Text('کوردی', style: segmentTextStyle),
                    ),
                  ],
                  selected: {lang},
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                  ),
                  onSelectionChanged: (set) {
                    if (set.isEmpty) return;
                    ref.read(langProvider.notifier).setLang(set.first);
                  },
                ),
              ],
            ],
          ),
          children: [
            if (!widget.constrainExpandedBody)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _AlignedBlock(
                  screenKey: widget.screenKey,
                  combinedText: lang == TranslationLang.fa
                      ? widget.sample.textEnFa
                      : widget.sample.textEnKur,
                  textScale: widget.textScale,
                ),
              )
            else if (isExpanded)
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenH = MediaQuery.sizeOf(context).height;
                  final maxH = (screenH * 0.50).clamp(240.0, 520.0);

                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerSignal: _chainPointerScrollToParentIfInnerFull,
                      child: Scrollbar(
                        controller: _innerScrollController!,
                        thumbVisibility: true,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollUpdateNotification) {
                              final d = n.scrollDelta ?? 0.0;
                              if (d != 0 && _maybePassEdgeScrollToParent(d)) {
                                return true;
                              }
                            }
                            if (n is OverscrollNotification) {
                              if (n.overscroll == 0.0) return false;
                              _propagateOverscrollToParent(n.overscroll);
                              return true;
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _innerScrollController!,
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: _AlignedBlock(
                                screenKey: widget.screenKey,
                                combinedText: lang == TranslationLang.fa
                                    ? widget.sample.textEnFa
                                    : widget.sample.textEnKur,
                                textScale: widget.textScale,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _AlignedBlock extends ConsumerWidget {
  const _AlignedBlock({
    required this.screenKey,
    required this.combinedText,
    required this.textScale,
  });

  final _BookUnitKey screenKey;
  final String combinedText;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pairs = _parseAlignedPairs(combinedText);

    if (pairs.isEmpty) return const SelectableText('—');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _PinchZoomTextScale(
        screenKey: screenKey,
        child: _TextPanel(
          background: scheme.surface,
          border: scheme.outlineVariant.withValues(alpha: 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < pairs.length; i++) ...[
                _ParagraphPairBlock(
                  screenKey: screenKey,
                  pair: pairs[i],
                  textScale: textScale,
                ),
                if (i != pairs.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PinchZoomTextScale extends ConsumerStatefulWidget {
  const _PinchZoomTextScale({
    required this.screenKey,
    required this.child,
  });

  final _BookUnitKey screenKey;
  final Widget child;

  @override
  ConsumerState<_PinchZoomTextScale> createState() => _PinchZoomTextScaleState();
}

class _PinchZoomTextScaleState extends ConsumerState<_PinchZoomTextScale> {
  double _startScale = 1.0;

  static const double _minScale = 0.85;
  static const double _maxScale = 1.55;

  void _setScale(double next) {
    ref.read(_samplesTextScaleProvider(widget.screenKey).notifier).state = next
        .clamp(_minScale, _maxScale);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(_samplesTextScaleProvider(widget.screenKey));
    // `SelectableText` uses its own gesture arena logic and can swallow scale
    // gestures on some Android builds. Using a `RawGestureDetector` with an
    // explicit `ScaleGestureRecognizer` makes pinch-to-zoom reliable.
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(debugOwner: this),
          (recognizer) {
            recognizer
              ..onStart = (_) {
                _startScale = current;
              }
              ..onUpdate = (details) {
                if (details.pointerCount < 2) return;
                _setScale(_startScale * details.scale);
              };
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () => _setScale(1.0),
        child: widget.child,
      ),
    );
  }
}

class _EnWordToken {
  const _EnWordToken({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}

List<_EnWordToken> _tokenizeEnglishWords(String s) {
  final out = <_EnWordToken>[];
  for (final m in RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(s)) {
    out.add(_EnWordToken(start: m.start, end: m.end, text: m.group(0)!));
  }
  return out;
}

/// Normalize an English token/phrase for matching.
///
/// - Lower-cases the input.
/// - Treats anything that is not a letter or apostrophe (e.g. hyphens, slashes,
///   punctuation) as a word boundary, so "part-time" and "part time" match.
/// - Collapses runs of whitespace into single spaces.
String _normalizeForLookup(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z']+"), ' ')
    .trim()
    .replaceAll(RegExp(r"\s+"), ' ');

List<VocabEntry> _lookupCatalogMatches({
  required List<_EnWordToken> tokens,
  required int startTokenIndex,
  required List<VocabEntry> catalog,
  required int preferredBookId,
  required int preferredUnit,
}) {
  if (startTokenIndex < 0 || startTokenIndex >= tokens.length) {
    return const [];
  }

  final tappedWord = _normalizeForLookup(tokens[startTokenIndex].text);
  if (tappedWord.isEmpty) return const [];

  int rank(VocabEntry e) {
    final bid = int.tryParse(e.bookId) ?? -1;
    if (bid != preferredBookId) return 2;
    if (e.unit == preferredUnit) return 0;
    return 1;
  }

  int compareEntries(VocabEntry a, VocabEntry b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    final ab = int.tryParse(a.bookId) ?? -1;
    final bb = int.tryParse(b.bookId) ?? -1;
    if (ab != bb) return ab.compareTo(bb);
    if (a.unit != b.unit) return a.unit.compareTo(b.unit);
    return a.rowId.compareTo(b.rowId);
  }

  final results = <VocabEntry>[];
  final seen = <String>{};

  // Tier 1 — longest exact phrase that starts at the tapped token.
  // Keeps multi-word entries (e.g. "look forward to") prominent when the user
  // taps the entry's first word.
  final maxLen = math.min(6, tokens.length - startTokenIndex);
  for (var len = maxLen; len >= 1; len--) {
    final phraseKey = _normalizeForLookup(
      tokens
          .sublist(startTokenIndex, startTokenIndex + len)
          .map((t) => t.text)
          .join(' '),
    );
    if (phraseKey.isEmpty) continue;
    final exact = catalog
        .where((e) => _normalizeForLookup(e.word) == phraseKey)
        .toList();
    if (exact.isEmpty) continue;
    for (final e in exact) {
      if (seen.add(e.id)) results.add(e);
    }
    break;
  }

  // Tier 2 — every other entry whose tokenised word contains the tapped lemma.
  // This is what surfaces "part-time", "time zone", "free time", … when the
  // user taps "time", regardless of where the tapped word sits in the entry.
  for (final e in catalog) {
    if (seen.contains(e.id)) continue;
    final entryTokens = _normalizeForLookup(e.word).split(' ');
    if (entryTokens.contains(tappedWord)) {
      seen.add(e.id);
      results.add(e);
    }
  }

  if (results.isEmpty) return const [];
  results.sort(compareEntries);
  return results;
}

class _SelectableEnglishWithTtsHighlight extends ConsumerStatefulWidget {
  const _SelectableEnglishWithTtsHighlight({
    required this.plainEn,
    required this.baseStyle,
    required this.scheme,
    required this.bookId,
    required this.unit,
  });

  final String plainEn;
  final TextStyle? baseStyle;
  final ColorScheme scheme;
  final int bookId;
  final int unit;

  @override
  ConsumerState<_SelectableEnglishWithTtsHighlight> createState() =>
      _SelectableEnglishWithTtsHighlightState();
}

class _SelectableEnglishWithTtsHighlightState
    extends ConsumerState<_SelectableEnglishWithTtsHighlight> {
  final List<TapGestureRecognizer> _tapRecognizers = [];

  @override
  void dispose() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SelectableEnglishWithTtsHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plainEn != widget.plainEn) {
      for (final r in _tapRecognizers) {
        r.dispose();
      }
      _tapRecognizers.clear();
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

  void _openVocabMatchesSheet(List<VocabEntry> entries) {
    if (entries.isEmpty) return;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final count = entries.length;
    final lemma = entries.first.word;
    final title = (lang == 'fa' || lang == 'ckb')
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
                      lemma,
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
                      child: WordCard(entry: entries.first),
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
                      itemBuilder: (_, i) => WordCard(entry: entries[i]),
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
    List<_EnWordToken> tokens,
    List<VocabEntry> catalog,
  ) {
    final catalogAsync = ref.read(apiAllWordsCatalogProvider);
    if (catalogAsync.isLoading) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'fa'
                ? 'در حال بارگذاری فهرست لغات…'
                : 'Loading vocabulary…',
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

    final matches = _lookupCatalogMatches(
      tokens: tokens,
      startTokenIndex: startTokenIndex,
      catalog: catalogAsync.value ?? catalog,
      preferredBookId: widget.bookId,
      preferredUnit: widget.unit,
    );
    if (matches.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(l10n?.noMatchingWords ?? 'No matching words found.'),
        ),
      );
      return;
    }
    _openVocabMatchesSheet(matches);
  }

  TextStyle? _styleForWordRange({
    required int ws,
    required int we,
    required bool highlightOn,
    required bool lingering,
    required bool karaoke,
    required int a,
    required int b,
    required TextStyle? readStyle,
    required TextStyle? currentStyle,
  }) {
    if (!highlightOn) return widget.baseStyle;
    if (lingering) return readStyle;
    if (!karaoke) return widget.baseStyle;
    if (we <= a) return readStyle;
    if (a < b && ws < b && we > a) return currentStyle;
    return widget.baseStyle;
  }

  TextSpan _buildTappableEnglishSpan({
    required String en,
    required List<_EnWordToken> tokens,
    required List<VocabEntry> catalog,
    required TextStyle? readStyle,
    required TextStyle? currentStyle,
    required bool highlightOn,
    required bool lingering,
    required bool karaoke,
    required int a,
    required int b,
  }) {
    if (tokens.isEmpty) {
      return TextSpan(text: _bidiWrapLtr(en), style: widget.baseStyle);
    }

    final children = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      if (cursor < tok.start) {
        children.add(
          TextSpan(
            text: _bidiWrapLtr(en.substring(cursor, tok.start)),
            style: widget.baseStyle,
          ),
        );
      }
      final ws = tok.start;
      final we = tok.end;
      final wordStyle = _styleForWordRange(
        ws: ws,
        we: we,
        highlightOn: highlightOn,
        lingering: lingering,
        karaoke: karaoke,
        a: a,
        b: b,
        readStyle: readStyle,
        currentStyle: currentStyle,
      );
      final r = _tapRecognizers[i]..onTap = () => _onWordTap(i, tokens, catalog);
      children.add(
        TextSpan(text: _bidiWrapLtr(tok.text), style: wordStyle, recognizer: r),
      );
      cursor = tok.end;
    }
    if (cursor < en.length) {
      children.add(
        TextSpan(
          text: _bidiWrapLtr(en.substring(cursor)),
          style: widget.baseStyle,
        ),
      );
    }
    return TextSpan(style: widget.baseStyle, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(ttsProvider);
    final highlightOn = ref.watch(ttsTextHighlightEnabledProvider);
    final catalogAsync = ref.watch(apiAllWordsCatalogProvider);
    final catalog = catalogAsync.valueOrNull ?? const <VocabEntry>[];

    final en = widget.plainEn;
    if (en.isEmpty) return const SizedBox.shrink();

    final tokens = _tokenizeEnglishWords(en);
    _ensureTapRecognizerCount(tokens.length);

    final readStyle = widget.baseStyle?.copyWith(
      backgroundColor: widget.scheme.primaryContainer.withValues(alpha: 0.30),
      color: widget.scheme.onPrimaryContainer,
    );
    final currentStyle = widget.baseStyle?.copyWith(
      backgroundColor: widget.scheme.primaryContainer.withValues(alpha: 0.62),
      color: widget.scheme.onPrimaryContainer,
      fontWeight: FontWeight.w800,
    );

    final lingering = tts.showsLingeringFullRead(en);
    final karaoke = highlightOn && tts.isSpeakingText(en);

    final len = en.length;
    var a = 0;
    var b = 0;
    if (karaoke) {
      if (tts.progressStart >= 0 && tts.progressEnd >= 0) {
        a = tts.progressStart.clamp(0, len);
        b = tts.progressEnd.clamp(0, len);
        if (b < a) b = a;
      } else {
        a = tts.spokenTextOffset.clamp(0, len);
        b = a;
      }
      if (b <= a && a < len) {
        b = (a + 1).clamp(0, len);
      }
    }

    final rootSpan = _buildTappableEnglishSpan(
      en: en,
      tokens: tokens,
      catalog: catalog,
      readStyle: readStyle,
      currentStyle: currentStyle,
      highlightOn: highlightOn,
      lingering: lingering,
      karaoke: karaoke,
      a: a,
      b: b,
    );

    return SelectableText.rich(
      rootSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      textWidthBasis: TextWidthBasis.parent,
    );
  }
}

class _ParagraphPairBlock extends ConsumerWidget {
  const _ParagraphPairBlock({
    required this.screenKey,
    required this.pair,
    required this.textScale,
  });

  final _BookUnitKey screenKey;
  final _AlignedPair pair;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);

    final en = pair.en.trim();
    final local = pair.local.trim();
    final enStyle = tt.bodyMedium?.copyWith(
      color: scheme.onSurface,
      height: 1.55,
      fontSize: (tt.bodyMedium?.fontSize ?? 14) * textScale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (en.isNotEmpty) ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectableEnglishWithTtsHighlight(
                    plainEn: en,
                    baseStyle: enStyle,
                    scheme: scheme,
                    bookId: screenKey.bookId,
                    unit: screenKey.unit,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Text size',
                          onPressed: () => _openUnitSamplesTextSizePicker(
                            context,
                            ref,
                            screenKey,
                          ),
                          icon: const Icon(Icons.text_fields_rounded),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          tooltip: tts.isSpeakingText(en)
                              ? (tts.isPaused ? 'Play' : 'Stop')
                              : 'Read',
                          onPressed: () {
                            if (en.isEmpty) return;
                            if (tts.isSpeakingText(en)) {
                              if (tts.isPaused) {
                                notifier.resume();
                              } else {
                                notifier.stop();
                              }
                            } else {
                              notifier.speak(en);
                            }
                          },
                          icon: Icon(
                            tts.isSpeakingText(en)
                                ? (tts.isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.stop_rounded)
                                : Icons.volume_up_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (en.isNotEmpty && local.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ],
        if (local.isNotEmpty) ...[
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: SelectableText(
                _bidiWrapRtl(local),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textWidthBasis: TextWidthBasis.parent,
                style: tt.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.9,
                  fontSize: (tt.bodyMedium?.fontSize ?? 14) * textScale,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _openUnitSamplesTextSizePicker(
  BuildContext context,
  WidgetRef ref,
  _BookUnitKey screenKey,
) async {
  final label = _textSizeLabel(context);
  final current = ref.read(_samplesTextScaleProvider(screenKey));
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.20),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) {
      return _TextSizeOverlay(
        label: label,
        initialValue: current,
        onChanged: (v) =>
            ref.read(_samplesTextScaleProvider(screenKey).notifier).state = v,
      );
    },
    transitionBuilder: (context, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _TextSizeOverlay extends ConsumerStatefulWidget {
  const _TextSizeOverlay({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  ConsumerState<_TextSizeOverlay> createState() => _TextSizeOverlayState();
}

class _TextSizeOverlayState extends ConsumerState<_TextSizeOverlay> {
  late final ValueNotifier<double> _valueN;

  @override
  void initState() {
    super.initState();
    _valueN = ValueNotifier<double>(widget.initialValue);
  }

  @override
  void dispose() {
    _valueN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomExtra =
        ref.watch(
          ttsProvider.select((s) => s.hasActivePlayback && s.showMiniPlayer),
        )
        ? kTtsMiniPlayerBottomReserve
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomExtra,
            child: SafeArea(
              top: false,
              left: false,
              child: Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: _valueN,
                  builder: (context, v, _) {
                    final percent = (v * 100).round();
                    return Material(
                      elevation: 6,
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percent%',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 240,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 10,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 18,
                                    ),
                                  ),
                                  child: Slider(
                                    min: 0.85,
                                    max: 1.55,
                                    divisions: 14,
                                    value: v.clamp(0.85, 1.55),
                                    onChanged: (next) {
                                      _valueN.value = next;
                                      widget.onChanged(next);
                                    },
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _textSizeLabel(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  switch (code) {
    case 'fa':
      return 'اندازه متن';
    case 'ckb':
      return 'قەبارەی دەق';
    default:
      return 'Text size';
  }
}

class _AlignedPair {
  const _AlignedPair(this.en, this.local);
  final String en;
  final String local;
}

List<String> _splitParagraphs(String text) {
  final t = text.trim();
  if (t.isEmpty) return const [];
  return t
      .split(RegExp(r'\n\s*\n+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

List<_AlignedPair> _zipParagraphPairs(String enBlock, String localBlock) {
  final enParts = _splitParagraphs(enBlock);
  final localParts = _splitParagraphs(localBlock);
  final maxLen = enParts.length > localParts.length
      ? enParts.length
      : localParts.length;
  if (maxLen == 0) return const [];
  return List.generate(maxLen, (i) {
    final en = i < enParts.length ? enParts[i] : '';
    final local = i < localParts.length ? localParts[i] : '';
    return _AlignedPair(en, local);
  });
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.background,
    required this.border,
    required this.child,
  });

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }
}

String _bidiWrapLtr(String s) {
  // Force LTR isolation for punctuation-heavy English inside RTL UIs.
  // LRI ... PDI keeps punctuation (., :) from jumping in mixed-direction layouts.
  const lri = '\u2066';
  const pdi = '\u2069';
  return '$lri$s$pdi';
}

String _bidiWrapRtl(String s) {
  // Force RTL isolation for Persian/Sorani inside mixed-direction layouts.
  const rli = '\u2067';
  const pdi = '\u2069';
  return '$rli$s$pdi';
}

String _stripHeadingPrefix(String input) {
  final s = input.trimLeft();
  final lower = s.toLowerCase();
  const prefixes = [
    'english:',
    'en:',
    'فارسی:',
    'کوردی:',
    'كوردی:',
    'کوردی سورانی:',
    'كوردی سورانی:',
    'کوردی (سورانی):',
    'كوردی (سورانی):',
    'kurdish:',
    'kurdish sorani:',
    'kur:',
  ];
  for (final p in prefixes) {
    if (lower.startsWith(p)) {
      return s.substring(p.length).trimLeft();
    }
  }
  return input.trim();
}

List<_AlignedPair> _parseAlignedPairs(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];

  final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).toList();

  // ── Label-based blocks (most common in your CMS) ──────────────────────────
  // Example:
  // English:
  // ...
  // فارسی:
  // ...
  // (or کوردی:)
  bool isEnglishLabel(String line) {
    final s = line.trim().toLowerCase();
    return s == 'english:' ||
        s == 'english :' ||
        s == 'en:' ||
        s == 'en :' ||
        s.startsWith('english:') ||
        s.startsWith('en:');
  }

  bool isLocalLabel(String line) {
    final s = line.trim().toLowerCase();
    return s == 'fa:' ||
        s == 'fa :' ||
        s == 'فارسی:' ||
        s == 'فارسی :' ||
        s == 'کوردی:' ||
        s == 'كوردی:' ||
        s == 'کوردی سورانی:' ||
        s == 'كوردی سورانی:' ||
        s == 'کوردی (سورانی):' ||
        s == 'کوردی (سورانی) :' ||
        s == 'كوردی (سورانی):' ||
        s == 'كوردی (سورانی) :' ||
        s == 'kurdish:' ||
        s == 'kurdish :' ||
        s == 'kurdish sorani:' ||
        s == 'kurdish sorani :' ||
        s == 'kur:' ||
        s == 'kur :';
  }

  final hasAnyLabels = lines.any(isEnglishLabel) || lines.any(isLocalLabel);
  if (hasAnyLabels) {
    final out = <_AlignedPair>[];

    final enBuf = StringBuffer();
    final localBuf = StringBuffer();
    String mode = ''; // 'en' | 'local' | ''

    void flushPair() {
      final en = _stripHeadingPrefix(enBuf.toString().trim());
      final local = _stripHeadingPrefix(localBuf.toString().trim());
      enBuf.clear();
      localBuf.clear();
      if (en.isEmpty && local.isEmpty) return;

      final zipped = _zipParagraphPairs(en, local);
      if (zipped.isNotEmpty) {
        out.addAll(zipped);
      } else {
        out.add(_AlignedPair(en, local));
      }
    }

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (isEnglishLabel(line)) {
        // Switching blocks: commit previous pair.
        if (mode.isNotEmpty && mode != 'en') flushPair();
        mode = 'en';
        final rest = _stripHeadingPrefix(line);
        if (rest.isNotEmpty) {
          enBuf.writeln(rest);
        }
        continue;
      }

      if (isLocalLabel(line)) {
        if (mode.isNotEmpty && mode != 'local') flushPair();
        mode = 'local';
        final rest = _stripHeadingPrefix(line);
        if (rest.isNotEmpty) {
          localBuf.writeln(rest);
        }
        continue;
      }

      if (mode == 'en') {
        enBuf.writeln(line);
        continue;
      }
      if (mode == 'local') {
        localBuf.writeln(line);
        continue;
      }

      // If no explicit mode yet, guess by script.
      final rtlCount = RegExp(r'[\u0600-\u06FF]').allMatches(line).length;
      if (rtlCount > (line.length / 6)) {
        localBuf.writeln(line);
      } else {
        enBuf.writeln(line);
      }
    }

    flushPair();
    return out;
  }

  // Fallback #1: "EN block" then separator line then "local block"
  final sepIndex = lines.indexWhere(
    (l) => l == '---' || l == '—' || l == '–––' || l == '———',
  );
  if (sepIndex >= 0) {
    final en = _stripHeadingPrefix(lines.take(sepIndex).join('\n').trim());
    final local = _stripHeadingPrefix(
      lines.skip(sepIndex + 1).join('\n').trim(),
    );
    if (en.isNotEmpty || local.isNotEmpty) {
      final pairs = _zipParagraphPairs(en, local);
      if (pairs.isNotEmpty) return pairs;
      return [_AlignedPair(en, local)];
    }
  }

  final out = <_AlignedPair>[];

  String? pendingEn;
  for (final line in lines) {
    if (line.isEmpty) continue;

    final lower = line.toLowerCase();
    if (lower.startsWith('en:')) {
      pendingEn = _stripHeadingPrefix(line.substring(3).trim());
      continue;
    }
    if (lower.startsWith('fa:') || lower.startsWith('kur:')) {
      final local = _stripHeadingPrefix(line.substring(line.indexOf(':') + 1));
      if (pendingEn != null && pendingEn.trim().isNotEmpty) {
        out.add(_AlignedPair(pendingEn, local));
        pendingEn = null;
      }
      continue;
    }

    // Fallback: if no prefixes, treat as plain block (LTR).
    if (out.isEmpty) {
      // If the text is mostly RTL, keep it in local (RTL). Otherwise EN.
      final rtlCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
      if (rtlCount > (text.length / 20)) {
        return [_AlignedPair('', _stripHeadingPrefix(text))];
      }
      return [_AlignedPair(_stripHeadingPrefix(text), '')];
    }
  }

  return out;
}

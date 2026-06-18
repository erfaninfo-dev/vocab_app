import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/unit_sample.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'sample_aligned_text.dart';
import 'sample_book_reader.dart';
import 'sample_text_scale.dart';
import 'sample_english_word_tap_text.dart';
import 'sample_reading_lamp_button.dart';
import 'sample_text_highlight_ui.dart';
import 'sample_text_highlights_controller.dart';
import 'sample_tts_player.dart';

typedef _BookUnitKey = ({int bookId, int unit, int? section});

String _sampleSectionBadgeLabel(AppLocalizations l10n, UnitSample sample) {
  final n = sample.section;
  if (n == null || n <= 0) return '';
  return l10n.sectionNumberLabel(n);
}

final _expandedSampleIdProvider = StateProvider.family
    .autoDispose<int?, _BookUnitKey>((ref, _) => null);

class UnitSamplesScreen extends ConsumerStatefulWidget {
  const UnitSamplesScreen({
    super.key,
    required this.bookId,
    required this.unit,
    this.section,
  });

  final int bookId;
  final int unit;

  /// When set (>0), loads unit-wide samples plus samples for this section (server-side filter).
  final int? section;

  @override
  ConsumerState<UnitSamplesScreen> createState() => _UnitSamplesScreenState();
}

class _UnitSamplesScreenState extends ConsumerState<UnitSamplesScreen> {
  late final SampleTtsStopper _sampleTtsStopper;

  @override
  void initState() {
    super.initState();
    _sampleTtsStopper = ref.read(sampleTtsStopperProvider);
  }

  @override
  void dispose() {
    unawaited(_sampleTtsStopper.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(langProvider); // keep screen reactive to language changes
    final screenKey = (
      bookId: widget.bookId,
      unit: widget.unit,
      section: widget.section,
    );
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final async = ref.watch(
      apiUnitSamplesProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(ttsProvider.notifier).stop();
        ref.read(sampleTtsSessionProvider.notifier).state = null;
        if (!context.mounted) return;
        if (context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.section != null && widget.section! > 0
                ? l10n.unitSamplesTitleSection(widget.unit, widget.section!)
                : l10n.unitSamplesTitle(widget.unit),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
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
                return SampleTtsPlayerScope(
                  child: _SampleTextSizeOverlayScope(
                    screenKey: screenKey,
                    child: _SamplesList(
                      screenKey: screenKey,
                      bookId: widget.bookId,
                      unit: widget.unit,
                      items: items,
                    ),
                  ),
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
                            section: widget.section,
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
    this.section,
    this.listPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final int bookId;
  final int unit;
  final int? section;
  final EdgeInsets listPadding;

  @override
  ConsumerState<UnitSamplesEmbedded> createState() =>
      _UnitSamplesEmbeddedState();
}

class _UnitSamplesEmbeddedState extends ConsumerState<UnitSamplesEmbedded> {
  late final SampleTtsStopper _sampleTtsStopper;

  @override
  void initState() {
    super.initState();
    _sampleTtsStopper = ref.read(sampleTtsStopperProvider);
  }

  @override
  void dispose() {
    unawaited(_sampleTtsStopper.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(langProvider); // keep reactive to language changes
    final screenKey = (
      bookId: widget.bookId,
      unit: widget.unit,
      section: widget.section,
    );
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final async = ref.watch(
      apiUnitSamplesProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
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
        return SampleTtsPlayerScope(
          child: _SampleTextSizeOverlayScope(
            screenKey: screenKey,
            child: _SamplesList(
              screenKey: screenKey,
              bookId: widget.bookId,
              unit: widget.unit,
              items: items,
              padding: widget.listPadding,
            ),
          ),
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
          constrainExpandedBody: widget.items.length > 1,
          parentScrollController: _listController,
          onExpandedChanged: (isExpanded) {
            final id = widget.items[i].id;
            if (id <= 0) return;
            final n = ref.read(
              _expandedSampleIdProvider(widget.screenKey).notifier,
            );
            if (isExpanded) {
              final session = ref.read(sampleTtsSessionProvider);
              if (session != null && session.sampleId != id) {
                unawaited(stopSampleTts(ref));
              }
              n.state = id;
            } else if (expandedId == id) {
              final session = ref.read(sampleTtsSessionProvider);
              if (session?.sampleId == id) {
                unawaited(stopSampleTts(ref));
              }
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
    required this.constrainExpandedBody,
    required this.parentScrollController,
    required this.onExpandedChanged,
  });
  final UnitSample sample;
  final _BookUnitKey screenKey;
  final int? expandedId;

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

  void _openSampleBookMode() {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.read(langProvider);
    openSampleBookReader(
      context,
      title: widget.sample.title.isEmpty
          ? l10n.unitSampleUntitled
          : widget.sample.title,
      textEnFa: widget.sample.textEnFa,
      textEnKur: widget.sample.textEnKur,
      initialLang: lang,
      bookId: widget.screenKey.bookId,
      unit: widget.screenKey.unit,
      sampleId: widget.sample.id,
    );
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
    final l10n = AppLocalizations.of(context)!;
    final segmentTextStyle = tt.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final cardColor = isExpanded ? scheme.surfaceContainerLow : scheme.surface;
    final sectionBadge = _sampleSectionBadgeLabel(l10n, widget.sample);
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.sample.title.isEmpty
                              ? l10n.unitSampleUntitled
                              : widget.sample.title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (sectionBadge.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sectionBadge,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SampleReadingLampButton(
                      tooltip: l10n.sampleBookMode,
                      onTap: _openSampleBookMode,
                    ),
                    const Spacer(),
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
                      selected: {lang},
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.standard,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        minimumSize: WidgetStateProperty.all(const Size(0, 42)),
                      ),
                      onSelectionChanged: (set) {
                        if (set.isEmpty) return;
                        ref.read(langProvider.notifier).setLang(set.first);
                      },
                    ),
                  ],
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
                  sampleId: widget.sample.id,
                  sampleTitle: widget.sample.title,
                  langKey: sampleTextLangKey(lang),
                  combinedText: lang == TranslationLang.fa
                      ? widget.sample.textEnFa
                      : widget.sample.textEnKur,
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
                                sampleId: widget.sample.id,
                                sampleTitle: widget.sample.title,
                                langKey: sampleTextLangKey(lang),
                                combinedText: lang == TranslationLang.fa
                                    ? widget.sample.textEnFa
                                    : widget.sample.textEnKur,
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
    required this.sampleId,
    required this.sampleTitle,
    required this.langKey,
    required this.combinedText,
  });

  final _BookUnitKey screenKey;
  final int sampleId;
  final String sampleTitle;
  final String langKey;
  final String combinedText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textScale = ref.watch(samplesTextScaleProvider);
    final pairs = parseSampleAlignedPairs(combinedText);

    if (pairs.isEmpty) return const SelectableText('—');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _SamplesPinchTextScale(
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
                  sampleId: sampleId,
                  sampleTitle: sampleTitle,
                  langKey: langKey,
                  paragraphIndex: i,
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

class _SampleTextSizeOverlayScope extends ConsumerWidget {
  const _SampleTextSizeOverlayScope({
    required this.screenKey,
    required this.child,
  });

  final _BookUnitKey screenKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (expandedId != null)
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: SafeArea(
              right: false,
              child: Center(
                child: _InstagramTextSizeSlider(screenKey: screenKey),
              ),
            ),
          ),
      ],
    );
  }
}

class _InstagramTextSizeSlider extends ConsumerStatefulWidget {
  const _InstagramTextSizeSlider({required this.screenKey});

  final _BookUnitKey screenKey;

  @override
  ConsumerState<_InstagramTextSizeSlider> createState() =>
      _InstagramTextSizeSliderState();
}

class _InstagramTextSizeSliderState
    extends ConsumerState<_InstagramTextSizeSlider> {
  static const double _width = 64;
  static const double _height = 270;
  static const _textUpdateInterval = Duration(milliseconds: 48);
  static const _minPreviewDelta = 0.018;

  var _active = false;
  double? _dragScale;
  DateTime? _lastTextUpdate;

  double _scaleFromDy(double dy, double height) {
    final t = (1 - (dy / height)).clamp(0.0, 1.0);
    return clampSamplesTextScale(
      kSamplesTextScaleMin +
          ((kSamplesTextScaleMax - kSamplesTextScaleMin) * t),
    );
  }

  double _normalizedScale(double scale) =>
      ((clampSamplesTextScale(scale) - kSamplesTextScaleMin) /
              (kSamplesTextScaleMax - kSamplesTextScaleMin))
          .clamp(0.0, 1.0);

  void _previewScaleThrottled(double next) {
    final current = ref.read(samplesTextScaleProvider);
    if ((next - current).abs() < _minPreviewDelta) return;
    final now = DateTime.now();
    if (_lastTextUpdate != null &&
        now.difference(_lastTextUpdate!) < _textUpdateInterval) {
      return;
    }
    _lastTextUpdate = now;
    ref.read(samplesTextScaleProvider.notifier).previewScale(next);
  }

  void _commitDrag(double next) {
    setState(() => _dragScale = next);
    _previewScaleThrottled(next);
  }

  void _finishDrag(double next) {
    _lastTextUpdate = null;
    setState(() {
      _active = false;
      _dragScale = null;
    });
    ref.read(samplesTextScaleProvider.notifier).persistScale(next);
  }

  @override
  Widget build(BuildContext context) {
    final providerScale = ref.watch(samplesTextScaleProvider);
    final scale = _dragScale ?? providerScale;
    final scheme = Theme.of(context).colorScheme;
    final normalized = _normalizedScale(scale);
    final trackColor = scheme.onSurface.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.36 : 0.28,
    );
    final thumbColor = scheme.inverseSurface;
    final activeFillColor = thumbColor.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.34 : 0.22,
    );

    return SizedBox(
      width: _width,
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              setState(() => _active = true);
              _commitDrag(_scaleFromDy(details.localPosition.dy, height));
            },
            onPanUpdate: (details) =>
                _commitDrag(_scaleFromDy(details.localPosition.dy, height)),
            onPanEnd: (_) => _finishDrag(_dragScale ?? providerScale),
            onPanCancel: () => _finishDrag(_dragScale ?? providerScale),
            onTapDown: (details) {
              setState(() => _active = true);
              _commitDrag(_scaleFromDy(details.localPosition.dy, height));
            },
            onTapUp: (_) => _finishDrag(_dragScale ?? providerScale),
            onTapCancel: () => _finishDrag(_dragScale ?? providerScale),
            child: CustomPaint(
              painter: _InstagramTextSizeSliderPainter(
                normalized: normalized,
                active: _active,
                trackColor: trackColor,
                activeFillColor: activeFillColor,
                thumbColor: thumbColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InstagramTextSizeSliderPainter extends CustomPainter {
  const _InstagramTextSizeSliderPainter({
    required this.normalized,
    required this.active,
    required this.trackColor,
    required this.activeFillColor,
    required this.thumbColor,
  });

  final double normalized;
  final bool active;
  final Color trackColor;
  final Color activeFillColor;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = normalized.clamp(0.0, 1.0);
    final knobY = size.height * (1 - progress);
    final centerX = size.width * 0.33;
    final thumbRadius = size.width * 0.203;
    final trackStroke = size.width * 0.031;

    if (active) {
      final easedBody = Curves.easeOutCubic.transform(progress);
      final topHalfWidth =
          size.width * 0.028 + (size.width * 0.164 * easedBody);
      final bottomHalfWidth = size.width * 0.0125;
      final path = Path()
        ..moveTo(centerX - topHalfWidth, 0)
        ..cubicTo(
          centerX - (topHalfWidth * 0.74),
          knobY * 0.34,
          centerX - bottomHalfWidth,
          size.height * 0.76,
          centerX - bottomHalfWidth,
          size.height,
        )
        ..lineTo(centerX + bottomHalfWidth, size.height)
        ..cubicTo(
          centerX + bottomHalfWidth,
          size.height * 0.76,
          centerX + (topHalfWidth * 0.74),
          knobY * 0.34,
          centerX + topHalfWidth,
          0,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = activeFillColor.withValues(alpha: 0.08 + progress * 0.48),
      );
    } else {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, size.height),
        Paint()
          ..color = trackColor
          ..strokeWidth = trackStroke
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset(centerX, knobY),
      thumbRadius,
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(covariant _InstagramTextSizeSliderPainter oldDelegate) {
    return oldDelegate.normalized != normalized ||
        oldDelegate.active != active ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeFillColor != activeFillColor ||
        oldDelegate.thumbColor != thumbColor;
  }
}

class _SamplesPinchTextScale extends ConsumerStatefulWidget {
  const _SamplesPinchTextScale({required this.screenKey, required this.child});

  final _BookUnitKey screenKey;
  final Widget child;

  @override
  ConsumerState<_SamplesPinchTextScale> createState() =>
      _SamplesPinchTextScaleState();
}

class _SamplesPinchTextScaleState
    extends ConsumerState<_SamplesPinchTextScale> {
  static const _textUpdateInterval = Duration(milliseconds: 48);
  static const _minPreviewDelta = 0.018;

  double? _pinchBaseScale;
  DateTime? _lastTextUpdate;

  void _clearPinchBase() => _pinchBaseScale = null;

  void _previewScaleThrottled(double next) {
    final current = ref.read(samplesTextScaleProvider);
    if ((next - current).abs() < _minPreviewDelta) return;
    final now = DateTime.now();
    if (_lastTextUpdate != null &&
        now.difference(_lastTextUpdate!) < _textUpdateInterval) {
      return;
    }
    _lastTextUpdate = now;
    ref.read(samplesTextScaleProvider.notifier).previewScale(next);
  }

  void _finishPinch(double next) {
    _lastTextUpdate = null;
    _clearPinchBase();
    ref.read(samplesTextScaleProvider.notifier).persistScale(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (_) {
        _pinchBaseScale = ref.read(samplesTextScaleProvider);
      },
      onScaleUpdate: (details) {
        final base = _pinchBaseScale;
        if (base == null) return;
        final next = clampSamplesTextScale(base * details.scale);
        _previewScaleThrottled(next);
      },
      onScaleEnd: (_) {
        if (_pinchBaseScale == null) return;
        _finishPinch(ref.read(samplesTextScaleProvider));
      },
      child: widget.child,
    );
  }
}

class _ParagraphPairBlock extends ConsumerStatefulWidget {
  const _ParagraphPairBlock({
    required this.screenKey,
    required this.sampleId,
    required this.sampleTitle,
    required this.langKey,
    required this.paragraphIndex,
    required this.pair,
    required this.textScale,
  });

  final _BookUnitKey screenKey;
  final int sampleId;
  final String sampleTitle;
  final String langKey;
  final int paragraphIndex;
  final SampleAlignedPair pair;
  final double textScale;

  @override
  ConsumerState<_ParagraphPairBlock> createState() =>
      _ParagraphPairBlockState();
}

class _ParagraphPairBlockState extends ConsumerState<_ParagraphPairBlock> {
  final _englishKey = GlobalKey<SampleEnglishWordTapTextState>();
  bool _showDefaultColorPicker = false;

  void _dismissAllHighlightUi() {
    _englishKey.currentState?.dismissHighlightUi();
    if (_showDefaultColorPicker) {
      setState(() => _showDefaultColorPicker = false);
    }
  }

  void _toggleDefaultColorPicker() {
    setState(() {
      _showDefaultColorPicker = !_showDefaultColorPicker;
      if (_showDefaultColorPicker) {
        _englishKey.currentState?.dismissHighlightUi();
      }
    });
  }

  Future<void> _onPlayTap() async {
    final paragraphText = widget.pair.en.trim();
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
      sampleTitle: widget.sampleTitle,
      paragraphIndex: widget.paragraphIndex,
      paragraphEnglishText: paragraphText,
    );
    await notifier.speak(paragraphText, showMiniPlayer: false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final en = widget.pair.en.trim();
    final local = widget.pair.local.trim();
    final enStyle = tt.bodyMedium?.copyWith(
      color: scheme.onSurface,
      height: 1.55,
      fontSize: (tt.bodyMedium?.fontSize ?? 14) * widget.textScale,
    );

    final playSlice = ref.watch(
      ttsProvider.select(
        (s) => (
          active: s.hasActivePlayback && s.activeText == en,
          paused: s.isPaused,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (en.isNotEmpty) ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: double.infinity,
              child: TapRegion(
                groupId: sampleHighlightTapRegionGroup,
                onTapOutside: (_) => _dismissAllHighlightUi(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SampleEnglishWordTapText(
                      key: _englishKey,
                      plainEn: en,
                      baseStyle: enStyle,
                      scheme: scheme,
                      bookId: widget.screenKey.bookId,
                      unit: widget.screenKey.unit,
                      sampleId: widget.sampleId,
                      sampleTitle: widget.sampleTitle,
                      langKey: widget.langKey,
                      paragraphIndex: widget.paragraphIndex,
                      onTextSelectionActive: () {
                        if (_showDefaultColorPicker) {
                          setState(() => _showDefaultColorPicker = false);
                        }
                      },
                    ),
                    if (_showDefaultColorPicker)
                      const SampleDefaultColorPickerBar(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: SampleParagraphToolStrip(
                        showHighlight: widget.sampleId > 0,
                        highlightPickerOpen: _showDefaultColorPicker,
                        onHighlightTap: _toggleDefaultColorPicker,
                        showPlay: en.isNotEmpty,
                        playActive: playSlice.active,
                        playPaused: playSlice.paused,
                        onPlayTap: _onPlayTap,
                      ),
                    ),
                  ],
                ),
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
                bidiWrapRtlText(local),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textWidthBasis: TextWidthBasis.parent,
                style: tt.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.9,
                  fontSize: (tt.bodyMedium?.fontSize ?? 14) * widget.textScale,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
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

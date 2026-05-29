import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/unit_sample.dart';
import '../../data/models/vocab_entry.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/widgets/word_card.dart';
import 'sample_text_highlight_rendering.dart';
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

const double kSamplesTextScaleMin = 0.85;
const double kSamplesTextScaleMax = 1.55;

double clampSamplesTextScale(double value) =>
    value.clamp(kSamplesTextScaleMin, kSamplesTextScaleMax);

final _samplesTextScaleProvider =
    NotifierProvider<_SamplesTextScaleController, double>(
      _SamplesTextScaleController.new,
    );

class _SamplesTextScaleController extends Notifier<double> {
  static const _prefsKey = 'unit_samples_text_scale_v1';

  @override
  double build() {
    _hydrate();
    return 1.0;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey);
    if (saved == null) return;
    state = clampSamplesTextScale(saved);
  }

  void previewScale(double value) {
    final next = clampSamplesTextScale(value);
    if (state == next) return;
    state = next;
  }

  Future<void> persistScale([double? value]) async {
    final next = clampSamplesTextScale(value ?? state);
    if (state != next) {
      state = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, next);
  }

  Future<void> setScale(double value) => persistScale(value);
}

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
  @override
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    ref.read(sampleTtsSessionProvider.notifier).state = null;
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
  @override
  void dispose() {
    ref.read(ttsProvider.notifier).stop();
    ref.read(sampleTtsSessionProvider.notifier).state = null;
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
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SegmentedButton<TranslationLang>(
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
    final textScale = ref.watch(_samplesTextScaleProvider);
    final pairs = _parseAlignedPairs(combinedText);

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
  static const double _width = 52;
  static const double _height = 220;
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
    final current = ref.read(_samplesTextScaleProvider);
    if ((next - current).abs() < _minPreviewDelta) return;
    final now = DateTime.now();
    if (_lastTextUpdate != null &&
        now.difference(_lastTextUpdate!) < _textUpdateInterval) {
      return;
    }
    _lastTextUpdate = now;
    ref.read(_samplesTextScaleProvider.notifier).previewScale(next);
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
    ref.read(_samplesTextScaleProvider.notifier).persistScale(next);
  }

  @override
  Widget build(BuildContext context) {
    final providerScale = ref.watch(_samplesTextScaleProvider);
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
    const centerX = 17.0;

    if (active) {
      final easedBody = Curves.easeOutCubic.transform(progress);
      final topHalfWidth = 1.4 + (8.6 * easedBody);
      const bottomHalfWidth = 0.65;
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
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(Offset(centerX, knobY), 10, Paint()..color = thumbColor);
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
    final current = ref.read(_samplesTextScaleProvider);
    if ((next - current).abs() < _minPreviewDelta) return;
    final now = DateTime.now();
    if (_lastTextUpdate != null &&
        now.difference(_lastTextUpdate!) < _textUpdateInterval) {
      return;
    }
    _lastTextUpdate = now;
    ref.read(_samplesTextScaleProvider.notifier).previewScale(next);
  }

  void _finishPinch(double next) {
    _lastTextUpdate = null;
    _clearPinchBase();
    ref.read(_samplesTextScaleProvider.notifier).persistScale(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (_) {
        _pinchBaseScale = ref.read(_samplesTextScaleProvider);
      },
      onScaleUpdate: (details) {
        final base = _pinchBaseScale;
        if (base == null) return;
        final next = clampSamplesTextScale(base * details.scale);
        _previewScaleThrottled(next);
      },
      onScaleEnd: (_) {
        if (_pinchBaseScale == null) return;
        _finishPinch(ref.read(_samplesTextScaleProvider));
      },
      child: widget.child,
    );
  }
}

List<EnWordToken> _tokenizeEnglishWords(String s) {
  final out = <EnWordToken>[];
  final re = RegExp(r"[A-Za-z]+(?:['\u2019\u2018\u02BC][A-Za-z]+)?");
  for (final m in re.allMatches(s)) {
    out.add(EnWordToken(start: m.start, end: m.end, text: m.group(0)!));
  }
  return out;
}

/// Normalize an English token/phrase for matching.
///
/// - Lower-cases the input.
/// - Treats anything that is not a letter or apostrophe (e.g. hyphens, slashes,
///   punctuation) as a word boundary, so "part-time" and "part time" match.
/// - Collapses runs of whitespace into single spaces.
String _normalizeForLookup(String s) {
  final unified = s
      .replaceAll('\u2019', "'")
      .replaceAll('\u2018', "'")
      .replaceAll('\u02BC', "'");
  return unified
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z']+"), ' ')
      .trim()
      .replaceAll(RegExp(r"\s+"), ' ');
}

bool _isCommonCollocationTail(String word) {
  switch (word) {
    case 'in':
    case 'on':
    case 'at':
    case 'to':
    case 'for':
    case 'of':
    case 'with':
    case 'about':
    case 'from':
    case 'into':
    case 'over':
    case 'under':
    case 'after':
    case 'before':
    case 'between':
    case 'through':
      return true;
    default:
      return false;
  }
}

String? _bestTappedPhrase({
  required List<EnWordToken> tokens,
  required int startTokenIndex,
}) {
  if (startTokenIndex < 0 || startTokenIndex >= tokens.length) return null;
  final head = _normalizeForLookup(tokens[startTokenIndex].text);
  if (head.isEmpty) return null;

  if (startTokenIndex + 1 < tokens.length) {
    final next = _normalizeForLookup(tokens[startTokenIndex + 1].text);
    if (_isCommonCollocationTail(next)) {
      return '$head $next';
    }
  }
  return head;
}

Set<String> _englishLemmaCandidates(
  String word, {
  required Set<String> catalogTokens,
  required bool allowDerivations,
}) {
  final w = _normalizeForLookup(word);
  if (w.isEmpty) return const {};

  final out = <String>{w};
  void add(String s) {
    final t = _normalizeForLookup(s);
    if (t.isNotEmpty) out.add(t);
  }

  if (w.endsWith("'s") && w.length > 2) add(w.substring(0, w.length - 2));

  // Plurals.
  if (w.endsWith('ies') && w.length > 3) {
    add('${w.substring(0, w.length - 3)}y');
  }
  if (w.endsWith('es') && w.length > 2) add(w.substring(0, w.length - 2));
  if (w.endsWith('s') && w.length > 1) add(w.substring(0, w.length - 1));

  // -ing.
  if (w.endsWith('ing') && w.length > 4) {
    final base = w.substring(0, w.length - 3);
    add(base);
    if (!base.endsWith('e')) add('${base}e');
    if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
      add(base.substring(0, base.length - 1));
    }
  }

  // -ed.
  if (w.endsWith('ed') && w.length > 3) {
    final base = w.substring(0, w.length - 2);
    add(base);
    if (w.endsWith('ied') && w.length > 3) {
      add('${w.substring(0, w.length - 3)}y');
    }
    if (!base.endsWith('e')) add('${base}e');
    if (base.length >= 2 && base[base.length - 1] == base[base.length - 2]) {
      add(base.substring(0, base.length - 1));
    }
  }

  // Helpful "other form" candidates (for related suggestions).
  if (!w.endsWith('ing')) add('${w}ing');
  if (!w.endsWith('ed')) add('${w}ed');
  if (!w.endsWith('s')) add('${w}s');

  // Conservative derivations (only if present in catalog).
  if (allowDerivations) {
    for (final suf in const ['ly', 'ful', 'fully', 'ingly']) {
      final d = _normalizeForLookup('$w$suf');
      if (d.isNotEmpty && catalogTokens.contains(d)) out.add(d);
    }
  }

  return out;
}

List<VocabEntry> _lookupCatalogMatches({
  required List<EnWordToken> tokens,
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
  final tappedPhrase = _bestTappedPhrase(
    tokens: tokens,
    startTokenIndex: startTokenIndex,
  );
  final catalogTokens = <String>{};
  for (final e in catalog) {
    final t = _normalizeForLookup(e.word);
    if (t.isEmpty) continue;
    catalogTokens.addAll(t.split(' '));
  }
  final allowDerivations = tappedWord.length >= 5;
  final tappedWordCandidates = _englishLemmaCandidates(
    tappedWord,
    catalogTokens: catalogTokens,
    allowDerivations: allowDerivations,
  );
  final tappedPhraseHeadCandidates = tappedPhrase == null
      ? const <String>{}
      : _englishLemmaCandidates(
          tappedPhrase.split(' ').first,
          catalogTokens: catalogTokens,
          allowDerivations: allowDerivations,
        );

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

  final tierCollocationSameUnit = <VocabEntry>[];
  final tierPhrase = <VocabEntry>[];
  final tierExactWord = <VocabEntry>[];
  final tierRelated = <VocabEntry>[];
  final seen = <String>{};

  void addTo(List<VocabEntry> bucket, VocabEntry e) {
    if (seen.add(e.id)) bucket.add(e);
  }

  // Tier 0 — exact collocation (word + preposition) in the same unit, if present.
  if (tappedPhrase != null && tappedPhrase.contains(' ')) {
    for (final e in catalog) {
      final bid = int.tryParse(e.bookId) ?? -1;
      if (bid != preferredBookId) continue;
      if (e.unit != preferredUnit) continue;
      if (_normalizeForLookup(e.word) == tappedPhrase) {
        addTo(tierCollocationSameUnit, e);
      }
    }
  }

  // Tier 1 — exact phrase match (prefer longest) starting at the tapped token.
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
      // Keep single-word exact match in its own tier.
      if (len == 1) {
        addTo(tierExactWord, e);
      } else {
        addTo(tierPhrase, e);
      }
    }
    break;
  }

  // Tier 2 — related matches by explicit morphology/derivation candidates.
  // This is what surfaces "part-time", "time zone", "free time", … when the
  // user taps "time", regardless of where the tapped word sits in the entry.
  for (final e in catalog) {
    if (seen.contains(e.id)) continue;
    final entryTokens = _normalizeForLookup(e.word).split(' ');
    final hit =
        entryTokens.any(tappedWordCandidates.contains) ||
        entryTokens.any(tappedPhraseHeadCandidates.contains);
    if (hit) {
      addTo(tierRelated, e);
    }
  }

  if (tierCollocationSameUnit.isEmpty &&
      tierPhrase.isEmpty &&
      tierExactWord.isEmpty &&
      tierRelated.isEmpty) {
    return const [];
  }
  tierCollocationSameUnit.sort(compareEntries);
  tierPhrase.sort(compareEntries);
  tierExactWord.sort(compareEntries);
  tierRelated.sort(compareEntries);
  return [
    ...tierCollocationSameUnit,
    ...tierPhrase,
    ...tierExactWord,
    ...tierRelated,
  ];
}

class _SelectableEnglishWithTtsHighlight extends ConsumerStatefulWidget {
  const _SelectableEnglishWithTtsHighlight({
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

  @override
  ConsumerState<_SelectableEnglishWithTtsHighlight> createState() =>
      _SelectableEnglishWithTtsHighlightState();
}

class _SelectableEnglishWithTtsHighlightState
    extends ConsumerState<_SelectableEnglishWithTtsHighlight> {
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
  void didUpdateWidget(covariant _SelectableEnglishWithTtsHighlight oldWidget) {
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

  void dismissHighlightUi() {
    setState(() {
      _textSelection = null;
      _lastAutoHighlighted = null;
      _selectableKey = UniqueKey();
    });
  }

  void _clearTextSelection() => dismissHighlightUi();

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
        final matches = _lookupCatalogMatches(
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
          tappedText: _bestTappedPhrase(
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

    final matches = _lookupCatalogMatches(
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
      tappedText: _bestTappedPhrase(
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

    final tokens = _tokenizeEnglishWords(en);
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
          textAlign: TextAlign.justify,
          textWidthBasis: TextWidthBasis.parent,
          onSelectionChanged: (sel, _) {
            if (!mounted) return;
            if (!sel.isValid || sel.isCollapsed) {
              setState(() {
                _textSelection = null;
                _lastAutoHighlighted = null;
              });
              return;
            }
            setState(() => _textSelection = sel);
            widget.onTextSelectionActive?.call();
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
        if (showHighlightBar)
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
  final _AlignedPair pair;
  final double textScale;

  @override
  ConsumerState<_ParagraphPairBlock> createState() =>
      _ParagraphPairBlockState();
}

class _ParagraphPairBlockState extends ConsumerState<_ParagraphPairBlock> {
  final _englishKey = GlobalKey<_SelectableEnglishWithTtsHighlightState>();
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
                    _SelectableEnglishWithTtsHighlight(
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
                _bidiWrapRtl(local),
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

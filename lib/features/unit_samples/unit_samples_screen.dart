import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/language/language_provider.dart';
import '../../core/tts/tts_service.dart';
import '../../data/models/unit_sample.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

typedef _BookUnitKey = ({int bookId, int unit});

final _expandedSampleIdProvider = StateProvider.family
    .autoDispose<int?, _BookUnitKey>((ref, _) => null);

final _samplesTextScaleProvider = StateProvider.family
    .autoDispose<double, _BookUnitKey>((ref, _) => 1.0);

class UnitSamplesScreen extends ConsumerWidget {
  const UnitSamplesScreen({
    super.key,
    required this.bookId,
    required this.unit,
  });

  final int bookId;
  final int unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(langProvider); // keep screen reactive to language changes
    final screenKey = (bookId: bookId, unit: unit);
    final scale = ref.watch(_samplesTextScaleProvider(screenKey));
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final async = ref.watch(
      apiUnitSamplesProvider((bookId: bookId, unit: unit)),
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.unitSamplesTitle(unit)),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: expandedId == null
          ? null
          : _TextSizeFab(
              screenKey: screenKey,
              label: _textSizeLabel(context),
              value: scale,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                            .state =
                        items.first.id;
                  }
                });
              }
              return _SamplesList(
                screenKey: screenKey,
                bookId: bookId,
                unit: unit,
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
                        apiUnitSamplesProvider((bookId: bookId, unit: unit)),
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
    );
  }
}

class _SamplesList extends ConsumerWidget {
  const _SamplesList({
    required this.screenKey,
    required this.bookId,
    required this.unit,
    required this.items,
  });

  final _BookUnitKey screenKey;
  final int bookId;
  final int unit;
  final List<UnitSample> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedId = ref.watch(_expandedSampleIdProvider(screenKey));
    final scale = ref.watch(_samplesTextScaleProvider(screenKey));
    return ListView.separated(
      // These sample cards have very dynamic heights (long SelectableText).
      // Laying out a larger cache reduces scroll-metric "jumps" on desktop.
      cacheExtent: 2400,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final i = index;
        return _UnitSampleCard(
          sample: items[i],
          expandedId: expandedId,
          textScale: scale,
          onExpandedChanged: (isExpanded) {
            final id = items[i].id;
            if (id <= 0) return;
            final n = ref.read(_expandedSampleIdProvider(screenKey).notifier);
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

class _UnitSampleCard extends ConsumerWidget {
  const _UnitSampleCard({
    required this.sample,
    required this.expandedId,
    required this.textScale,
    required this.onExpandedChanged,
  });
  final UnitSample sample;
  final int? expandedId;
  final double textScale;
  final ValueChanged<bool> onExpandedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isExpanded = expandedId != null && expandedId == sample.id;
    final lang = ref.watch(langProvider);
    final segmentTextStyle = tt.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
    );
    final cardColor = isExpanded ? scheme.surfaceContainerLow : scheme.surface;
    return Card(
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
          key: ValueKey('sample-${sample.id}-expanded-$isExpanded'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpandedChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  sample.title.isEmpty ? 'Sample' : sample.title,
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
            _AlignedBlock(
              combinedText: lang == TranslationLang.fa
                  ? sample.textEnFa
                  : sample.textEnKur,
              textScale: textScale,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignedBlock extends ConsumerWidget {
  const _AlignedBlock({required this.combinedText, required this.textScale});

  final String combinedText;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pairs = _parseAlignedPairs(combinedText);

    if (pairs.isEmpty) return const SelectableText('—');

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _TextPanel(
        background: scheme.surface,
        border: scheme.outlineVariant.withValues(alpha: 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pairs.length; i++) ...[
              _ParagraphPairBlock(pair: pairs[i], textScale: textScale),
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
    );
  }
}

class _ParagraphPairBlock extends ConsumerWidget {
  const _ParagraphPairBlock({required this.pair, required this.textScale});

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
                  SelectableText(
                    _bidiWrapLtr(en),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.justify,
                    textWidthBasis: TextWidthBasis.parent,
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.55,
                      fontSize: (tt.bodyMedium?.fontSize ?? 14) * textScale,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton.filledTonal(
                      tooltip: tts.isSpeakingText(en) ? 'Stop' : 'Read',
                      onPressed: () {
                        if (en.isEmpty) return;
                        if (tts.isSpeakingText(en)) {
                          notifier.stop();
                        } else {
                          notifier.speak(en);
                        }
                      },
                      icon: Icon(
                        tts.isSpeakingText(en)
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                      ),
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

class _TextSizeFab extends ConsumerWidget {
  const _TextSizeFab({
    required this.screenKey,
    required this.label,
    required this.value,
  });

  final _BookUnitKey screenKey;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (value * 100).round();

    return FloatingActionButton.extended(
      heroTag: 'text-size-${screenKey.bookId}-${screenKey.unit}',
      onPressed: () async {
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
                  ref
                          .read(_samplesTextScaleProvider(screenKey).notifier)
                          .state =
                      v,
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
      },
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      icon: const Icon(Icons.text_fields_rounded),
      label: Text('$percent%'),
    );
  }
}

class _TextSizeOverlay extends StatelessWidget {
  const _TextSizeOverlay({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final valueN = ValueNotifier<double>(initialValue);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Floating slider "pill"
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              left: false,
              child: Center(
                child: ValueListenableBuilder<double>(
                  valueListenable: valueN,
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
                                      valueN.value = next;
                                      onChanged(next);
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

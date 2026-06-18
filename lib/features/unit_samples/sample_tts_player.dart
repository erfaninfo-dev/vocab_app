import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tts/tts_service.dart';
import '../../l10n/app_localizations.dart';
import 'sample_tts_helpers.dart';

final sampleTtsSessionProvider = StateProvider<SampleTtsSession?>(
  (ref) => null,
);

final sampleTtsStopperProvider = Provider<SampleTtsStopper>((ref) {
  return SampleTtsStopper(
    ref.read(ttsProvider.notifier),
    ref.read(sampleTtsSessionProvider.notifier),
  );
});

class SampleTtsStopper {
  const SampleTtsStopper(this._tts, this._session);

  final TtsNotifier _tts;
  final StateController<SampleTtsSession?> _session;

  Future<void> stop() async {
    await _tts.stop();
    _session.state = null;
  }

  void clear() {
    _session.state = null;
  }
}

String _formatSpeedPreset(double preset) {
  if ((preset - preset.roundToDouble()).abs() < 0.001) {
    return preset.toStringAsFixed(0);
  }
  return preset.toString();
}

void clearSampleTtsSession(WidgetRef ref) {
  ref.read(sampleTtsSessionProvider.notifier).state = null;
}

Future<void> stopSampleTts(WidgetRef ref) async {
  await ref.read(sampleTtsStopperProvider).stop();
}

void openSampleParagraphSession(
  WidgetRef ref, {
  required int sampleId,
  required String sampleTitle,
  required int paragraphIndex,
  required String paragraphEnglishText,
}) {
  ref.read(sampleTtsSessionProvider.notifier).state = SampleTtsSession(
    sampleId: sampleId,
    title: sampleTitle,
    paragraphIndex: paragraphIndex,
    paragraphEnglishText: paragraphEnglishText,
  );
}

bool isSamplePlayerActiveFor(WidgetRef ref, {required int sampleId}) {
  final session = ref.read(sampleTtsSessionProvider);
  return session != null && session.sampleId == sampleId;
}

/// Scoped bottom player for unit sample full-text TTS.
class SampleTtsPlayerBar extends ConsumerStatefulWidget {
  const SampleTtsPlayerBar({super.key});

  @override
  ConsumerState<SampleTtsPlayerBar> createState() => _SampleTtsPlayerBarState();
}

class _SampleTtsPlayerBarState extends ConsumerState<SampleTtsPlayerBar> {
  double? _sliderDrag;
  double _dragOffset = 0;

  static const double _dismissDragThreshold = 56;
  static const double _dismissVelocityThreshold = 420;

  void _onDragUpdate(double deltaDy) {
    if (deltaDy <= 0) return;
    setState(() => _dragOffset += deltaDy);
  }

  void _onDragEnd(double velocity) {
    if (_dragOffset >= _dismissDragThreshold ||
        velocity >= _dismissVelocityThreshold) {
      setState(() => _dragOffset = 0);
      unawaited(stopSampleTts(ref));
      return;
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sampleTtsSessionProvider);
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);

    ref.listen<TtsState>(ttsProvider, (prev, next) {
      final session = ref.read(sampleTtsSessionProvider);
      if (session == null) return;
      // Word-card TTS uses a short snippet — do not tear down the sample player.
      if (next.hasActivePlayback &&
          next.activeText != session.paragraphEnglishText &&
          next.activeText.length >= session.paragraphEnglishText.length * 0.5) {
        clearSampleTtsSession(ref);
      }
    });

    if (session == null) {
      if (_sliderDrag != null || _dragOffset != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _sliderDrag = null;
              _dragOffset = 0;
            });
          }
        });
      }
      return const SizedBox.shrink();
    }

    final paragraphText = session.paragraphEnglishText;
    final matchesSession =
        tts.activeText == paragraphText ||
        tts.lingeringReadText == paragraphText;
    if (!matchesSession && !tts.hasActivePlayback) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final totalLen = paragraphText.length;
    final current = tts.activeText == paragraphText
        ? tts.currentCharIndex.clamp(0, totalLen)
        : (tts.lingeringReadText == paragraphText ? totalLen : 0);
    final fromTts = SampleEnglishLayout.progressFraction(current, totalLen);
    final sliderValue = _sliderDrag ?? fromTts;
    final speed = tts.speechRateMultiplier;
    final title = SampleEnglishLayout.previewTitle(
      session.title,
      paragraphText,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Material(
                elevation: 12,
                shadowColor: scheme.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                color: scheme.surfaceContainerHigh,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primaryContainer.withValues(alpha: 0.35),
                        scheme.surfaceContainerHigh,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SampleTtsDragHandle(
                        onDragUpdate: _onDragUpdate,
                        onDragEnd: _onDragEnd,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.headphones_rounded,
                                  size: 22,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        l10n.sampleTtsNowPlaying,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.sampleTtsStop,
                                  onPressed: () => stopSampleTts(ref),
                                  icon: const Icon(Icons.close_rounded),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16,
                                ),
                              ),
                              child: Slider(
                                value: sliderValue.clamp(0.0, 1.0),
                                onChanged: (v) => setState(
                                  () => _sliderDrag = v.clamp(0.0, 1.0),
                                ),
                                onChangeEnd: (v) {
                                  final next =
                                      SampleEnglishLayout.seekIndexFromFraction(
                                        v,
                                        totalLen,
                                      );
                                  setState(() => _sliderDrag = null);
                                  unawaited(
                                    notifier.speakFrom(
                                      paragraphText,
                                      next,
                                      showMiniPlayer: false,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _PlayerIconButton(
                                  tooltip: l10n.sampleTtsRewind5,
                                  icon: Icons.replay_5_rounded,
                                  onPressed: () => unawaited(
                                    notifier.skipSeconds(-kTtsSkipSeconds),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(52, 52),
                                    shape: const CircleBorder(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (tts.isPaused) {
                                      unawaited(notifier.resume());
                                    } else if (tts.isSpeaking) {
                                      unawaited(notifier.pause());
                                    } else {
                                      unawaited(
                                        notifier.speakFrom(
                                          paragraphText,
                                          current,
                                          showMiniPlayer: false,
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    tts.isPaused || !tts.isSpeaking
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                _PlayerIconButton(
                                  tooltip: l10n.sampleTtsForward5,
                                  icon: Icons.forward_5_rounded,
                                  onPressed: () => unawaited(
                                    notifier.skipSeconds(kTtsSkipSeconds),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final preset in kTtsSpeedPresets)
                                    ChoiceChip(
                                      label: Text(
                                        l10n.sampleTtsSpeedLabel(
                                          _formatSpeedPreset(preset),
                                        ),
                                      ),
                                      selected: (speed - preset).abs() < 0.01,
                                      onSelected: (_) {
                                        HapticFeedback.selectionClick();
                                        unawaited(
                                          notifier.setSpeechRateMultiplier(
                                            preset,
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: tt.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (tts.googleEngineAvailable) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      l10n.sampleTtsEngine,
                                      style: tt.labelMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ChoiceChip(
                                      label: Text(l10n.sampleTtsEngineSystem),
                                      selected:
                                          tts.engineChoice ==
                                          TtsEngineChoice.system,
                                      onSelected: (_) {
                                        HapticFeedback.selectionClick();
                                        unawaited(
                                          notifier.setEngineChoice(
                                            TtsEngineChoice.system,
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: tt.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ChoiceChip(
                                      label: Text(l10n.sampleTtsEngineGoogle),
                                      selected:
                                          tts.engineChoice ==
                                          TtsEngineChoice.google,
                                      onSelected: (_) {
                                        HapticFeedback.selectionClick();
                                        unawaited(
                                          notifier.setEngineChoice(
                                            TtsEngineChoice.google,
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: tt.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _SampleTtsDragHandle extends StatelessWidget {
  const _SampleTtsDragHandle({
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
      onVerticalDragEnd: (details) => onDragEnd(details.primaryVelocity ?? 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

/// Wraps the samples list and overlays the scoped player at the bottom.
class SampleTtsPlayerScope extends ConsumerWidget {
  const SampleTtsPlayerScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SampleTtsPlayerBar(),
        ),
      ],
    );
  }
}

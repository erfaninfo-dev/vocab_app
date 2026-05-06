import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_service.dart';

class TtsPlayerOverlay extends ConsumerStatefulWidget {
  const TtsPlayerOverlay({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<TtsPlayerOverlay> createState() => _TtsPlayerOverlayState();
}

class _TtsPlayerOverlayState extends ConsumerState<TtsPlayerOverlay> {
  double? _sliderDrag;

  @override
  Widget build(BuildContext context) {
    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);

    final base = widget.child ?? const SizedBox.shrink();
    if (!tts.hasActivePlayback ||
        tts.activeText.trim().isEmpty ||
        !tts.showMiniPlayer) {
      if (_sliderDrag != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _sliderDrag = null);
        });
      }
      return base;
    }

    final totalLen = tts.activeText.length;
    final current = (tts.progressEnd >= 0 ? tts.progressEnd : tts.spokenTextOffset)
        .clamp(0, totalLen);
    final fromTts =
        totalLen == 0 ? 0.0 : (current / totalLen).clamp(0.0, 1.0).toDouble();
    final value = _sliderDrag ?? fromTts;

    final scheme = Theme.of(context).colorScheme;
    final highlightOn = ref.watch(ttsTextHighlightEnabledProvider);

    return Stack(
      children: [
        base,
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(18),
                  color: scheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            final cur =
                                ref.read(ttsTextHighlightEnabledProvider);
                            ref
                                    .read(ttsTextHighlightEnabledProvider
                                        .notifier)
                                    .state =
                                !cur;
                          },
                          icon: Icon(
                            highlightOn
                                ? Icons.highlight_rounded
                                : Icons.highlight_off_outlined,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton.filled(
                          onPressed: () {
                            if (tts.isPaused) {
                              notifier.resume();
                            } else {
                              notifier.pause();
                            }
                          },
                          icon: Icon(
                            tts.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton.filledTonal(
                          onPressed: () {
                            final jump = (totalLen * 0.10).round();
                            final next = (current - jump).clamp(0, totalLen);
                            notifier.speakFrom(
                              tts.activeText,
                              next,
                              showMiniPlayer: tts.showMiniPlayer,
                            );
                          },
                          icon: const Icon(Icons.replay_10_rounded),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Slider(
                            value: value.clamp(0.0, 1.0),
                            onChanged: (v) => setState(
                                  () => _sliderDrag = v.clamp(0.0, 1.0),
                                ),
                            onChangeEnd: (v) {
                              final next =
                                  (totalLen * v).round().clamp(0, totalLen);
                              setState(() => _sliderDrag = null);
                              notifier.speakFrom(
                                tts.activeText,
                                next,
                                showMiniPlayer: tts.showMiniPlayer,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton.filledTonal(
                          onPressed: () {
                            final jump = (totalLen * 0.10).round();
                            final next = (current + jump).clamp(0, totalLen);
                            notifier.speakFrom(
                              tts.activeText,
                              next,
                              showMiniPlayer: tts.showMiniPlayer,
                            );
                          },
                          icon: const Icon(Icons.forward_10_rounded),
                        ),
                        const SizedBox(width: 2),
                        IconButton.filled(
                          onPressed: () => notifier.stop(),
                          icon: const Icon(Icons.stop_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

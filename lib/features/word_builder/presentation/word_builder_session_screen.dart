import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_game_notifier.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import 'word_builder_feedback.dart';
import 'word_builder_session_ambience.dart';
import 'widgets/answer_slots.dart';
import 'widgets/circular_letter_tray.dart';
import 'widgets/word_builder_tray_circle_button.dart';
import 'widgets/word_info_sheet.dart';

class WordBuilderSessionScreen extends ConsumerStatefulWidget {
  const WordBuilderSessionScreen({super.key, required this.bookKey});

  final int bookKey;

  @override
  ConsumerState<WordBuilderSessionScreen> createState() =>
      _WordBuilderSessionScreenState();
}

class _WordBuilderSessionScreenState
    extends ConsumerState<WordBuilderSessionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = widget.bookKey;
    final async = ref.watch(wordBuilderGameProvider(key));
    final camp = decodeWordBuilderCampaignSessionKey(key);

    ref.listen(wordBuilderGameProvider(key), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final prevData = prev?.valueOrNull;
      if (data.lastSolvedWord != null &&
          data.lastSolvedWord != prevData?.lastSolvedWord) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await WordInfoSheet.show(
            context,
            data.lastSolvedWord!,
            bookKey: key,
          );
          if (!mounted) return;
          ref.read(wordBuilderGameProvider(key).notifier).clearLastSolvedWord();
          if (!mounted) return;
          final after = ref.read(wordBuilderGameProvider(key)).valueOrNull;
          if (after != null && after.levelComplete) {
            await Future<void>.delayed(const Duration(milliseconds: 320));
            if (!mounted) return;
            if (camp != null) {
              final repo =
                  ref.read(wordBuilderCampaignProgressRepositoryProvider);
              final snap = await repo.load();
              final nextProg = snap.afterClearingStage(
                camp.difficulty,
                camp.stage1Based,
              );
              await repo.save(nextProg);
              ref.invalidate(wordBuilderCampaignProgressProvider);
              ref.invalidate(wordBuilderGameProvider(key));
              if (context.mounted) context.pop();
            } else {
              await ref.read(wordBuilderGameProvider(key).notifier).goToNextLevel();
            }
          }
        });
      }
      final msg = data.feedbackMessage;
      if (msg != null && msg != prevData?.feedbackMessage) {
        final text = localizeWordBuilderFeedback(l10n, msg);
        if (text != null && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    final gradient = WordBuilderSessionAmbience.skyBackground(
      scheme,
      isDark: isDark,
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: scheme.surface.withValues(alpha: 0.72),
          foregroundColor: scheme.onSurface,
          surfaceTintColor: scheme.surfaceTint,
          title: camp == null
              ? Text(l10n.wordBuilderTitle)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.wordBuilderTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      l10n.wordBuilderCampaignStageOf(
                        camp.stage1Based,
                        kWordBuilderStagesPerTier,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/word-builder'),
          ),
        ),
        body: async.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: scheme.primary),
          ),
          error: (e, _) {
            final noWords = e is StateError && e.message == 'NO_WORDS';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      noWords
                          ? l10n.wordBuilderNoWordsBody
                          : '${l10n.errorGeneric}\n$e',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(wordBuilderGameProvider(key)),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (s) {
            final built = s.path.map((e) => e.char).join();
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, outer) {
                  final sScale =
                      WordBuilderSessionAmbience.layoutScale(outer.biggest);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          clipBehavior: Clip.none,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  14 * sScale,
                                  10 * sScale,
                                  14 * sScale,
                                  2,
                                ),
                                child: AnswerSlotsPanel(
                                  level: s.level,
                                  solvedLower: s.solvedLower,
                                  revealedPositions: s.revealedPositions,
                                  layoutScale: sScale,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16 * sScale,
                                  6 * sScale,
                                  16 * sScale,
                                  4 * sScale,
                                ),
                                child: DecoratedBox(
                                  decoration:
                                      WordBuilderSessionAmbience.currentWordChip(
                                    scheme: scheme,
                                    isDark: isDark,
                                    wrong: s.pathWrongHighlight,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical:
                                          (11 * sScale).clamp(8.0, 14.0),
                                      horizontal:
                                          (14 * sScale).clamp(10.0, 16.0),
                                    ),
                                    child: Text(
                                      built.isEmpty ? ' ' : built.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            letterSpacing: (3 * sScale)
                                                .clamp(2.0, 4.0),
                                            fontWeight: FontWeight.w900,
                                            fontSize: (Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.fontSize ??
                                                    22) *
                                                sScale,
                                            color: s.pathWrongHighlight
                                                ? scheme.onErrorContainer
                                                : scheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: (8 * sScale).clamp(4.0, 14.0),
                          ),
                          child: LayoutBuilder(
                            builder: (context, trayConstraints) {
                              final w = trayConstraints.maxWidth;
                              final side = math.min(
                                    w,
                                    trayConstraints.maxHeight,
                                  ) *
                                  (0.76 * sScale).clamp(0.56, 0.82);
                              final btn =
                                  (50 * sScale).clamp(44.0, 54.0);
                              final inset =
                                  (22 * sScale).clamp(18.0, 32.0);
                              return Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: side * 1.1,
                                          height: side * 1.1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                scheme.primary
                                                    .withValues(alpha: 0.14),
                                                scheme.primary
                                                    .withValues(alpha: 0.04),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.45, 1.0],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            6 * sScale,
                                            0,
                                            6 * sScale,
                                            8 * sScale,
                                          ),
                                          child: SizedBox(
                                            width: w,
                                            height: trayConstraints.maxHeight,
                                            child: CircularLetterTray(
                                              bookKey: key,
                                              letters: s.circleLetters,
                                              layoutMinExtent: math.min(w, side),
                                              chromeInset: inset,
                                              chromeButtonSize: btn,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PositionedDirectional(
                                    start: inset,
                                    top: inset,
                                    child: WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.hint,
                                      diameter: btn,
                                      l10n: l10n,
                                    ),
                                  ),
                                  PositionedDirectional(
                                    start: inset,
                                    bottom: inset,
                                    child: WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.shuffle,
                                      diameter: btn,
                                      l10n: l10n,
                                    ),
                                  ),
                                  PositionedDirectional(
                                    end: inset,
                                    bottom: inset,
                                    child: WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.translate,
                                      diameter: btn,
                                      l10n: l10n,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

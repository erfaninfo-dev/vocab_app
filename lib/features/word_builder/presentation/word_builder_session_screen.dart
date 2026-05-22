import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/word_builder_sound_service.dart';
import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_coins_provider.dart';
import '../application/word_builder_game_notifier.dart';
import '../application/word_builder_session_audio.dart';
import '../application/word_builder_tray_water_audio.dart';
import '../domain/word_builder_models.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import '../word_builder_coin_constants.dart';
import 'word_builder_feedback.dart';
import 'word_builder_session_ambience.dart';
import 'widgets/answer_slots.dart';
import 'widgets/circular_letter_tray.dart';
import 'widgets/magic_background.dart';
import 'widgets/shake_wrapper.dart';
import 'widgets/word_builder_coins_chip.dart';
import 'widgets/word_builder_level_complete_dialog.dart';
import 'widgets/word_builder_meaning_banner.dart';
import 'widgets/word_builder_session_audio_sheet.dart';
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
    extends ConsumerState<WordBuilderSessionScreen>
    with WidgetsBindingObserver {
  bool _levelCompleteDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(
          ref
              .read(wordBuilderBgmPlayerProvider)
              .apply(enabled: ref.read(wordBuilderGameBgmEnabledProvider)),
        );
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopSessionAudioForBackground();
    }
  }

  void _stopSessionAudioForBackground() {
    unawaited(ref.read(wordBuilderBgmPlayerProvider).stopForAppBackground());
    unawaited(ref.read(wordBuilderSoundServiceProvider).stop());
    unawaited(
      ref.read(wordBuilderTrayWaterAudioProvider(widget.bookKey)).stopAll(),
    );
  }

  Future<void> _saveCampaignStageProgress() async {
    final key = widget.bookKey;
    final camp = decodeWordBuilderCampaignSessionKey(key);
    if (camp == null) return;
    final repo = ref.read(wordBuilderCampaignProgressRepositoryProvider);
    final snap = await repo.load();
    final nextProg = snap.afterClearingStage(camp.difficulty, camp.stage1Based);
    await repo.save(nextProg);
    ref.invalidate(wordBuilderCampaignProgressProvider);
    ref.invalidate(wordBuilderGameProvider(key));
  }

  Future<void> _finishCampaignStageAndExit() async {
    await _saveCampaignStageProgress();
    if (mounted) context.pop();
  }

  Future<void> _advanceAfterLevelComplete() async {
    final key = widget.bookKey;
    final camp = decodeWordBuilderCampaignSessionKey(key);
    if (camp != null) {
      await _saveCampaignStageProgress();
      if (!mounted) return;
      if (camp.stage1Based >= kWordBuilderStagesPerTier) {
        context.pop();
        return;
      }
      final nextKey = encodeWordBuilderCampaignSessionKey(
        camp.difficulty,
        camp.stage1Based + 1,
      );
      context.pushReplacement('/word-builder/session?bookId=$nextKey');
      return;
    }
    await ref.read(wordBuilderGameProvider(key).notifier).goToNextLevel();
  }

  Future<void> _showLevelCompleteDialog() async {
    if (_levelCompleteDialogOpen || !mounted) return;
    _levelCompleteDialogOpen = true;
    try {
      final key = widget.bookKey;
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      final after = ref.read(wordBuilderGameProvider(key)).valueOrNull;
      if (after == null || !after.levelComplete) return;

      final action = await WordBuilderLevelCompleteDialog.show(context);
      if (!mounted || action == null) return;
      switch (action) {
        case WordBuilderLevelCompleteAction.next:
          await _advanceAfterLevelComplete();
        case WordBuilderLevelCompleteAction.exit:
          await _finishCampaignStageAndExit();
      }
    } finally {
      _levelCompleteDialogOpen = false;
    }
  }

  Future<void> _maybeShowLevelCompleteDialog() async {
    if (!mounted) return;
    final after = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (after == null || !after.levelComplete) return;
    await _showLevelCompleteDialog();
  }

  Future<void> _onSolvedWordTapped(WordBuilderTargetWord target) async {
    if (!mounted) return;
    await WordInfoSheet.show(context, target, bookKey: widget.bookKey);
    if (!mounted) return;
    await _maybeShowLevelCompleteDialog();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = widget.bookKey;
    final async = ref.watch(wordBuilderGameProvider(key));
    final coinsAsync = ref.watch(wordBuilderCoinsProvider);
    ref.watch(wordBuilderSessionAudioLifecycleProvider(key));

    ref.listen(wordBuilderGameProvider(key), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final prevData = prev?.valueOrNull;
      if (data.levelComplete && prevData?.levelComplete != true) {
        unawaited(_showLevelCompleteDialog());
      }
      final msg = data.feedbackMessage;
      if (msg != null && msg != prevData?.feedbackMessage) {
        if (wordBuilderFeedbackIsMeaning(msg)) return;
        final text = localizeWordBuilderFeedback(l10n, msg);
        if (text != null && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                text,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: isDark
                  ? const Color(0xFF3E3228)
                  : const Color(0xFF5D4037),
            ),
          );
        }
      }
    });

    final funTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
    );

    final trayGameOver = async.valueOrNull?.isTrayGameOver ?? false;

    return Theme(
      data: funTheme,
      child: PopScope(
        canPop: !trayGameOver,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MagicBackground(isDark: isDark),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: kToolbarHeight,
                title: const SizedBox.shrink(),
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: trayGameOver
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? scheme.onSurface
                              : const Color(0xFF5D4037),
                        ),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/word-builder'),
                      ),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Tooltip(
                      message: l10n.wordBuilderSessionSoundTitle,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: trayGameOver
                              ? null
                              : () =>
                                    WordBuilderSessionAudioSheet.show(context),
                          child: Ink(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? scheme.surfaceContainerHighest.withValues(
                                      alpha: 0.55,
                                    )
                                  : const Color(
                                      0xFF5D4037,
                                    ).withValues(alpha: 0.12),
                              border: Border.all(
                                color: const Color(
                                  0xFFFFB300,
                                ).withValues(alpha: isDark ? 0.45 : 0.65),
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.28 : 0.08,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.settings_rounded,
                                size: 24,
                                color: isDark
                                    ? scheme.onSurface
                                    : const Color(0xFF5D4037),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: Center(
                      child: coinsAsync.when(
                        data: (c) => WordBuilderCoinsChip(
                          balanceLabel: l10n.wordBuilderCoinsBalance(c),
                          isDark: isDark,
                          scheme: scheme,
                        ),
                        loading: () =>
                            WordBuilderCoinsChipLoading(scheme: scheme),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
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
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
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
                  final letterCost = wordBuilderCoinsCostHintLetter();
                  final meaningCost = wordBuilderCoinsCostHintMeaning();
                  final balance = coinsAsync.valueOrNull;
                  final coinsReady = balance != null;
                  final trayBlocked = s.isTrayGameOver;
                  final canHint =
                      !trayBlocked && coinsReady && balance >= letterCost;
                  final canMeaning =
                      !trayBlocked && coinsReady && balance >= meaningCost;
                  final hintTip =
                      '${l10n.wordBuilderHintReveal}\n${l10n.wordBuilderCoinsCost(letterCost)}';
                  final meaningTip =
                      '${l10n.wordBuilderTranslation}\n${l10n.wordBuilderCoinsCost(meaningCost)}';
                  final meaningText = wordBuilderMeaningFromFeedback(
                    s.feedbackMessage,
                  );
                  return SafeArea(
                    child: LayoutBuilder(
                      builder: (context, outer) {
                        final sScale = WordBuilderSessionAmbience.layoutScale(
                          outer.biggest,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                clipBehavior: Clip.none,
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                        onSolvedWordTap: _onSolvedWordTapped,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        16 * sScale,
                                        6 * sScale,
                                        16 * sScale,
                                        4 * sScale,
                                      ),
                                      child: ShakeWrapper(
                                        shake: s.pathWrongHighlight,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            gradient: LinearGradient(
                                              colors: s.pathWrongHighlight
                                                  ? const [
                                                      Color(0xFFFFCDD2),
                                                      Color(0xFFFF8A80),
                                                    ]
                                                  : const [
                                                      Color(0xFFFFF8E1),
                                                      Color(0xFFFFECB3),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: s.pathWrongHighlight
                                                  ? const Color(0xFFD32F2F)
                                                  : const Color(0xFFFFB300),
                                              width: 2.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (s.pathWrongHighlight
                                                            ? Colors.red
                                                            : Colors.orange)
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                blurRadius: 14,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: (11 * sScale).clamp(
                                                8.0,
                                                14.0,
                                              ),
                                              horizontal: (14 * sScale).clamp(
                                                10.0,
                                                16.0,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 280,
                                                  ),
                                                  transitionBuilder:
                                                      (child, anim) {
                                                        return ScaleTransition(
                                                          scale: anim,
                                                          child: child,
                                                        );
                                                      },
                                                  child: Text(
                                                    built.isEmpty
                                                        ? ' '
                                                        : built.toUpperCase(),
                                                    key: ValueKey(built),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.fredoka(
                                                      fontSize: 32 * sScale,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 3,
                                                      color:
                                                          s.pathWrongHighlight
                                                          ? const Color(
                                                              0xFFB71C1C,
                                                            )
                                                          : const Color(
                                                              0xFF5D4037,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                if (meaningText != null) ...[
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: (8 * sScale).clamp(
                                                        6.0,
                                                        10.0,
                                                      ),
                                                      bottom: (2 * sScale)
                                                          .clamp(0.0, 4.0),
                                                    ),
                                                    child: Divider(
                                                      height: 1,
                                                      thickness: 1.2,
                                                      color:
                                                          (s.pathWrongHighlight
                                                                  ? const Color(
                                                                      0xFFD32F2F,
                                                                    )
                                                                  : const Color(
                                                                      0xFFFFB300,
                                                                    ))
                                                              .withValues(
                                                                alpha: 0.45,
                                                              ),
                                                    ),
                                                  ),
                                                  AnimatedSize(
                                                    duration: const Duration(
                                                      milliseconds: 260,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: WordBuilderEmbeddedMeaning(
                                                      key: ValueKey(
                                                        meaningText,
                                                      ),
                                                      label: l10n
                                                          .wordBuilderTranslation,
                                                      meaning: meaningText,
                                                      isDark: isDark,
                                                      layoutScale: sScale,
                                                    ),
                                                  ),
                                                ],
                                              ],
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
                                    final side =
                                        math.min(w, trayConstraints.maxHeight) *
                                        (0.76 * sScale).clamp(0.56, 0.82);
                                    final btn = (50 * sScale).clamp(44.0, 54.0);
                                    final inset = (22 * sScale).clamp(
                                      18.0,
                                      32.0,
                                    );
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
                                                      scheme.primary.withValues(
                                                        alpha: 0.14,
                                                      ),
                                                      scheme.primary.withValues(
                                                        alpha: 0.04,
                                                      ),
                                                      Colors.transparent,
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.45,
                                                      1.0,
                                                    ],
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
                                                  height:
                                                      trayConstraints.maxHeight,
                                                  child: CircularLetterTray(
                                                    bookKey: key,
                                                    letters: s.circleLetters,
                                                    layoutMinExtent: math.min(
                                                      w,
                                                      side,
                                                    ),
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
                                            kind:
                                                WordBuilderTrayActionKind.hint,
                                            diameter: btn,
                                            l10n: l10n,
                                            enabled: canHint,
                                            tooltipOverride: hintTip,
                                          ),
                                        ),
                                        PositionedDirectional(
                                          start: inset,
                                          bottom: inset,
                                          child: WordBuilderTrayCircleButton(
                                            bookKey: key,
                                            kind: WordBuilderTrayActionKind
                                                .shuffle,
                                            diameter: btn,
                                            l10n: l10n,
                                            enabled: !trayBlocked,
                                          ),
                                        ),
                                        PositionedDirectional(
                                          end: inset,
                                          bottom: inset,
                                          child: WordBuilderTrayCircleButton(
                                            bookKey: key,
                                            kind: WordBuilderTrayActionKind
                                                .translate,
                                            diameter: btn,
                                            l10n: l10n,
                                            enabled: canMeaning,
                                            tooltipOverride: meaningTip,
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
          ],
        ),
      ),
    );
  }
}

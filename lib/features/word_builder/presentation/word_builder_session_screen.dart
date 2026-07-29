import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/angry_words_gun_audio.dart';
import '../../../core/audio/angry_words_sling_audio.dart';
import '../../../core/audio/word_builder_sound_service.dart';
import '../../../l10n/app_localizations.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_coins_provider.dart';
import '../application/word_builder_game_notifier.dart';
import '../application/word_builder_league_sync.dart';
import '../application/word_builder_play_mode_controller.dart';
import '../application/word_builder_session_audio.dart';
import '../application/word_builder_tray_prison_audio.dart';
import '../application/word_builder_tray_train_audio.dart';
import '../application/word_builder_tray_water_audio.dart';
import '../domain/word_builder_game_logic.dart';
import '../domain/word_builder_models.dart';
import '../domain/word_builder_play_mode.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import '../word_builder_coin_constants.dart';
import 'word_builder_feedback.dart';
import 'word_builder_session_ambience.dart';
import 'widgets/angry_words/angry_words_letter_board.dart';
import 'widgets/answer_slot_key_bag.dart';
import 'widgets/answer_slots.dart';
import 'widgets/arkanoid/arkanoid_ball_speed_button.dart';
import 'widgets/arkanoid/arkanoid_letter_board.dart';
import 'widgets/circular_letter_tray.dart';
import 'widgets/magic_background.dart';
import 'widgets/puzzle/puzzle_letter_board.dart';
import 'widgets/shake_wrapper.dart';
import 'widgets/word_builder_action_bar.dart';
import 'widgets/word_builder_coins_chip.dart';
import 'widgets/word_builder_level_complete_panel.dart';
import 'widgets/word_builder_meaning_banner.dart';
import 'widgets/word_builder_path_letters.dart';
import 'widgets/word_builder_session_audio_sheet.dart';
import 'widgets/word_info_sheet.dart';
import 'theme/word_builder_chapter_meta.dart';
import 'theme/word_builder_tokens.dart';

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
  final _answerSlotKeys = AnswerSlotKeyBag();
  final _pathCardKey = GlobalKey(debugLabel: 'angryWordsPathCard');

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
        unawaited(
          ref
              .read(wordBuilderGameProvider(widget.bookKey).notifier)
              .persistSessionDraft(),
        );
    }
  }

  void _stopSessionAudioForBackground() {
    unawaited(ref.read(wordBuilderBgmPlayerProvider).stopForAppBackground());
    unawaited(ref.read(wordBuilderSoundServiceProvider).stop());
    unawaited(
      ref.read(wordBuilderTrayWaterAudioProvider(widget.bookKey)).stopAll(),
    );
    unawaited(
      ref.read(wordBuilderTrayTrainAudioProvider(widget.bookKey)).stopAll(),
    );
    unawaited(
      ref.read(wordBuilderTrayPrisonAudioProvider(widget.bookKey)).stopAll(),
    );
    unawaited(ref.read(angryWordsGunAudioProvider).stop());
    unawaited(ref.read(angryWordsSlingAudioProvider).stop());
  }

  Future<void> _saveCampaignStageProgress() async {
    final key = widget.bookKey;
    final camp = decodeWordBuilderCampaignSessionKey(key);
    if (camp == null) return;
    final repo = ref.read(wordBuilderCampaignProgressRepositoryProvider);
    final snap = await repo.load();
    final nextProg = snap.afterClearingStage(camp.difficulty, camp.stage1Based);
    await repo.save(nextProg);
    final coins = ref.read(wordBuilderCoinsProvider).valueOrNull;
    if (coins != null) {
      unawaited(
        syncWordBuilderLeagueSnapshot(
          read: ref.read,
          progress: nextProg,
          coins: coins,
        ),
      );
    }
    ref.invalidate(wordBuilderCampaignProgressProvider);
    ref.invalidate(wordBuilderGameProvider(key));
  }

  WordBuilderDifficulty? _nextCampaignDifficulty(WordBuilderDifficulty d) {
    switch (d) {
      case WordBuilderDifficulty.beginner:
        return WordBuilderDifficulty.intermediate;
      case WordBuilderDifficulty.intermediate:
        return WordBuilderDifficulty.advanced;
      case WordBuilderDifficulty.advanced:
        return null;
    }
  }

  /// Confetti only when finishing the last stage of a chapter (not every level).
  bool _isChapterComplete() {
    final camp = decodeWordBuilderCampaignSessionKey(widget.bookKey);
    if (camp == null) return false;
    final m = WbChapterMeta.forStage(camp.stage1Based);
    return m.indexInChapter >= m.chapterLength;
  }

  bool _isCampaignTierComplete() {
    final camp = decodeWordBuilderCampaignSessionKey(widget.bookKey);
    return camp != null && camp.stage1Based >= kWordBuilderStagesPerTier;
  }

  ({String emoji, String title, String body, String nextLabel})
  _levelCompleteCopy(AppLocalizations l10n) {
    final camp = decodeWordBuilderCampaignSessionKey(widget.bookKey);
    if (camp == null || camp.stage1Based < kWordBuilderStagesPerTier) {
      return (
        emoji: '🏆🎉',
        title: l10n.wordBuilderLevelCompleteTitle,
        body: l10n.wordBuilderLevelCompleteBody,
        nextLabel: l10n.wordBuilderNextLevel,
      );
    }
    switch (camp.difficulty) {
      case WordBuilderDifficulty.beginner:
        return (
          emoji: '🎉🏆✨',
          title: l10n.wordBuilderBeginnerCompleteTitle,
          body: l10n.wordBuilderBeginnerCompleteBody,
          nextLabel: l10n.wordBuilderStartIntermediate,
        );
      case WordBuilderDifficulty.intermediate:
        return (
          emoji: '🚀🏆✨',
          title: l10n.wordBuilderIntermediateCompleteTitle,
          body: l10n.wordBuilderIntermediateCompleteBody,
          nextLabel: l10n.wordBuilderStartAdvanced,
        );
      case WordBuilderDifficulty.advanced:
        return (
          emoji: '👑✨🏆',
          title: l10n.wordBuilderAdvancedCompleteTitle,
          body: l10n.wordBuilderAdvancedCompleteBody,
          nextLabel: l10n.exit,
        );
    }
  }

  Future<void> _finishCampaignStageAndExit() async {
    await ref
        .read(wordBuilderGameProvider(widget.bookKey).notifier)
        .clearSessionDraft();
    await _saveCampaignStageProgress();
    if (mounted) context.pop();
  }

  Future<void> _advanceAfterLevelComplete() async {
    final key = widget.bookKey;
    final camp = decodeWordBuilderCampaignSessionKey(key);
    await ref.read(wordBuilderGameProvider(key).notifier).clearSessionDraft();
    if (camp != null) {
      await _saveCampaignStageProgress();
      if (!mounted) return;
      if (camp.stage1Based >= kWordBuilderStagesPerTier) {
        final nextDifficulty = _nextCampaignDifficulty(camp.difficulty);
        if (nextDifficulty != null) {
          final nextKey = encodeWordBuilderCampaignSessionKey(
            nextDifficulty,
            1,
          );
          context.pushReplacement('/word-builder/session?bookId=$nextKey');
          return;
        }
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

  Future<void> _onSolvedWordTapped(WordBuilderTargetWord target) async {
    if (!mounted) return;
    await WordInfoSheet.show(context, target, bookKey: widget.bookKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = widget.bookKey;
    final async = ref.watch(wordBuilderGameProvider(key));
    final coinsAsync = ref.watch(wordBuilderCoinsProvider);
    final playMode = ref.watch(wordBuilderPlayModeProvider);
    ref.watch(wordBuilderSessionAudioLifecycleProvider(key));

    ref.listen(wordBuilderPlayModeProvider, (prev, next) {
      if (prev == next) return;
      unawaited(
        ref.read(wordBuilderGameProvider(key).notifier).clearPathOnly(),
      );
      if (next.skipsTrayTension) {
        unawaited(ref.read(wordBuilderTrayWaterAudioProvider(key)).stopAll());
        unawaited(ref.read(wordBuilderTrayTrainAudioProvider(key)).stopAll());
        unawaited(ref.read(wordBuilderTrayPrisonAudioProvider(key)).stopAll());
        unawaited(
          ref
              .read(wordBuilderGameProvider(key).notifier)
              .preparePhysicsLetterMode(),
        );
      }
    });

    ref.listen(wordBuilderGameProvider(key), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      final prevData = prev?.valueOrNull;
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
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFFFFDE7),
                ),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: isDark
                  ? const Color(0xFF5D4037)
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
                toolbarHeight: playMode.usesCompactLetterBoard
                    ? 44
                    : kToolbarHeight,
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
                title: Builder(
                  builder: (context) {
                    final camp =
                        decodeWordBuilderCampaignSessionKey(widget.bookKey);
                    if (camp == null) return const SizedBox.shrink();
                    return Text(
                      WbChapterMeta.hudLabel(camp.stage1Based),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: playMode.usesCompactLetterBoard
                            ? WbTokens.tSm
                            : WbTokens.tMd,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? scheme.onSurface
                            : const Color(0xFF5D4037),
                      ),
                    );
                  },
                ),
                centerTitle: false,
                titleSpacing: 0,
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
                            height: playMode.usesCompactLetterBoard
                                ? 34
                                : 44,
                            width: playMode.usesCompactLetterBoard
                                ? 34
                                : 44,
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
                                size: playMode.usesCompactLetterBoard
                                    ? 18
                                    : 24,
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
                          balance: c,
                          balanceLabel: l10n.wordBuilderCoinsBalance(c),
                          isDark: isDark,
                          scheme: scheme,
                          compact: playMode.usesCompactLetterBoard,
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
                  final trayBlocked = playMode.usesCompactLetterBoard
                      ? false
                      : s.isTrayGameOver;
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
                  final ghostNext = playMode == WordBuilderPlayMode.arkanoid
                      ? ghostNextLetterForUnsolvedPrefix(
                          s.level,
                          s.solvedLower,
                          built,
                        )
                      : null;
                  final prefixGlow =
                      playMode.usesPhysicsLetterBoard &&
                      s.feedbackMessage == '__arkanoid_prefix';
                  return SafeArea(
                    child: LayoutBuilder(
                      builder: (context, outer) {
                        final sScale = WordBuilderSessionAmbience.layoutScale(
                          outer.biggest,
                        );
                        final isCompactBoard = playMode.usesCompactLetterBoard;
                        final isArkanoid =
                            playMode == WordBuilderPlayMode.arkanoid;
                        final isAngryWords =
                            playMode == WordBuilderPlayMode.angryWords;
                        final isPuzzle =
                            playMode == WordBuilderPlayMode.puzzle;
                        final topScale = isCompactBoard ? sScale * 0.92 : sScale;
                        // Equal air between path card â†” chrome â†” game board.
                        final chromeGap = (14 * sScale).clamp(10.0, 18.0);
                        final actionBarHeight = (52 * sScale).clamp(48.0, 58.0);
                        final pathCardMaxWidth = isCompactBoard
                            ? (outer.maxWidth * 0.74).clamp(220.0, 360.0)
                            : double.infinity;
                        final topPanel = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        14 * sScale,
                                        isCompactBoard ? 4 * sScale : 10 * sScale,
                                        14 * sScale,
                                        isCompactBoard ? 0 : 2,
                                      ),
                                      child: AnswerSlotsPanel(
                                        level: s.level,
                                        solvedLower: s.solvedLower,
                                        revealedPositions: s.revealedPositions,
                                        builtPath: built,
                                        layoutScale: isCompactBoard
                                            ? topScale
                                            : sScale,
                                        onSolvedWordTap: _onSolvedWordTapped,
                                        slotKeyBag: isAngryWords
                                            ? _answerSlotKeys
                                            : null,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isCompactBoard ? 0 : 16 * sScale,
                                        isCompactBoard ? 4 * sScale : 6 * sScale,
                                        isCompactBoard ? 0 : 16 * sScale,
                                        isCompactBoard ? 0 : 4 * sScale,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: pathCardMaxWidth,
                                          ),
                                          child: ShakeWrapper(
                                        shake: s.pathWrongHighlight,
                                        child: DecoratedBox(
                                          key: isAngryWords ? _pathCardKey : null,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              isCompactBoard ? 14 : 18,
                                            ),
                                            gradient: LinearGradient(
                                              colors: s.pathWrongHighlight
                                                  ? const [
                                                      Color(0xFFFFCDD2),
                                                      Color(0xFFFF8A80),
                                                    ]
                                                  : isDark
                                                  ? const [
                                                      Color(0xFF5D4037),
                                                      Color(0xFF2D2640),
                                                    ]
                                                  : const [
                                                      Color(0xFFFFF8E1),
                                                      Color(0xFFFFECB3),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: s.pathWrongHighlight
                                                  ? const Color(0xFFD32F2F)
                                                  : const Color(
                                                      0xFFFFB300,
                                                    ).withValues(
                                                      alpha: isDark ? 0.82 : 1,
                                                    ),
                                              width: isCompactBoard ? 1.6 : 2.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (s.pathWrongHighlight
                                                            ? Colors.red
                                                            : Colors.orange)
                                                        .withValues(
                                                          alpha: isCompactBoard
                                                              ? 0.22
                                                              : 0.35,
                                                        ),
                                                blurRadius: isCompactBoard ? 8 : 14,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: isCompactBoard
                                                  ? (8 * topScale).clamp(
                                                      6.0,
                                                      10.0,
                                                    )
                                                  : (11 * sScale).clamp(
                                                      8.0,
                                                      14.0,
                                                    ),
                                              horizontal: isCompactBoard
                                                  ? (16 * topScale).clamp(
                                                      14.0,
                                                      20.0,
                                                    )
                                                  : (14 * sScale).clamp(
                                                      10.0,
                                                      16.0,
                                                    ),
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: WbTokens.dBase,
                                              switchInCurve: WbTokens.cEnter,
                                              switchOutCurve: WbTokens.cExit,
                                              transitionBuilder:
                                                  (child, anim) {
                                                    return FadeTransition(
                                                      opacity: anim,
                                                      child: child,
                                                    );
                                                  },
                                              // Translate cross-fades with letters.
                                              child: meaningText != null
                                                  ? WordBuilderEmbeddedMeaning(
                                                      key: ValueKey(
                                                        'meaning|$meaningText',
                                                      ),
                                                      label: l10n
                                                          .wordBuilderTranslation,
                                                      meaning: meaningText,
                                                      isDark: isDark,
                                                      layoutScale: topScale,
                                                      compact: true,
                                                    )
                                                  : WordBuilderPathLetters(
                                                      key: ValueKey(
                                                        'path|$built|${ghostNext ?? ''}|$prefixGlow',
                                                      ),
                                                      built: built,
                                                      fontSize:
                                                          (isCompactBoard
                                                              ? 26
                                                              : 32) *
                                                          topScale,
                                                      letterSpacing:
                                                          isCompactBoard
                                                          ? 2
                                                          : 3,
                                                      color: s.pathWrongHighlight
                                                          ? const Color(
                                                              0xFFB71C1C,
                                                            )
                                                          : prefixGlow
                                                          ? const Color(
                                                              0xFF2E7D32,
                                                            )
                                                          : isDark
                                                          ? const Color(
                                                              0xFFFFF8E1,
                                                            )
                                                          : const Color(
                                                              0xFF5D4037,
                                                            ),
                                                      ghostNext:
                                                          ghostNext != null &&
                                                              !s.pathWrongHighlight
                                                          ? ghostNext
                                                          : null,
                                                      ghostScale: sScale,
                                                      isDark: isDark,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                        ),
                                      ),
                                    ),
                                  ],
                        );
                        final showLevelCompletePanel =
                            s.levelComplete && !s.trayVictorySequenceActive;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isCompactBoard)
                              topPanel
                            else
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  clipBehavior: Clip.none,
                                  physics: const ClampingScrollPhysics(),
                                  child: topPanel,
                                ),
                              ),
                            // Equal gap: path card â†’ chrome â†’ game board.
                            if (!showLevelCompletePanel) ...[
                              SizedBox(height: chromeGap),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: (16 * sScale).clamp(12.0, 24.0),
                                ),
                                child: SizedBox(
                                  height: actionBarHeight,
                                  child: WordBuilderActionBar(
                                    bookKey: key,
                                    l10n: l10n,
                                    canHint: canHint,
                                    canShuffle: !trayBlocked,
                                    canTranslate: canMeaning,
                                    hintCost: letterCost,
                                    hintTooltip: hintTip,
                                    translateTooltip: meaningTip,
                                  ),
                                ),
                              ),
                              SizedBox(height: chromeGap),
                            ],
                            if (isArkanoid && !showLevelCompletePanel)
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  12 * sScale,
                                  0,
                                  12 * sScale,
                                  (4 * sScale).clamp(2.0, 6.0),
                                ),
                                child: ArkanoidBallSpeedSlider(
                                  l10n: l10n,
                                  height: (26 * sScale).clamp(24.0, 30.0),
                                ),
                              ),
                            Expanded(
                              flex: isCompactBoard ? 1 : 6,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isCompactBoard
                                      ? (4 * sScale).clamp(2.0, 8.0)
                                      : (8 * sScale).clamp(4.0, 14.0),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, trayConstraints) {
                                    final w = trayConstraints.maxWidth;
                                    final side =
                                        math.min(w, trayConstraints.maxHeight) *
                                        (0.76 * sScale).clamp(0.56, 0.82);
                                    final completeCopy = _levelCompleteCopy(
                                      l10n,
                                    );
                                    final boardHPad = isCompactBoard
                                        ? (12 * sScale).clamp(10.0, 16.0)
                                        : 0.0;
                                    return AnimatedSwitcher(
                                      duration: WbTokens.dSlow,
                                      switchInCurve: WbTokens.cEnter,
                                      switchOutCurve: WbTokens.cExit,
                                      // Expand so physics boards stay full-width
                                      // and centered (equal left/right inset).
                                      layoutBuilder:
                                          (currentChild, previousChildren) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        );
                                      },
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.96,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: showLevelCompletePanel
                                          ? WordBuilderLevelCompletePanel(
                                              key: const ValueKey(
                                                'level-complete-actions',
                                              ),
                                              l10n: l10n,
                                              isDark: isDark,
                                              layoutScale: sScale,
                                              emoji: completeCopy.emoji,
                                              title: completeCopy.title,
                                              body: completeCopy.body,
                                              nextLabel: completeCopy.nextLabel,
                                              tierComplete:
                                                  _isCampaignTierComplete(),
                                              chapterComplete:
                                                  _isChapterComplete(),
                                              onNext:
                                                  _advanceAfterLevelComplete,
                                              onReplay: () => unawaited(
                                                ref
                                                    .read(
                                                      wordBuilderGameProvider(
                                                        key,
                                                      ).notifier,
                                                    )
                                                    .replayCurrentLevel(),
                                              ),
                                              onExit:
                                                  _finishCampaignStageAndExit,
                                            )
                                          : isCompactBoard
                                          ? Padding(
                                              key: ValueKey(
                                                isPuzzle
                                                    ? 'puzzle-board'
                                                    : isAngryWords
                                                    ? 'angry-words-board'
                                                    : 'arkanoid-board',
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                boardHPad,
                                                0,
                                                boardHPad,
                                                2 * sScale,
                                              ),
                                              child: isPuzzle
                                                  ? PuzzleLetterBoard(
                                                      bookKey: key,
                                                      level: s.level,
                                                      letters: s.circleLetters,
                                                    )
                                                  : isAngryWords
                                                  ? AngryWordsLetterBoard(
                                                      bookKey: key,
                                                      letters: s.circleLetters,
                                                      slotKeyBag:
                                                          _answerSlotKeys,
                                                      pathCardKey: _pathCardKey,
                                                    )
                                                  : ArkanoidLetterBoard(
                                                      bookKey: key,
                                                      letters: s.circleLetters,
                                                    ),
                                            )
                                          : Stack(
                                              key: const ValueKey(
                                                'letter-tray',
                                              ),
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
                                                          shape:
                                                              BoxShape.circle,
                                                          gradient: RadialGradient(
                                                            colors: [
                                                              scheme.primary
                                                                  .withValues(
                                                                    alpha: 0.14,
                                                                  ),
                                                              scheme.primary
                                                                  .withValues(
                                                                    alpha: 0.04,
                                                                  ),
                                                              Colors
                                                                  .transparent,
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
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                              6 * sScale,
                                                              0,
                                                              6 * sScale,
                                                              8 * sScale,
                                                            ),
                                                        child: SizedBox(
                                                          width: w,
                                                          height:
                                                              trayConstraints
                                                                  .maxHeight,
                                                          child: CircularLetterTray(
                                                            bookKey: key,
                                                            letters:
                                                                s.circleLetters,
                                                            layoutMinExtent:
                                                                math.min(
                                                                  w,
                                                                  side,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
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


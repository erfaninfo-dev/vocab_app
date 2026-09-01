import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/word_builder_sound_service.dart';
import '../../../l10n/app_localizations.dart';
import '../application/pvp_challenge_providers.dart';
import '../application/word_builder_campaign_providers.dart';
import '../application/word_builder_theme_categories_provider.dart';
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
import '../data/word_builder_theme_categories.dart';
import '../word_builder_theme_session_key.dart';
import '../word_builder_campaign_constants.dart';
import '../word_builder_campaign_session_key.dart';
import '../word_builder_coin_constants.dart';
import 'theme/word_builder_chapter_theme.dart';
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
import 'widgets/word_builder_coins_chip.dart';
import 'widgets/word_builder_meaning_banner.dart';
import 'widgets/word_builder_session_audio_sheet.dart';
import 'widgets/word_builder_tray_circle_button.dart';
import 'widgets/word_info_sheet.dart';

class WordBuilderSessionScreen extends ConsumerStatefulWidget {
  const WordBuilderSessionScreen({
    super.key,
    required this.bookKey,
    this.pvpMatchId,
    this.pvpTopicLabel,
  });

  final int bookKey;
  final int? pvpMatchId;
  final String? pvpTopicLabel;

  @override
  ConsumerState<WordBuilderSessionScreen> createState() =>
      _WordBuilderSessionScreenState();
}

class _WordBuilderSessionScreenState
    extends ConsumerState<WordBuilderSessionScreen>
    with WidgetsBindingObserver {
  final _answerSlotKeys = AnswerSlotKeyBag();
  DateTime? _pvpStartedAt;
  bool _pvpSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.pvpMatchId != null) {
      _pvpStartedAt = DateTime.now().toUtc();
    }
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
    unawaited(
      ref.read(wordBuilderTrayTrainAudioProvider(widget.bookKey)).stopAll(),
    );
    unawaited(
      ref.read(wordBuilderTrayPrisonAudioProvider(widget.bookKey)).stopAll(),
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

  bool _isCampaignTierComplete() {
    final camp = decodeWordBuilderCampaignSessionKey(widget.bookKey);
    return camp != null && camp.stage1Based >= kWordBuilderStagesPerTier;
  }

  ({String emoji, String title, String body, String nextLabel})
  _levelCompleteCopy(AppLocalizations l10n) {
    if (widget.pvpMatchId != null) {
      return (
        emoji: '🏆',
        title: l10n.wordBuilderLevelCompleteTitle,
        body: 'You found all 3 challenge words!',
        nextLabel: 'Submit score',
      );
    }
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
          emoji: '🚀🏆🎉',
          title: l10n.wordBuilderIntermediateCompleteTitle,
          body: l10n.wordBuilderIntermediateCompleteBody,
          nextLabel: l10n.wordBuilderStartAdvanced,
        );
      case WordBuilderDifficulty.advanced:
        return (
          emoji: '👑🏆🎉',
          title: l10n.wordBuilderAdvancedCompleteTitle,
          body: l10n.wordBuilderAdvancedCompleteBody,
          nextLabel: l10n.exit,
        );
    }
  }

  Future<void> _finishCampaignStageAndExit() async {
    if (widget.pvpMatchId != null) {
      if (mounted) {
        context.go('/word-builder/challenge/${widget.pvpMatchId}');
      }
      return;
    }
    await _saveCampaignStageProgress();
    if (mounted) context.pop();
  }

  Future<void> _submitPvpChallengeAndExit() async {
    final matchId = widget.pvpMatchId;
    if (matchId == null || _pvpSubmitting) return;
    setState(() => _pvpSubmitting = true);
    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s == null) {
      setState(() => _pvpSubmitting = false);
      return;
    }
    final words = s.solvedLower.toList()..sort();
    final started = _pvpStartedAt ?? DateTime.now().toUtc();
    final completed = DateTime.now().toUtc();
    try {
      await ref.read(pvpChallengeActionsProvider).submit(
            matchId: matchId,
            startedAt: started,
            completedAt: completed,
            words: words,
          );
      if (!mounted) return;
      context.go('/word-builder/challenge/$matchId');
    } catch (e) {
      if (mounted) {
        setState(() => _pvpSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e')),
        );
      }
    }
  }

  Future<void> _advanceAfterLevelComplete() async {
    if (widget.pvpMatchId != null) {
      await _submitPvpChallengeAndExit();
      return;
    }
    final key = widget.bookKey;
    final camp = decodeWordBuilderCampaignSessionKey(key);
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

    final themeStage = decodeWordBuilderThemeStageSessionKey(key);
    if (themeStage != null) {
      if (!mounted) return;
      final categories =
          ref.read(wordBuilderThemeCategoriesProvider).valueOrNull ??
          const <WordBuilderThemeCategory>[];
      final catIndex = themeStage.categoryIndex;
      var totalStages = 0;
      if (catIndex >= 0 && catIndex < categories.length) {
        final wordCount = themeCategoryPlayableWordCount(
          categories[catIndex],
          catIndex,
        );
        totalStages = themeCategoryStageCount(wordCount);
      }
      ref.invalidate(wordBuilderGameProvider(key));
      if (themeStage.stage1Based >= totalStages) {
        context.pop();
        return;
      }
      final nextKey = encodeWordBuilderThemeStageSessionKey(
        catIndex,
        themeStage.stage1Based + 1,
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
    final stage14Weapon = ref.watch(stage14WeaponProvider);
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
    final camp = decodeWordBuilderCampaignSessionKey(key);
    final stage1Based =
        camp?.stage1Based ?? ((async.valueOrNull?.levelIndex ?? 0) + 1);
    final chapterTheme = playMode == WordBuilderPlayMode.angryWords
        ? WbChapterTheme.forStage(stage1Based)
        : null;
    final chromeDark =
        chapterTheme?.chromeBrightness == Brightness.dark || isDark;
    final chromeOn = chapterTheme?.chromeOnSurface ??
        (isDark ? scheme.onSurface : const Color(0xFF5D4037));

    Widget session = Theme(
      data: funTheme,
      child: PopScope(
        canPop: !trayGameOver,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MagicBackground(isDark: chromeDark),
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
                title: widget.pvpTopicLabel == null
                    ? const SizedBox.shrink()
                    : Text(
                        widget.pvpTopicLabel!,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w800,
                          color: chromeOn,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: trayGameOver
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: chromeOn,
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
                            height: playMode.usesCompactLetterBoard ? 34 : 44,
                            width: playMode.usesCompactLetterBoard ? 34 : 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: chromeDark
                                  ? (chapterTheme?.chromeSurface ??
                                          scheme.surfaceContainerHighest)
                                      .withValues(alpha: 0.55)
                                  : chromeOn.withValues(alpha: 0.12),
                              border: Border.all(
                                color: (chapterTheme?.accent ??
                                        const Color(0xFFFFB300))
                                    .withValues(alpha: chromeDark ? 0.45 : 0.65),
                                width: 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: chromeDark ? 0.28 : 0.08,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.settings_rounded,
                                size: playMode.usesCompactLetterBoard ? 18 : 24,
                                color: chromeOn,
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
                          isDark: chromeDark,
                          scheme: scheme,
                          compact: playMode.usesCompactLetterBoard,
                          chromeSurface: chapterTheme?.chromeSurface,
                          chromeOnSurface: chapterTheme?.chromeOnSurface,
                          accent: chapterTheme?.accent,
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
                        final isPuzzle = playMode == WordBuilderPlayMode.puzzle;
                        final topScale = isCompactBoard
                            ? sScale * 0.92
                            : sScale;
                        final chromeBtn = isCompactBoard
                            ? (30 * sScale).clamp(28.0, 34.0)
                            : (50 * sScale).clamp(44.0, 54.0);
                        // Equal air between path card ↔ chrome ↔ game board.
                        final chromeGap = isCompactBoard
                            ? (16 * sScale).clamp(14.0, 20.0)
                            : 0.0;
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
                                layoutScale: isCompactBoard ? topScale : sScale,
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
                                              ? (8 * topScale).clamp(6.0, 10.0)
                                              : (11 * sScale).clamp(8.0, 14.0),
                                          horizontal: isCompactBoard
                                              ? (16 * topScale).clamp(
                                                  14.0,
                                                  20.0,
                                                )
                                              : (14 * sScale).clamp(10.0, 16.0),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          transitionBuilder: (child, anim) {
                                            return FadeTransition(
                                              opacity: anim,
                                              child: ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              ),
                                            );
                                          },
                                          // Translate replaces the selected-letter
                                          // text; hitting a letter clears meaning.
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
                                              : Row(
                                                  key: ValueKey(
                                                    'path|$built|${ghostNext ?? ''}|$prefixGlow',
                                                  ),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        built.isEmpty
                                                            ? ' '
                                                            : built
                                                                  .toUpperCase(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: GoogleFonts.fredoka(
                                                          fontSize:
                                                              (isCompactBoard
                                                                  ? 26
                                                                  : 32) *
                                                              topScale,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing:
                                                              isCompactBoard
                                                              ? 2
                                                              : 3,
                                                          color:
                                                              s.pathWrongHighlight
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
                                                        ),
                                                      ),
                                                    ),
                                                    if (ghostNext != null &&
                                                        !s.pathWrongHighlight) ...[
                                                      const SizedBox(width: 6),
                                                      Opacity(
                                                        opacity: 0.38,
                                                        child: DecoratedBox(
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFFFFB300,
                                                                  ).withValues(
                                                                    alpha: 0.55,
                                                                  ),
                                                            ),
                                                            color: isDark
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.06,
                                                                      )
                                                                : Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.45,
                                                                      ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8 *
                                                                      sScale,
                                                                  vertical:
                                                                      4 *
                                                                      sScale,
                                                                ),
                                                            child: Text(
                                                              ghostNext
                                                                  .toUpperCase(),
                                                              style: GoogleFonts.fredoka(
                                                                fontSize:
                                                                    22 * sScale,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: isDark
                                                                    ? const Color(
                                                                        0xFFFFF8E1,
                                                                      )
                                                                    : const Color(
                                                                        0xFF5D4037,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
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
                            // Equal gap: path card → chrome → game board.
                            if (isCompactBoard && !showLevelCompletePanel) ...[
                              SizedBox(height: chromeGap),
                              SizedBox(
                                height: chromeBtn,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.hint,
                                      diameter: chromeBtn,
                                      l10n: l10n,
                                      enabled: canHint,
                                      tooltipOverride: hintTip,
                                    ),
                                    WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.shuffle,
                                      diameter: chromeBtn,
                                      l10n: l10n,
                                      enabled: !trayBlocked,
                                    ),
                                    WordBuilderTrayCircleButton(
                                      bookKey: key,
                                      kind: WordBuilderTrayActionKind.translate,
                                      diameter: chromeBtn,
                                      l10n: l10n,
                                      enabled: canMeaning,
                                      tooltipOverride: meaningTip,
                                    ),
                                  ],
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
                                    final btn = chromeBtn;
                                    final inset = (22 * sScale).clamp(
                                      18.0,
                                      32.0,
                                    );
                                    final completeCopy = _levelCompleteCopy(
                                      l10n,
                                    );
                                    final boardHPad = isCompactBoard
                                        ? (12 * sScale).clamp(10.0, 16.0)
                                        : 0.0;
                                    return AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 520,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
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
                                          ? _LevelCompleteActionPanel(
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
                                                            chromeInset: inset,
                                                            chromeButtonSize:
                                                                btn,
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
                                                        WordBuilderTrayActionKind
                                                            .hint,
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
                                                    kind:
                                                        WordBuilderTrayActionKind
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
                                                    kind:
                                                        WordBuilderTrayActionKind
                                                            .translate,
                                                    diameter: btn,
                                                    l10n: l10n,
                                                    enabled: canMeaning,
                                                    tooltipOverride: meaningTip,
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

    if (chapterTheme != null) {
      session = AnnotatedRegion<SystemUiOverlayStyle>(
        value: chapterTheme.systemUiOverlayStyle,
        child: WbChapterThemeScope(theme: chapterTheme, child: session),
      );
    }
    return session;
  }
}

class _LevelCompleteActionPanel extends StatelessWidget {
  const _LevelCompleteActionPanel({
    super.key,
    required this.l10n,
    required this.isDark,
    required this.layoutScale,
    required this.emoji,
    required this.title,
    required this.body,
    required this.nextLabel,
    required this.tierComplete,
    required this.onNext,
    required this.onReplay,
    required this.onExit,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final double layoutScale;
  final String emoji;
  final String title;
  final String body;
  final String nextLabel;
  final bool tierComplete;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final s = layoutScale.clamp(0.85, 1.15);
    final titleColor = isDark
        ? const Color(0xFFFFF8E1)
        : const Color(0xFF4E342E);
    final bodyColor = isDark
        ? const Color(0xFFFFECB3).withValues(alpha: 0.82)
        : const Color(0xFF6D4C41);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 10 * s),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360 * s),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28 * s),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF5D4037), Color(0xFF2D2640)]
                    : const [Color(0xFFFFFDE7), Color(0xFFFFECB3)],
              ),
              border: Border.all(
                color: const Color(
                  0xFFFFB300,
                ).withValues(alpha: isDark ? 0.82 : 0.95),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF9800,
                  ).withValues(alpha: isDark ? 0.28 : 0.36),
                  blurRadius: 24 * s,
                  offset: Offset(0, 8 * s),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16 * s,
                  offset: Offset(0, 5 * s),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 16 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: tierComplete ? 46 * s : 40 * s),
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: (24 * s).clamp(20.0, 28.0),
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 5 * s),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: (13.5 * s).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: bodyColor,
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  _LevelCompleteButton(
                    label: nextLabel,
                    icon: Icons.arrow_forward_rounded,
                    filled: true,
                    isDark: isDark,
                    onPressed: onNext,
                  ),
                  SizedBox(height: 10 * s),
                  _LevelCompleteButton(
                    label: l10n.wordBuilderReplayLevel,
                    icon: Icons.replay_rounded,
                    filled: false,
                    isDark: isDark,
                    onPressed: onReplay,
                  ),
                  SizedBox(height: 10 * s),
                  _LevelCompleteButton(
                    label: l10n.exit,
                    icon: Icons.logout_rounded,
                    filled: false,
                    isDark: isDark,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCompleteButton extends StatelessWidget {
  const _LevelCompleteButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            foregroundColor: const Color(0xFF4E342E),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: child,
        ),
      );
    }

    final outlineForeground = isDark
        ? const Color(0xFFFFECB3)
        : const Color(0xFF5D4037);
    final outlineBorder = isDark
        ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
        : const Color(0xFFFFB300).withValues(alpha: 0.95);
    final outlineBackground = isDark
        ? const Color(0xFF3E3228).withValues(alpha: 0.64)
        : const Color(0xFFFFF8E1).withValues(alpha: 0.7);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: outlineBackground,
          foregroundColor: outlineForeground,
          side: BorderSide(color: outlineBorder, width: 1.6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/audio/angry_words_egg_crack_audio.dart';
import '../../../../../core/audio/angry_words_gun_audio.dart';
import '../../../../../core/audio/angry_words_pop_audio.dart';
import '../../../../../core/audio/angry_words_porcelain_break_audio.dart';
import '../../../../../core/audio/angry_words_sling_audio.dart';
import '../../../../../core/audio/angry_words_sling_snap_audio.dart';
import '../../../../../core/audio/angry_words_sling_whoosh_audio.dart';
import '../../../../../core/audio/app_haptics.dart';
import '../../../../../core/audio/word_builder_sound_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../application/word_builder_game_notifier.dart';
import '../../../application/word_builder_onboarding_prefs.dart';
import '../../../application/word_builder_session_audio.dart';
import '../../../domain/word_builder_game_logic.dart';
import '../../../domain/word_builder_models.dart';
import '../../../word_builder_campaign_session_key.dart';
import '../../theme/word_builder_motion.dart';
import '../answer_slot_key_bag.dart';
import '../coach/coach_overlay.dart';
import '../word_builder_combo_chip.dart';
import 'angry_words_celebrate.dart';
import 'angry_words_flight_overlay.dart';
import 'angry_words_loadout.dart';
import 'angry_words_paint_model.dart';
import 'angry_words_painter.dart';
import 'angry_words_physics.dart';

class _PathLetterAnchor {
  const _PathLetterAnchor({
    required this.char,
    required this.boardPos,
    required this.tintIndex,
  });

  final String char;
  final Offset boardPos;
  final int tintIndex;
}

/// Slingshot letter picker for Word Builder Angry Words mode.
///
/// PREFIX_CHECK (+ Classic catalog match) runs after every letter hit.
/// Aim preview updates live while dragging — core gameplay.
class AngryWordsLetterBoard extends ConsumerStatefulWidget {
  const AngryWordsLetterBoard({
    super.key,
    required this.bookKey,
    required this.letters,
    this.slotKeyBag,
    this.pathCardKey,
  });

  final int bookKey;
  final List<LetterInstance> letters;
  final AnswerSlotKeyBag? slotKeyBag;

  /// Path / typed-letter card — chicks fly here when a letter is found.
  final GlobalKey? pathCardKey;

  @override
  ConsumerState<AngryWordsLetterBoard> createState() =>
      _AngryWordsLetterBoardState();
}

class _AngryWordsLetterBoardState extends ConsumerState<AngryWordsLetterBoard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final _world = AngryWordsPhysicsWorld(width: 1, height: 1);
  late final AngryWordsPaintModel _paint = AngryWordsPaintModel(_world);
  late final AngryWordsBoardPainter _painter = AngryWordsBoardPainter(
    model: _paint,
  );
  Duration _lastElapsed = Duration.zero;
  final List<Offset> _trail = [];
  double _sparkLife = 0;
  double _wrongFlash = 0;
  double _successFlash = 0;
  double _prefixFlash = 0;
  String? _peekChar;
  double _peekFlash = 0;
  bool _wasWrong = false;
  bool _autoEvalBusy = false;
  bool _attemptClean = true;
  int _combo = 0;
  /// 0..1 remaining combo window (visual + soft reset).
  double _comboLife = 0;
  static const _comboWindowSec = 3.5;
  int? _layoutSig;
  bool _awaitingReload = false;
  /// After a solved word, rebuild floating letters from scratch (do not keep
  /// exploded `removed` flags — letter ids are reused 0..n each rebuild).
  bool _forceFreshLetterLayout = false;
  bool _gradualPropLayout = false;

  /// Word just solved: hold wall rebuild until celebrate asks for gradual refill
  /// (avoids one-frame full wall → empty → refill flash).
  bool _pendingGradualRelayout = false;
  bool _windButtonHeld = false;
  bool _wasAimingAtWind = false;
  int? _lastSoftLockId;
  Size _boardSize = Size.zero;
  final List<AngryWordsLetterExplosion> _explosions = [];
  final List<_PathLetterAnchor> _pathAnchors = [];
  final List<AngryWordsFlightLetter> _flights = [];
  OverlayEntry? _flightOverlay;
  bool _celebrateBusy = false;
  Completer<void>? _flightCompleter;

  /// Phase-6 first-run coach.
  bool _coachEnabled = false;
  bool _coachBootstrapped = false;
  int _coachPops = 0;
  bool _freeShotOk = false;
  bool _prefixCoachVisible = false;
  bool _prefixCoachDone = false;
  /// Armed for this session when prefs say onboarding is incomplete.
  bool _prefixOnWrongArmed = false;
  List<CoachStep> _coachSteps = const [];
  int _hudCargo = -1;
  AngryWordsPhase? _hudPhase;
  int _hudCombo = 0;

  static const _windBtnSize = 52.0;
  static const _windBtnRight = 10.0;
  static const _windBtnBottom = 64.0;

  Offset get _windButtonCenter => Offset(
        _boardSize.width - _windBtnRight - _windBtnSize / 2,
        _boardSize.height - _windBtnBottom - _windBtnSize / 2,
      );

  void _syncWindFromSources({bool hapticOnAimEnter = false}) {
    final aimingAtWind = !hardBlockedForWind &&
        (_world.aiming || _world.gunTriggerHeld) &&
        _boardSize.width > 1 &&
        _world.isAimingToward(_windButtonCenter, hitRadius: 96);
    final held = _windButtonHeld || aimingAtWind;
    if (hapticOnAimEnter && aimingAtWind && !_wasAimingAtWind) {
      appHapticSelection(ref);
    }
    _wasAimingAtWind = aimingAtWind;
    _world.setWindAimActive(aimingAtWind && _world.aiming);
    if (_world.windHeld != held) {
      _world.setWindHeld(held);
    }
  }

  bool get hardBlockedForWind {
    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    return (s?.trayVictorySequenceActive ?? false) ||
        _celebrateBusy ||
        _flights.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(wordBuilderGameProvider(widget.bookKey).notifier)
            .preparePhysicsLetterMode(),
      );
      unawaited(ref.read(angryWordsGunAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsPopAudioProvider).ensureLoaded());
      unawaited(
        ref.read(angryWordsPorcelainBreakAudioProvider).ensureLoaded(),
      );
      unawaited(ref.read(angryWordsSlingAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsSlingSnapAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsSlingWhooshAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsEggCrackAudioProvider).ensureLoaded());
      _bootstrapCoachIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_ticker.isActive) _ticker.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_ticker.isActive) _ticker.stop();
        unawaited(_stopAngryWordsAudio());
    }
  }

  Future<void> _stopAngryWordsAudio() async {
    await ref.read(angryWordsGunAudioProvider).stop();
    await ref.read(angryWordsSlingAudioProvider).stop();
  }

  void _bootstrapCoachIfNeeded() {
    if (_coachBootstrapped) return;
    _coachBootstrapped = true;
    unawaited(() async {
      final done =
          await ref.read(wordBuilderAngryWordsOnboardingProvider.future);
      if (!mounted || done) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      setState(() {
        _coachEnabled = true;
        _prefixOnWrongArmed = true;
        _coachSteps = _buildAngryWordsCoachSteps(l10n);
      });
    }());
  }

  List<CoachStep> _buildAngryWordsCoachSteps(AppLocalizations l10n) {
    final hammer = _world.usesHammer;
    return [
      CoachStep(
        id: 'cage_shoot',
        message: hammer
            ? l10n.wordBuilderCoachHammerSmash
            : l10n.wordBuilderCoachHoldFire,
        targetRect: hammer ? _hammerSpotlightRect : _muzzleSpotlightRect,
        finger: hammer ? CoachFingerKind.dragPull : CoachFingerKind.hold,
        isComplete: () => _coachPops >= 3,
      ),
      CoachStep(
        id: 'cage_cargo',
        message: l10n.wordBuilderCoachLettersHidden,
        targetRect: _cargoSpotlightRect,
        finger: CoachFingerKind.none,
        autoAdvanceAfter: const Duration(milliseconds: 2200),
        allowSkip: true,
        blocksInput: false,
      ),
      CoachStep(
        id: 'wait_clear',
        message: l10n.wordBuilderCoachClearWall,
        targetRect: null,
        dimOpacity: 0.28,
        blocksInput: false,
        isComplete: () =>
            _world.phase == AngryWordsPhase.freeing ||
            _world.phase == AngryWordsPhase.free,
      ),
      CoachStep(
        id: 'freeing_banner',
        message: l10n.wordBuilderCoachWallCleared,
        autoAdvanceAfter: const Duration(milliseconds: 1200),
        dimOpacity: 0.4,
        blocksInput: false,
      ),
      CoachStep(
        id: 'free_aim',
        message: l10n.wordBuilderCoachPullRelease,
        targetRect: _muzzleSpotlightRect,
        finger: CoachFingerKind.dragPull,
        isComplete: () => _freeShotOk,
      ),
    ];
  }

  Rect? _muzzleSpotlightRect() {
    if (_boardSize.width < 8) return null;
    final m = _world.muzzle;
    return Rect.fromCenter(center: m, width: 88, height: 72);
  }

  Rect? _hammerSpotlightRect() {
    if (_boardSize.width < 8) return null;
    final c = _world.hammerPos ?? _world.muzzle;
    return Rect.fromCenter(center: c, width: 96, height: 96);
  }

  Rect? _cargoSpotlightRect() {
    for (final P in _world.props) {
      if (P.removed || !P.holdsLetter || !P.isSpawnVisible) continue;
      return Rect.fromCircle(center: P.pos, radius: P.radius + 10);
    }
    return _muzzleSpotlightRect();
  }

  Rect? _expectedLetterSpotlightRect(String? peekLower) {
    if (peekLower == null || peekLower.isEmpty) return null;
    for (final L in _world.letters) {
      if (L.removed) continue;
      if (L.letter.char.toLowerCase() == peekLower) {
        return Rect.fromCircle(center: L.pos, radius: L.radius + 12);
      }
    }
    for (final P in _world.props) {
      if (P.removed || P.cargo == null) continue;
      if (P.cargo!.char.toLowerCase() == peekLower) {
        return Rect.fromCircle(center: P.pos, radius: P.radius + 12);
      }
    }
    return null;
  }

  Future<void> _finishMainCoach() async {
    if (!_coachEnabled) return;
    setState(() => _coachEnabled = false);
    await ref
        .read(wordBuilderAngryWordsOnboardingProvider.notifier)
        .markComplete();
  }

  Future<void> _finishPrefixCoach() async {
    setState(() {
      _prefixCoachVisible = false;
      _prefixCoachDone = true;
      _prefixOnWrongArmed = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeFlightOverlay();
    _windButtonHeld = false;
    _world.setWindHeld(false);
    _world.setGunTrigger(false);
    unawaited(ref.read(angryWordsGunAudioProvider).stop());
    unawaited(ref.read(angryWordsSlingAudioProvider).stop());
    _ticker.dispose();
    _paint.dispose();
    super.dispose();
  }

  void _removeFlightOverlay() {
    _flightOverlay?.remove();
    _flightOverlay = null;
  }

  void _syncFlightOverlay() {
    if (_flights.isEmpty) {
      _removeFlightOverlay();
      return;
    }
    if (_flightOverlay == null) {
      _flightOverlay = OverlayEntry(
        builder: (context) => AngryWordsFlightOverlay(flights: _flights),
      );
      Overlay.of(context, rootOverlay: true).insert(_flightOverlay!);
    } else {
      _flightOverlay!.markNeedsBuild();
    }
  }

  void _tickFlights(double dt) {
    var anySettled = false;
    var allDone = true;
    final reveal = ref.read(angryWordsSlotRevealProvider);
    var revealed = reveal?.revealedCount ?? 0;
    for (var i = 0; i < _flights.length; i++) {
      final f = _flights[i];
      if (f.delay > 0) {
        f.delay -= dt;
        allDone = false;
        continue;
      }
      if (f.t < 1) {
        f.age += dt;
        f.t = (f.t + dt / f.durationSec).clamp(0.0, 1.0);
        allDone = false;
      } else if (f.asChick && !f.settled) {
        f.age += dt;
      }
      if (f.t >= 1 && !f.settled) {
        f.settled = true;
        anySettled = true;
        revealed = math.max(revealed, i + 1);
        appHapticSelection(ref);
      }
      if (!f.settled) allDone = false;
    }
    if (anySettled && reveal != null) {
      ref.read(angryWordsSlotRevealProvider.notifier).state =
          AngryWordsSlotReveal(
            wordNorm: reveal.wordNorm,
            revealedCount: revealed,
          );
    }
    _syncFlightOverlay();
    if (allDone && _flights.isNotEmpty) {
      final c = _flightCompleter;
      if (c != null && !c.isCompleted) c.complete();
    }
  }

  Future<void> _setGunTrigger(bool held) async {
    _world.setGunTrigger(held);
    if (!held) return;
    // Preload single-shot clip so the first bullet already has audio ready.
    await ref.read(angryWordsGunAudioProvider).ensureLoaded();
  }

  void _syncSlingStretchAudio() {
    final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
    ref.read(angryWordsSlingAudioProvider).sync(
          enabled: sfx,
          aiming: _world.aiming && _world.isFreePhase && !_world.usesGun,
          pullDistance: _world.pullDistance,
          powerNorm: _world.powerNorm,
          minPull: AngryWordsPhysicsWorld.minPull,
        );
  }

  @override
  void didUpdateWidget(covariant AngryWordsLetterBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameLetterIds(oldWidget.letters, widget.letters)) {
      _layoutSig = null;
    }
  }

  bool _sameLetterIds(List<LetterInstance> a, List<LetterInstance> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].char != b[i].char) return false;
    }
    return true;
  }

  AngryWordsLoadout _loadoutForCurrentSession() {
    final levelIndex =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull?.levelIndex ??
            0;
    return AngryWordsLoadout.forSession(
      bookKey: widget.bookKey,
      levelIndex: levelIndex,
    );
  }

  void _ensureLayout(Size size) {
    final loadout = _loadoutForCurrentSession();
    final sig = Object.hash(
      size.width.round(),
      size.height.round(),
      widget.letters.map((e) => '${e.id}${e.char}').join(','),
      loadout.profileIndex,
    );
    if (_layoutSig == sig && !_forceFreshLetterLayout) return;

    final sizeChanged = (_world.width - size.width).abs() > 0.5 ||
        (_world.height - size.height).abs() > 0.5;

    // Keep the post-solve wall as-is until celebrate triggers gradual refill.
    if (_pendingGradualRelayout && !_forceFreshLetterLayout) {
      if (_world.width > 1 && sizeChanged) {
        _world.resize(size.width, size.height);
      } else {
        _world.width = size.width;
        _world.height = size.height;
      }
      return;
    }

    final worldLetters = [for (final L in _world.letters) L.letter];
    final sameLetterSet = _world.letters.isNotEmpty &&
        _sameLetterIds(worldLetters, widget.letters);

    // Pure resize: keep live positions / mid-word explosions.
    if (!_forceFreshLetterLayout &&
        sameLetterSet &&
        sizeChanged &&
        _world.width > 1 &&
        _world.loadout.profileIndex == loadout.profileIndex) {
      _world.resize(size.width, size.height);
      _layoutSig = sig;
      if (!_world.inFlight) _world.resetToCannon();
      return;
    }

    _layoutSig = sig;
    _forceFreshLetterLayout = false;
    final gradual = _gradualPropLayout || _pendingGradualRelayout;
    _gradualPropLayout = false;
    _pendingGradualRelayout = false;
    _world.width = size.width;
    _world.height = size.height;
    _world.layoutLetters(
      widget.letters,
      seed: sig,
      loadout: loadout,
      gradualProps: gradual,
    );
    _world.resetToCannon();
  }

  void _onTick(Duration elapsed) {
    final dtMs = _lastElapsed == Duration.zero
        ? 16
        : (elapsed - _lastElapsed).inMilliseconds;
    _lastElapsed = elapsed;
    final dt = (dtMs.clamp(1, 32)) / 1000.0;

    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s == null) return;

    final selectedIds = s.path.map((e) => e.id).toSet();

    if (s.pathWrongHighlight && !_wasWrong) {
      _wrongFlash = 1;
      _attemptClean = false;
      _combo = 0;
      _comboLife = 0;
      appHapticLight(ref);
      unawaited(_clearWrongAfterFlash());
      if (_prefixOnWrongArmed && !_prefixCoachDone && !_prefixCoachVisible) {
        setState(() => _prefixCoachVisible = true);
      }
    }
    _wasWrong = s.pathWrongHighlight;

    if (_wrongFlash > 0) {
      _wrongFlash = (_wrongFlash - dt * 2.2).clamp(0.0, 1.0);
    }
    if (_successFlash > 0) {
      _successFlash = (_successFlash - dt * 1.4).clamp(0.0, 1.0);
    }
    if (_prefixFlash > 0) {
      _prefixFlash = (_prefixFlash - dt * 3.0).clamp(0.0, 1.0);
    }
    if (_peekFlash > 0) {
      // ~400ms peek flash after wrong path clears.
      _peekFlash = (_peekFlash - dt * 2.5).clamp(0.0, 1.0);
      if (_peekFlash <= 0) _peekChar = null;
    }
    if (_sparkLife > 0) {
      _sparkLife = (_sparkLife - dt * 3.2).clamp(0.0, 1.0);
    }
    for (final e in _explosions) {
      final decay = e.material == AngryWordsPropMaterial.porcelain
          ? 1.65
          : e.material == AngryWordsPropMaterial.foam ||
                  e.material == AngryWordsPropMaterial.sand
              ? 1.15
              : e.material == AngryWordsPropMaterial.stone ||
                      e.material == AngryWordsPropMaterial.metal
                  ? 1.35
                  : 1.55;
      e.life = (e.life - dt * decay).clamp(0.0, 2.0);
    }
    _explosions.removeWhere((e) => e.life <= 0);

    if (_flights.isNotEmpty) {
      _tickFlights(dt);
    }

    if (!s.trayVictorySequenceActive &&
        _flights.isEmpty &&
        !_celebrateBusy) {
      // Keep letter chaos / drift running even while evaluating a hit.
      _world.update(dt, selectedIds: selectedIds);
      if (!_world.usesGun && _world.gunTriggerHeld) {
        unawaited(_setGunTrigger(false));
      }
      // One shot2.WAV per bullet (dedicated player, preloaded).
      final shots = _world.shotsFiredThisFrame;
      if (shots > 0) {
        final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
        final gun = ref.read(angryWordsGunAudioProvider);
        for (var i = 0; i < shots; i++) {
          gun.playShot(enabled: sfx);
          appHapticLightThrottled(ref);
        }
        _world.shotsFiredThisFrame = 0;
      }
      _syncWindFromSources(hapticOnAimEnter: true);
      _syncSlingStretchAudio();
      final softLock = _world.softLockLetterId;
      if (_world.aiming &&
          softLock != null &&
          softLock != _lastSoftLockId) {
        appHapticSelection(ref);
      }
      _lastSoftLockId = _world.aiming ? softLock : null;
      final propPops = _world.takePropPops();
      // Always allow pop.WAV (own player + rate limit) — single or spray.
      for (final pop in propPops) {
        if (_coachEnabled) _coachPops += 1;
        _spawnPropExplosion(pop, playSound: true);
      }
      while (_explosions.length > 28) {
        _explosions.removeAt(0);
      }
      if (_world.isFreePhase && !_autoEvalBusy) {
        final hit = _world.hitLetter;
        if (hit != null && !s.pathWrongHighlight) {
          unawaited(_onLetterHit(hit));
        } else if (!_world.inFlight &&
            !_world.aiming &&
            _awaitingReload &&
            hit == null) {
          _awaitingReload = false;
          _world.resetToCannon();
        }
      }
    } else if (_world.windHeld && !_windButtonHeld) {
      _world.setWindHeld(false);
      _wasAimingAtWind = false;
    }

    if (_world.isFreePhase && _world.inFlight) {
      _trail.add(_world.ball);
      if (_trail.length > 8) _trail.removeAt(0);
      _awaitingReload = true;
    } else if (!_world.aiming) {
      _trail.clear();
    }

    if (_world.cageCombo >= 2) {
      if (_world.cageCombo > _combo) {
        _comboLife = 1;
      }
      _combo = math.max(_combo, _world.cageCombo);
    }
    if (_combo >= 2 && _comboLife > 0) {
      _comboLife = (_comboLife - dt / _comboWindowSec).clamp(0.0, 1.0);
      if (_comboLife <= 0) {
        _combo = 0;
        _world.cageCombo = 0;
      }
    }

    final motion = WbMotion.of(context);
    _paint.selectedIds = selectedIds;
    _paint.wrongFlash = _wrongFlash;
    _paint.successFlash = _successFlash;
    _paint.prefixFlash = _prefixFlash;
    _paint.sparkLife = _sparkLife;
    _paint.trail = _trail;
    _paint.explosions = _explosions;
    _paint.isDark = Theme.of(context).brightness == Brightness.dark;
    _paint.scheme = Theme.of(context).colorScheme;
    _paint.nextLetterHighlight = _nextLetterHighlightFor(s);
    _paint.peekChar = _peekChar;
    _paint.peekFlash = _peekFlash;
    _paint.allowIdlePulse = motion.allowIdlePulse;
    _paint.particleScale = motion.particleScale;
    _paint.markNeedsPaint();

    final cargo = _world.remainingCargoCount;
    final phase = _world.phase;
    final comboShown = _combo >= 2 ? _combo : 0;
    if (cargo != _hudCargo ||
        phase != _hudPhase ||
        comboShown != _hudCombo) {
      _hudCargo = cargo;
      _hudPhase = phase;
      _hudCombo = comboShown;
      if (mounted) setState(() {});
    }
  }

  Future<void> _onLetterHit(LetterInstance hit) async {
    final n = ref.read(wordBuilderGameProvider(widget.bookKey).notifier);
    final before =
        ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (before == null) {
      _scheduleReload();
      return;
    }

    final correctForActive = n.isPhysicsNextLetterProgress(hit.char);

    Offset? hitPos;
    for (final L in _world.letters) {
      if (L.letter.id == hit.id) {
        hitPos = L.pos;
        break;
      }
    }
    hitPos ??= _world.sparkAt ?? _world.ball;

    final porcelainLetters = _world.loadout.isPorcelainOnlyWall;
    final sfxEnabled = ref.read(wordBuilderGameSfxEnabledProvider);

    if (correctForActive) {
      // Hit-stop: freeze sim ~50ms so the impact reads before shards fly.
      _world.requestHitStop(WbMotion.hitStop.inMilliseconds / 1000.0);
      var tint = 0;
      for (final L in _world.letters) {
        if (L.letter.id == hit.id) {
          tint = L.tintIndex;
          break;
        }
      }
      _pathAnchors.add(
        _PathLetterAnchor(
          char: hit.char,
          boardPos: hitPos,
          tintIndex: tint,
        ),
      );
      _world.explodeLetter(hit.id);
      // Correct: shell cracks, chick flies — no yolk. Stage 22 = jug shatter.
      if (porcelainLetters) {
        _spawnPropExplosion(
          AngryWordsPropPop(
            at: hitPos,
            palette: tint,
            radius: 16,
            material: AngryWordsPropMaterial.porcelain,
          ),
        );
      } else {
        _spawnEggLetterBreak(hitPos);
        ref.read(angryWordsEggCrackAudioProvider).play(enabled: sfxEnabled);
      }
      _sparkLife = 1;
      appHapticMedium(ref);

      final landing = _chickLandingGlobal(
        before: before,
        letterIndex: before.path.length,
        fallbackBoardPos: hitPos,
      );
      if (landing != null) {
        await _flySingleChick(
          boardStart: hitPos,
          char: hit.char,
          tintIndex: tint,
          endGlobal: landing,
        );
        if (!mounted) return;
      }
    } else {
      // Wrong: shatter + scatter. Eggs spill yolk; stage 22 jugs do not.
      var letterR = 16.0;
      var tint = 0;
      for (final L in _world.letters) {
        if (L.letter.id == hit.id) {
          letterR = L.radius;
          tint = L.tintIndex;
          break;
        }
      }
      _pathAnchors.clear();
      if (porcelainLetters) {
        _spawnPropExplosion(
          AngryWordsPropPop(
            at: hitPos,
            palette: tint,
            radius: letterR,
            material: AngryWordsPropMaterial.porcelain,
          ),
        );
      } else {
        _spawnEggLetterBreak(hitPos);
        _world.spillYolkAt(hitPos, fromRadius: letterR, seed: hit.id);
        ref.read(angryWordsEggCrackAudioProvider).play(enabled: sfxEnabled);
      }
      _world.scatterFromWrongHit(hit.id);
      _sparkLife = 1;
      appHapticHeavy(ref);
    }

    await n.appendLetterFromDrag(hit);
    if (!mounted) return;

    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s == null || s.pathWrongHighlight || _autoEvalBusy) {
      _scheduleReload();
      return;
    }

    _autoEvalBusy = true;
    try {
      await n.evaluatePhysicsLetterAfterLetter(pathClean: _attemptClean);
      if (!mounted) return;
      final after =
          ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
      if (after?.feedbackMessage == '__arkanoid_prefix' ||
          after?.feedbackMessage == '__physics_prefix') {
        _prefixFlash = 1;
        _combo += 1;
        _comboLife = 1;
        if (_coachEnabled && _world.isFreePhase) _freeShotOk = true;
      }
      if (after?.feedbackMessage == '__correct' ||
          after?.feedbackMessage == '__correct_perfect') {
        _combo += 1;
        _comboLife = 1;
        _world.requestScreenPunch(0.55);
        unawaited(appHapticWordComplete(ref));
        if (_coachEnabled && _world.isFreePhase) _freeShotOk = true;
      }
    } finally {
      _autoEvalBusy = false;
      _scheduleReload();
    }
  }

  Future<void> _celebrateLevelComplete() async {
    final remaining = <AngryWordsLetterTarget>[
      for (final L in _world.letters)
        if (!L.removed) L,
    ];
    final remainingProps = <AngryWordsPropBubble>[
      for (final P in _world.props)
        if (!P.removed) P,
    ];
    if (remaining.isEmpty && remainingProps.isEmpty) {
      _successFlash = 1;
      await ref
          .read(wordBuilderGameProvider(widget.bookKey).notifier)
          .clearAngryWordsVictoryHold();
      return;
    }

    final center = Offset(_world.width * 0.5, _world.height * 0.35);
    remaining.sort((a, b) {
      final da = (a.pos - center).distanceSquared;
      final db = (b.pos - center).distanceSquared;
      return da.compareTo(db);
    });
    remainingProps.sort((a, b) {
      final da = (a.pos - center).distanceSquared;
      final db = (b.pos - center).distanceSquared;
      return da.compareTo(db);
    });

    final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
    final sounds = ref.read(wordBuilderSoundServiceProvider);
    final bgm = ref.read(wordBuilderBgmPlayerProvider);
    // Burst of letterPop + BGM together crashes just_audio_windows.
    await bgm.beginSfxBurst();
    // On Windows, keep visual/haptic pops only — one levelComplete at the end.
    final playPopSfx = sfx && !WordBuilderSoundService.isFragileDesktopAudio;
    final popGapMs = WordBuilderSoundService.isFragileDesktopAudio ? 70 : 110;
    try {
      for (final P in remainingProps) {
        if (!mounted) return;
        P.removed = true;
        _spawnPropExplosion(
          AngryWordsPropPop(
            at: P.pos,
            palette: P.palette,
            radius: P.radius,
            material: P.material,
          ),
          playSound: playPopSfx,
        );
        if (!mounted) return;
        setState(() {});
        await Future<void>.delayed(Duration(milliseconds: popGapMs));
      }
      for (final L in remaining) {
        if (!mounted) return;
        final pos = L.pos;
        final char = L.letter.char;
        _world.explodeLetter(L.letter.id);
        _spawnExplosion(pos, char);
        _sparkLife = 1;
        if (playPopSfx) {
          await sounds.play(WordBuilderSound.letterPop, enabled: true);
        }
        if (!mounted) return;
        appHapticMedium(ref);
        setState(() {});
        await Future<void>.delayed(Duration(milliseconds: popGapMs));
      }
      if (!mounted) return;
      await sounds.play(WordBuilderSound.levelComplete, enabled: sfx);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      await ref
          .read(wordBuilderGameProvider(widget.bookKey).notifier)
          .clearAngryWordsVictoryHold();
      if (!mounted) return;
      _successFlash = 1;
      _world.requestScreenPunch(0.7);
      appHapticHeavy(ref);
      setState(() {});
    } finally {
      await bgm.endSfxBurst();
    }
  }

  void _spawnExplosion(Offset at, String char) {
    final rng = math.Random(char.codeUnitAt(0) + at.dx.round());
    final bits = <AngryWordsExplosionBit>[];
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi * 2 / 14 + rng.nextDouble() * 0.4;
      final speed = 90 + rng.nextDouble() * 140;
      bits.add(
        AngryWordsExplosionBit(
          angle: a,
          speed: speed,
          size: 3.5 + rng.nextDouble() * 4.5,
          color: i.isEven
              ? const Color(0xFFFFD54F)
              : const Color(0xFFFF7043),
        ),
      );
    }
    _explosions.add(
      AngryWordsLetterExplosion(
        at: at,
        char: char.toUpperCase(),
        life: 1,
        bits: bits,
      ),
    );
  }

  /// Shell shards when a free-phase letter-egg is found (yolk is a live blob).
  void _spawnEggLetterBreak(Offset at) {
    final rng = math.Random(at.dx.round() * 17 + at.dy.round());
    const shell = Color(0xFFFFF8E1);
    const shellDark = Color(0xFFE8D5B5);
    final bits = <AngryWordsExplosionBit>[];
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi * 2 / 18 + rng.nextDouble() * 0.35;
      bits.add(
        AngryWordsExplosionBit(
          angle: a,
          speed: 120 + rng.nextDouble() * 190,
          size: 2.2 + rng.nextDouble() * 4.0,
          color: i.isEven ? shell : shellDark,
          shape: AngryWordsBitShape.shard,
        ),
      );
    }
    _explosions.add(
      AngryWordsLetterExplosion(
        at: at,
        char: '',
        life: 1,
        bits: bits,
        juicy: true,
        ringA: const Color(0xFFFFF8E1),
        ringB: const Color(0xFFFFD54F),
        material: AngryWordsPropMaterial.egg,
      ),
    );
  }

  void _spawnPropExplosion(
    AngryWordsPropPop pop, {
    bool playSound = true,
  }) {
    final palette = angryWordsColorsForMaterial(pop.material, pop.palette);
    final rng = math.Random(
      pop.palette * 31 + pop.at.dx.round() + pop.material.index * 17,
    );
    final profile = _popProfileFor(pop.material);
    final motionScale = mounted ? WbMotion.of(context).particleScale : 1.0;
    final bits = <AngryWordsExplosionBit>[];
    if (pop.material == AngryWordsPropMaterial.egg) {
      // Shell shards only — yolk becomes a live floor puddle.
      const shell = Color(0xFFFFF8E1);
      const shellDark = Color(0xFFE8D5B5);
      final shardN = math.max(4, (16 * motionScale).round());
      for (var i = 0; i < shardN; i++) {
        final a = i * math.pi * 2 / shardN + rng.nextDouble() * 0.4;
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: 130 + rng.nextDouble() * 200,
            size: 2.4 + rng.nextDouble() * 4.2,
            color: i.isEven ? shell : shellDark,
            shape: AngryWordsBitShape.shard,
          ),
        );
      }
    } else {
      final count = math.max(2, (profile.count * motionScale).round());
      for (var i = 0; i < count; i++) {
        final a = i * math.pi * 2 / count + rng.nextDouble() * 0.55;
        final speed = profile.speedMin +
            rng.nextDouble() * (profile.speedMax - profile.speedMin);
        final shape = profile.shapes[i % profile.shapes.length];
        final accent = i % 3 == 0 && profile.accent != null
            ? profile.accent!
            : (i.isEven ? palette[0] : palette[1]);
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: speed,
            size: profile.sizeMin +
                rng.nextDouble() * (profile.sizeMax - profile.sizeMin),
            color: accent,
            shape: shape,
          ),
        );
      }
    }

    // Extra ceramic shatter: fine shards stay near the jug (tight radius).
    if (pop.material == AngryWordsPropMaterial.porcelain) {
      for (var i = 0; i < 22; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: 22 + rng.nextDouble() * 48,
            size: 1.0 + rng.nextDouble() * 1.8,
            color: i.isEven ? palette[0] : palette[1],
            shape: AngryWordsBitShape.shard,
          ),
        );
      }
      for (var i = 0; i < 12; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: 16 + rng.nextDouble() * 36,
            size: 0.8 + rng.nextDouble() * 1.4,
            color: palette[0],
            shape: AngryWordsBitShape.shard,
          ),
        );
      }
      // Powder cloud: brief beige puff near the break (fades faster in paint).
      const dustColors = [
        Color(0xFFEDE7E0),
        Color(0xFFD7CCC8),
        Color(0xFFBCAAA4),
        Color(0xFFF5F0E8),
      ];
      for (var i = 0; i < 14; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: 8 + rng.nextDouble() * 22,
            size: 2.4 + rng.nextDouble() * 3.2,
            color: dustColors[i % dustColors.length],
            shape: AngryWordsBitShape.dust,
          ),
        );
      }
    }

    if (pop.steamy) {
      for (var i = 0; i < 8; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        bits.add(
          AngryWordsExplosionBit(
            angle: a,
            speed: 40 + rng.nextDouble() * 70,
            size: 4 + rng.nextDouble() * 5,
            color: const Color(0xFFE1F5FE),
            shape: AngryWordsBitShape.dust,
          ),
        );
      }
    }
    _explosions.add(
      AngryWordsLetterExplosion(
        at: pop.at,
        char: '',
        life: profile.life,
        bits: bits,
        juicy: profile.juicy,
        steamy: pop.steamy,
        chromatic: _world.loadout.element == AngryWordsBulletElement.plasma ||
            _world.loadout.element == AngryWordsBulletElement.laser,
        ringA: profile.ringA,
        ringB: profile.ringB,
        material: pop.material,
      ),
    );
    _sparkLife = 1;
    appHapticSelection(ref);
    if (playSound) {
      final sfxEnabled = ref.read(wordBuilderGameSfxEnabledProvider);
      if (pop.material == AngryWordsPropMaterial.porcelain ||
          (pop.material == AngryWordsPropMaterial.glass &&
              _world.loadout.isBottleOnlyWall)) {
        ref.read(angryWordsPorcelainBreakAudioProvider).play(
          enabled: sfxEnabled,
        );
      } else {
        ref.read(angryWordsPopAudioProvider).play(
          enabled: sfxEnabled,
        );
      }
    }
  }

  static _AngryWordsPopProfile _popProfileFor(AngryWordsPropMaterial m) {
    return switch (m) {
      AngryWordsPropMaterial.glass => const _AngryWordsPopProfile(
        count: 34,
        speedMin: 160,
        speedMax: 360,
        sizeMin: 2.2,
        sizeMax: 5.8,
        shapes: [AngryWordsBitShape.shard, AngryWordsBitShape.spark],
        ringA: Color(0xFFE0F7FA),
        ringB: Color(0xFF4DD0E1),
        accent: Color(0xFFFFFFFF),
      ),
      AngryWordsPropMaterial.crystal => const _AngryWordsPopProfile(
        count: 32,
        speedMin: 150,
        speedMax: 340,
        sizeMin: 2.4,
        sizeMax: 6.2,
        shapes: [
          AngryWordsBitShape.shard,
          AngryWordsBitShape.glitter,
          AngryWordsBitShape.spark,
        ],
        ringA: Color(0xFFF3E5F5),
        ringB: Color(0xFFAB47BC),
        accent: Color(0xFFFFFFFF),
      ),
      AngryWordsPropMaterial.porcelain => const _AngryWordsPopProfile(
        count: 36,
        speedMin: 28,
        speedMax: 72,
        sizeMin: 1.0,
        sizeMax: 2.6,
        shapes: [
          AngryWordsBitShape.shard,
          AngryWordsBitShape.shard,
          AngryWordsBitShape.spark,
        ],
        ringA: Color(0xFFEDE7E0),
        ringB: Color(0xFFBCAAA4),
        accent: Color(0xFFEEEEEE),
        juicy: false,
        life: 1.0,
      ),
      AngryWordsPropMaterial.ice => const _AngryWordsPopProfile(
        count: 28,
        speedMin: 120,
        speedMax: 280,
        sizeMin: 2.5,
        sizeMax: 6.0,
        shapes: [
          AngryWordsBitShape.shard,
          AngryWordsBitShape.dust,
          AngryWordsBitShape.spark,
        ],
        ringA: Color(0xFFE1F5FE),
        ringB: Color(0xFF81D4FA),
        accent: Color(0xFFFFFFFF),
      ),
      AngryWordsPropMaterial.wood => const _AngryWordsPopProfile(
        count: 22,
        speedMin: 90,
        speedMax: 230,
        sizeMin: 2.8,
        sizeMax: 6.5,
        shapes: [AngryWordsBitShape.chip, AngryWordsBitShape.round],
        ringA: Color(0xFFD7CCC8),
        ringB: Color(0xFF6D4C41),
      ),
      AngryWordsPropMaterial.stone => const _AngryWordsPopProfile(
        count: 18,
        speedMin: 70,
        speedMax: 200,
        sizeMin: 3.5,
        sizeMax: 7.5,
        shapes: [AngryWordsBitShape.round, AngryWordsBitShape.dust],
        ringA: Color(0xFFB0BEC5),
        ringB: Color(0xFF546E7A),
        juicy: false,
        life: 1.05,
      ),
      AngryWordsPropMaterial.metal => const _AngryWordsPopProfile(
        count: 20,
        speedMin: 100,
        speedMax: 260,
        sizeMin: 2.4,
        sizeMax: 5.5,
        shapes: [AngryWordsBitShape.spark, AngryWordsBitShape.chip],
        ringA: Color(0xFFCFD8DC),
        ringB: Color(0xFF78909C),
        accent: Color(0xFFFFF176),
        juicy: false,
      ),
      AngryWordsPropMaterial.water => const _AngryWordsPopProfile(
        count: 24,
        speedMin: 80,
        speedMax: 220,
        sizeMin: 2.8,
        sizeMax: 6.8,
        shapes: [AngryWordsBitShape.drop, AngryWordsBitShape.round],
        ringA: Color(0xFFB3E5FC),
        ringB: Color(0xFF0288D1),
      ),
      AngryWordsPropMaterial.foam => const _AngryWordsPopProfile(
        count: 20,
        speedMin: 50,
        speedMax: 150,
        sizeMin: 4.0,
        sizeMax: 9.0,
        shapes: [AngryWordsBitShape.dust, AngryWordsBitShape.round],
        ringA: Color(0xFFFFFFFF),
        ringB: Color(0xFFECEFF1),
        life: 1.15,
      ),
      AngryWordsPropMaterial.slime => const _AngryWordsPopProfile(
        count: 22,
        speedMin: 60,
        speedMax: 190,
        sizeMin: 3.0,
        sizeMax: 7.2,
        shapes: [AngryWordsBitShape.drop, AngryWordsBitShape.chip],
        ringA: Color(0xFFB2FF59),
        ringB: Color(0xFF64DD17),
      ),
      AngryWordsPropMaterial.rubber => const _AngryWordsPopProfile(
        count: 20,
        speedMin: 110,
        speedMax: 270,
        sizeMin: 3.0,
        sizeMax: 6.8,
        shapes: [AngryWordsBitShape.chip, AngryWordsBitShape.round],
        ringA: Color(0xFFFFAB91),
        ringB: Color(0xFFE64A19),
      ),
      AngryWordsPropMaterial.sand => const _AngryWordsPopProfile(
        count: 26,
        speedMin: 70,
        speedMax: 210,
        sizeMin: 1.8,
        sizeMax: 4.5,
        shapes: [AngryWordsBitShape.dust, AngryWordsBitShape.round],
        ringA: Color(0xFFFFE0B2),
        ringB: Color(0xFFBF360C),
      ),
      AngryWordsPropMaterial.magma => const _AngryWordsPopProfile(
        count: 26,
        speedMin: 120,
        speedMax: 300,
        sizeMin: 2.5,
        sizeMax: 6.5,
        shapes: [
          AngryWordsBitShape.spark,
          AngryWordsBitShape.round,
          AngryWordsBitShape.glitter,
        ],
        ringA: Color(0xFFFF6D00),
        ringB: Color(0xFFBF360C),
        accent: Color(0xFFFFEA00),
      ),
      AngryWordsPropMaterial.gold => const _AngryWordsPopProfile(
        count: 30,
        speedMin: 110,
        speedMax: 280,
        sizeMin: 2.2,
        sizeMax: 5.5,
        shapes: [
          AngryWordsBitShape.glitter,
          AngryWordsBitShape.spark,
          AngryWordsBitShape.round,
        ],
        ringA: Color(0xFFFFF59D),
        ringB: Color(0xFFFF8F00),
        accent: Color(0xFFFFFFFF),
      ),
      AngryWordsPropMaterial.candy => const _AngryWordsPopProfile(
        count: 24,
        speedMin: 110,
        speedMax: 280,
        sizeMin: 3.0,
        sizeMax: 6.5,
        shapes: [
          AngryWordsBitShape.round,
          AngryWordsBitShape.glitter,
          AngryWordsBitShape.spark,
        ],
        ringA: Color(0xFFFFD54F),
        ringB: Color(0xFFFF7043),
      ),
      AngryWordsPropMaterial.plastic => const _AngryWordsPopProfile(
        count: 20,
        speedMin: 100,
        speedMax: 240,
        sizeMin: 2.6,
        sizeMax: 5.8,
        shapes: [AngryWordsBitShape.round, AngryWordsBitShape.chip],
        ringA: Color(0xFF80D8FF),
        ringB: Color(0xFF0288D1),
      ),
      AngryWordsPropMaterial.egg => const _AngryWordsPopProfile(
        count: 30,
        speedMin: 90,
        speedMax: 280,
        sizeMin: 2.4,
        sizeMax: 6.0,
        shapes: [AngryWordsBitShape.shard, AngryWordsBitShape.drop],
        ringA: Color(0xFFFFF8E1),
        ringB: Color(0xFFFFD54F),
        accent: Color(0xFFFFA000),
      ),
    };
  }

  void _scheduleReload() {
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (!_world.inFlight) {
        _world.resetToCannon();
        _awaitingReload = false;
        setState(() {});
      }
    });
  }

  Future<void> _clearWrongAfterFlash() async {
    // Let the scatter chaos play out before clearing the path flash.
    await Future<void>.delayed(const Duration(milliseconds: 780));
    if (!mounted) return;
    await ref
        .read(wordBuilderGameProvider(widget.bookKey).notifier)
        .clearWrongSelectionAfterFade();
    if (!mounted) return;
    _pathAnchors.clear();
    // Bring back any prefix balls that had been popped before the wrong hit.
    _world.revealAllLetters();
    _world.resetToCannon();
    // Peek: flash only the next expected letter (~400ms) — no full-word spoil.
    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    if (s != null) {
      final peek = ghostNextLetterForUnsolvedPrefix(
        s.level,
        s.solvedLower,
        '',
      );
      if (peek != null && peek.isNotEmpty) {
        _peekChar = peek.toLowerCase();
        _peekFlash = 1;
        setState(() {});
      }
    }
  }

  /// Soft next-letter halo while path is non-empty (off on advanced).
  String? _nextLetterHighlightFor(WordBuilderViewState s) {
    final camp = decodeWordBuilderCampaignSessionKey(widget.bookKey);
    if (camp?.difficulty == WordBuilderDifficulty.advanced) return null;
    if (s.path.isEmpty) return null;
    final built = s.path.map((e) => e.char).join();
    final next = ghostNextLetterForUnsolvedPrefix(
      s.level,
      s.solvedLower,
      built,
    );
    return next?.toLowerCase();
  }

  Future<void> _onCorrectWord({required bool perfect}) async {
    if (_celebrateBusy) return;
    _celebrateBusy = true;
    _successFlash = 1;
    _prefixFlash = 0;
    _attemptClean = true;
    _combo = perfect ? math.max(_combo, 2) : _combo;
    if (perfect) _comboLife = 1;
    if (!mounted) {
      _celebrateBusy = false;
      return;
    }
    final s = ref.read(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    final word = s?.lastSolvedWord;
    try {
      if (word != null && _pathAnchors.isNotEmpty) {
        await _flyPathLettersToSlots(word);
      }
      _pathAnchors.clear();
      if (!mounted) return;
      if (s?.levelComplete == true) {
        _pendingGradualRelayout = false;
        await _celebrateLevelComplete();
        return;
      }
      _gradualPropLayout = true;
      _pendingGradualRelayout = true;
      _forceFreshLetterLayout = true;
      _layoutSig = null;
      if (mounted) setState(() {});
    } finally {
      if (mounted) {
        ref.read(angryWordsSlotRevealProvider.notifier).state = null;
      }
      _celebrateBusy = false;
    }
  }

  /// Target for a hatching chick: path / typed-letter card (or board top fallback).
  Offset? _chickLandingGlobal({
    required WordBuilderViewState before,
    required int letterIndex,
    required Offset fallbackBoardPos,
  }) {
    final key = widget.pathCardKey;
    if (key != null) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final center = box.localToGlobal(box.size.center(Offset.zero));
        // Nudge toward where the new glyph will appear in the path text.
        final stagger = ((letterIndex - before.path.length / 2) * 11.0)
            .clamp(-48.0, 48.0);
        return center.translate(stagger, 0);
      }
    }
    final boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return null;
    return boardBox.localToGlobal(
      Offset(fallbackBoardPos.dx.clamp(24.0, _world.width - 24), 28),
    );
  }

  Future<void> _flySingleChick({
    required Offset boardStart,
    required String char,
    required int tintIndex,
    required Offset endGlobal,
  }) async {
    final boardBox = context.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return;

    _flights
      ..clear()
      ..add(
        AngryWordsFlightLetter(
          char: char,
          startGlobal: boardBox.localToGlobal(boardStart),
          endGlobal: endGlobal,
          tint: angryWordsLetterTint(tintIndex),
          delay: 0,
          asChick: true,
        ),
      );
    _flightCompleter = Completer<void>();
    _syncFlightOverlay();

    await _flightCompleter!.future.timeout(
      const Duration(milliseconds: 2400),
      onTimeout: () {},
    );
    if (!mounted) return;
    _flights.clear();
    _removeFlightOverlay();
  }

  Future<void> _flyPathLettersToSlots(WordBuilderTargetWord word) async {
    final bag = widget.slotKeyBag;
    final boardBox = context.findRenderObject() as RenderBox?;
    if (bag == null || boardBox == null || !boardBox.hasSize) {
      _pathAnchors.clear();
      return;
    }

    final norm = normalizeWord(word.word);
    ref.read(angryWordsSlotRevealProvider.notifier).state =
        AngryWordsSlotReveal(wordNorm: norm, revealedCount: 0);

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    var ends = bag.globalCentersFor(word.word);
    if (ends.isEmpty || ends.every((e) => e == null)) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      if (!mounted) return;
      ends = bag.globalCentersFor(word.word);
    }

    final anchors = List<_PathLetterAnchor>.of(_pathAnchors);
    _flights
      ..clear()
      ..addAll([
        for (var i = 0; i < anchors.length; i++)
          AngryWordsFlightLetter(
            char: anchors[i].char,
            startGlobal: boardBox.localToGlobal(anchors[i].boardPos),
            endGlobal: (i < ends.length ? ends[i] : null) ??
                boardBox.localToGlobal(
                  Offset(_world.width * 0.5, 24.0 + i * 8),
                ),
            tint: angryWordsLetterTint(anchors[i].tintIndex),
            delay: i * 0.085,
            asChick: true,
          ),
      ]);
    _pathAnchors.clear();
    _flightCompleter = Completer<void>();
    _syncFlightOverlay();

    await _flightCompleter!.future.timeout(
      const Duration(milliseconds: 4200),
      onTimeout: () {},
    );
    if (!mounted) return;
    _flights.clear();
    _removeFlightOverlay();
    ref.read(angryWordsSlotRevealProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(wordBuilderGameProvider(widget.bookKey)).valueOrNull;
    final hardBlocked = s?.trayVictorySequenceActive ?? false;
    final inputBlocked = hardBlocked ||
        (s?.pathWrongHighlight ?? false) ||
        _autoEvalBusy ||
        _celebrateBusy ||
        _flights.isNotEmpty;

    ref.listen(wordBuilderGameProvider(widget.bookKey), (prev, next) {
      final p = prev?.valueOrNull;
      final n = next.valueOrNull;
      if (p == null || n == null) return;

      final feedback = n.feedbackMessage;
      final accepted =
          feedback == '__correct' || feedback == '__correct_perfect';
      final wordJustSolved =
          p.path.isNotEmpty && n.path.isEmpty && accepted;

      final a = p.circleLetters;
      final b = n.circleLetters;
      if (!_sameLetterIds(a, b) && !wordJustSolved && !_celebrateBusy) {
        _forceFreshLetterLayout = true;
        _layoutSig = null;
        _world.resetToCannon();
      }

      if (wordJustSolved) {
        // Defer wall rebuild — next letter bag must not flash a full wall first.
        _pendingGradualRelayout = true;
        unawaited(_onCorrectWord(perfect: feedback == '__correct_perfect'));
        return;
      }

      if (p.path.isNotEmpty &&
          n.path.isEmpty &&
          !n.pathWrongHighlight &&
          !accepted) {
        _attemptClean = true;
        _combo = 0;
        _pathAnchors.clear();
        _world.revealAllLetters();
        _world.resetToCannon();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _boardSize = size;
        _ensureLayout(size);

        final motion = WbMotion.of(context);
        final punch = motion.allowShake ? _world.screenPunch : 0.0;
        final shake = punch > 0.01
            ? Offset(
                math.sin(_world.simTime * 70) *
                    punch *
                    WbMotion.maxShakePx,
                math.cos(_world.simTime * 55) *
                    punch *
                    (WbMotion.maxShakePx * 0.7),
              )
            : Offset.zero;

        return SizedBox.expand(
          child: Transform.translate(
            offset: shake,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: inputBlocked
                      ? null
                      : (d) {
                          final box =
                              context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local =
                              box.globalToLocal(d.globalPosition);
                          if (_world.usesHammer) {
                            _world.beginHammer(local);
                            appHapticSelection(ref);
                            return;
                          }
                          if (_world.usesGun) {
                            _world.setGunAim(local);
                            unawaited(_setGunTrigger(true));
                            _syncWindFromSources(hapticOnAimEnter: true);
                            return;
                          }
                          if (_world.inFlight) return;
                          if (_world.beginLetterDrag(local)) {
                            appHapticSelection(ref);
                            return;
                          }
                          _world.beginAim(local);
                          _syncWindFromSources(hapticOnAimEnter: true);
                          // Re-apply after wind flag so letter soft-lock yields same frame.
                          if (_world.aiming) _world.updateAim(local);
                        },
                  onPanUpdate: inputBlocked
                      ? null
                      : (d) {
                          final box =
                              context.findRenderObject() as RenderBox?;
                          if (box == null) return;
                          final local =
                              box.globalToLocal(d.globalPosition);
                          if (_world.usesHammer) {
                            _world.updateHammer(local);
                            return;
                          }
                          if (_world.usesGun) {
                            _world.setGunAim(local);
                            if (!_world.gunTriggerHeld) {
                              unawaited(_setGunTrigger(true));
                            }
                            _syncWindFromSources(hapticOnAimEnter: true);
                            return;
                          }
                          if (_world.isDraggingLetter) {
                            _world.updateLetterDrag(local);
                            return;
                          }
                          _world.updateAim(local);
                          _syncWindFromSources(hapticOnAimEnter: true);
                          if (_world.aiming) _world.updateAim(local);
                        },
                  onPanEnd: inputBlocked
                      ? null
                      : (_) {
                          if (_world.usesHammer) {
                            _world.endHammer();
                            appHapticMedium(ref);
                            return;
                          }
                          if (_world.usesGun) {
                            unawaited(_setGunTrigger(false));
                            _syncWindFromSources();
                            return;
                          }
                          if (_world.isDraggingLetter) {
                            final focused = _world.endLetterDrag();
                            appHapticLight(ref);
                            if (focused) {
                              appHapticSelection(ref);
                            }
                            return;
                          }
                          final launched = _world.releaseAim();
                          unawaited(ref.read(angryWordsSlingAudioProvider).stop());
                          final sfxOn = ref.read(wordBuilderGameSfxEnabledProvider);
                          if (launched) {
                            ref.read(angryWordsSlingSnapAudioProvider).play(enabled: sfxOn);
                            ref.read(angryWordsSlingWhooshAudioProvider).play(enabled: sfxOn);
                            appHapticMedium(ref);
                          }
                          _syncWindFromSources();
                        },
                  onPanCancel: () {
                    if (_world.usesHammer) {
                      _world.cancelHammer();
                    } else if (_world.usesGun) {
                      unawaited(_setGunTrigger(false));
                    } else if (_world.isDraggingLetter) {
                      _world.endLetterDrag();
                    } else {
                      _world.cancelAim();
                      unawaited(ref.read(angryWordsSlingAudioProvider).stop());
                    }
                    _lastSoftLockId = null;
                    _syncWindFromSources();
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _painter,
                    ),
                  ),
                ),
                if (_combo >= 2)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _paint,
                        builder: (context, _) => IgnorePointer(
                          child: WordBuilderComboChip(
                            combo: _combo,
                            life: _comboLife,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_world.phase == AngryWordsPhase.cage &&
                    _world.remainingCargoCount > 0)
                  Positioned(
                    top: _combo >= 2 ? 58 : 10,
                    right: 10,
                    child: RepaintBoundary(
                      child: ListenableBuilder(
                        listenable: _paint,
                        builder: (context, _) => IgnorePointer(
                          child: _AngryWordsHudChip(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.92,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.wordBuilderAngryWordsLettersLeft(
                                      _world.remainingCargoCount,
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
                if (_world.isFreePhase)
                  Positioned(
                    right: _windBtnRight,
                    bottom: _windBtnBottom,
                    child: _AngryWordsWindButton(
                      held: _world.windHeld,
                      intensity: _world.windBoost,
                      enabled: !hardBlocked,
                      tooltip: l10n.wordBuilderAngryWordsWindHint,
                      onHeldChanged: (held) {
                        _windButtonHeld = held;
                        _syncWindFromSources();
                        if (held) appHapticSelection(ref);
                        setState(() {});
                      },
                    ),
                  ),
                if (!inputBlocked &&
                    ((_world.usesHammer && !_world.hammerHeld) ||
                        (_world.usesGun && !_world.gunTriggerHeld) ||
                        (_world.isFreePhase &&
                            !_world.inFlight &&
                            !_world.aiming &&
                            !_world.isDraggingLetter)))
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: IgnorePointer(
                      child: Center(
                        child: _AngryWordsHudChip(
                          child: _angryWordsHintText(
                            scheme: scheme,
                            l10n: l10n,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_coachEnabled && _coachSteps.isNotEmpty)
                  Positioned.fill(
                    child: CoachOverlay(
                      key: const ValueKey('aw-main-coach'),
                      steps: _coachSteps,
                      onFinished: () => unawaited(_finishMainCoach()),
                    ),
                  ),
                if (_prefixCoachVisible)
                  Positioned.fill(
                    child: CoachOverlay(
                      key: const ValueKey('aw-prefix-coach'),
                      steps: [
                        CoachStep(
                          id: 'prefix',
                          message: l10n.wordBuilderCoachPrefixOrder,
                          targetRect: () {
                            final s = ref
                                .read(wordBuilderGameProvider(widget.bookKey))
                                .valueOrNull;
                            if (s == null) return null;
                            final next = ghostNextLetterForUnsolvedPrefix(
                              s.level,
                              s.solvedLower,
                              '',
                            );
                            return _expectedLetterSpotlightRect(
                              next?.toLowerCase(),
                            );
                          },
                          autoAdvanceAfter: const Duration(milliseconds: 2800),
                          allowSkip: true,
                          dimOpacity: 0.5,
                        ),
                      ],
                      onFinished: () => unawaited(_finishPrefixCoach()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _angryWordsHintText({
    required ColorScheme scheme,
    required AppLocalizations l10n,
  }) {
    final found = _world.revealedLetterCount;
    final total = found + _world.remainingCargoCount;
    final baseStyle = TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.88),
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
    );
    if (_world.usesHammer) {
      return Text(
        '${l10n.wordBuilderAngryWordsHammerHint} · $found / $total',
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    if (_world.usesGun) {
      final label = _world.loadout.label;
      if (_world.loadout.gun == AngryWordsGunKind.doomsdayMg ||
          (_world.loadout.gun == AngryWordsGunKind.tankCannon &&
              _world.loadout.pelletCount >= 2)) {
        return Text(
          l10n.wordBuilderAngryWordsHoldSprayHint(label),
          textAlign: TextAlign.center,
          style: baseStyle,
        );
      }
      if (_world.remainingCargoCount == 0 && _world.revealedLetterCount > 0) {
        return Text(
          l10n.wordBuilderAngryWordsClearWallHint(label),
          textAlign: TextAlign.center,
          style: baseStyle,
        );
      }
      return Text(
        l10n.wordBuilderAngryWordsBlastOrbsHint(label, found, total),
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    if (_world.phase == AngryWordsPhase.freeing) {
      return Text(
        l10n.wordBuilderAngryWordsLettersUnlocked,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    return Text(
      l10n.wordBuilderAngryWordsAimHint,
      textAlign: TextAlign.center,
      style: baseStyle,
    );
  }
}

class _AngryWordsHudChip extends StatelessWidget {
  const _AngryWordsHudChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: isDark ? 0.42 : 0.55,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AngryWordsPopProfile {
  const _AngryWordsPopProfile({
    required this.count,
    required this.speedMin,
    required this.speedMax,
    required this.sizeMin,
    required this.sizeMax,
    required this.shapes,
    required this.ringA,
    required this.ringB,
    this.accent,
    this.juicy = true,
    this.life = 1,
  });

  final int count;
  final double speedMin;
  final double speedMax;
  final double sizeMin;
  final double sizeMax;
  final List<AngryWordsBitShape> shapes;
  final Color ringA;
  final Color ringB;
  final Color? accent;
  final bool juicy;
  final double life;
}

class _AngryWordsWindButton extends StatelessWidget {
  const _AngryWordsWindButton({
    required this.held,
    required this.intensity,
    required this.enabled,
    required this.tooltip,
    required this.onHeldChanged,
  });

  final bool held;
  final double intensity;
  final bool enabled;
  final String tooltip;
  final ValueChanged<bool> onHeldChanged;

  @override
  Widget build(BuildContext context) {
    final active = held || intensity > 0.08;
    return Tooltip(
      message: tooltip,
      child: Listener(
        onPointerDown: enabled ? (_) => onHeldChanged(true) : null,
        onPointerUp: enabled ? (_) => onHeldChanged(false) : null,
        onPointerCancel: enabled ? (_) => onHeldChanged(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? const [Color(0xFF81D4FA), Color(0xFF0288D1)]
                  : const [Color(0xFFE1F5FE), Color(0xFF90CAF9)],
            ),
            border: Border.all(
              color: active ? const Color(0xFF01579B) : Colors.white70,
              width: active ? 2.4 : 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0288D1)
                    .withValues(alpha: 0.25 + intensity * 0.35),
                blurRadius: 8 + intensity * 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.air_rounded,
            color: active ? Colors.white : const Color(0xFF01579B),
            size: 26 + intensity * 4,
          ),
        ),
      ),
    );
  }
}

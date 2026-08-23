import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/audio/angry_words_can_shoot_audio.dart';
import '../../../../../core/audio/angry_words_lamp_shot_audio.dart';
import '../../../../../core/audio/angry_words_egg_crack_audio.dart';
import '../../../../../core/audio/angry_words_explosion_audio.dart';
import '../../../../../core/audio/angry_words_gun_audio.dart';
import '../../../../../core/audio/angry_words_pop_audio.dart';
import '../../../../../core/audio/angry_words_prop_break_audio.dart';
import '../../../../../core/audio/angry_words_sling_audio.dart';
import '../../../../../core/audio/word_builder_sound_service.dart';
import '../../../data/prop_archetypes/wb_prop_archetype.dart';
import '../../../data/prop_archetypes/wb_prop_sound_family.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../application/word_builder_game_notifier.dart';
import '../../../application/word_builder_session_audio.dart';
import '../../../domain/word_builder_game_logic.dart';
import '../../../domain/word_builder_models.dart';
import '../answer_slot_key_bag.dart';
import '../../theme/word_builder_motion.dart';
import '../../../application/word_builder_play_mode_controller.dart';
import 'angry_words_celebrate.dart';
import 'angry_words_flight_overlay.dart';
import 'angry_words_loadout.dart';
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
  });

  final int bookKey;
  final List<LetterInstance> letters;
  final AnswerSlotKeyBag? slotKeyBag;

  @override
  ConsumerState<AngryWordsLetterBoard> createState() =>
      _AngryWordsLetterBoardState();
}

class _AngryWordsLetterBoardState extends ConsumerState<AngryWordsLetterBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _world = AngryWordsPhysicsWorld(width: 1, height: 1);
  Duration _lastElapsed = Duration.zero;
  final List<Offset> _trail = [];
  double _sparkLife = 0;
  double _wrongFlash = 0;
  double _successFlash = 0;
  double _prefixFlash = 0;
  bool _wasWrong = false;
  bool _autoEvalBusy = false;
  bool _attemptClean = true;
  int _combo = 0;
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
      HapticFeedback.selectionClick();
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
    _ticker = createTicker(_onTick)..start();
    unawaited(_loadPropSprites());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(wordBuilderGameProvider(widget.bookKey).notifier)
            .preparePhysicsLetterMode(),
      );
      // Preload cage + free-phase SFX once — never reload per shot/pop/pull.
      unawaited(ref.read(angryWordsGunAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsPopAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsSlingAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsEggCrackAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsCanShootAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsLampShotAudioProvider).ensureLoaded());
      unawaited(ref.read(angryWordsExplosionAudioProvider).ensureLoaded());
    });
  }

  Future<void> _loadPropSprites() async {
    try {
      final results = await Future.wait([
        _decodeAssetImage('assets/items/can.png'),
        _decodeAssetImage('assets/items/canshoot.png'),
        _decodeAssetImage('assets/items/gun4.png'),
        _decodeAssetImage('assets/items/oilbarrel.png'),
        _decodeAssetImage('assets/items/oilbarrelshot.png'),
        _decodeAssetImage('assets/items/lamp.png'),
        _decodeAssetImage('assets/items/lampshot.png'),
        _decodeAssetImage('assets/items/lampleftshot.png'),
        _decodeAssetImage('assets/items/lamprightshot.png'),
      ]);
      if (!mounted) {
        for (final img in results) {
          img?.dispose();
        }
        return;
      }
      _world.sodaCanSprite?.dispose();
      _world.sodaCanShotSprite?.dispose();
      _world.stage4GunSprite?.dispose();
      _world.oilBarrelSprite?.dispose();
      _world.oilBarrelShotSprite?.dispose();
      _world.lampSprite?.dispose();
      _world.lampShotSprite?.dispose();
      _world.lampLeftFragmentSprite?.dispose();
      _world.lampRightFragmentSprite?.dispose();
      _world.sodaCanSprite = results[0];
      _world.sodaCanShotSprite = results[1];
      _world.stage4GunSprite = results[2];
      _world.oilBarrelSprite = results[3];
      _world.oilBarrelShotSprite = results[4];
      _world.lampSprite = results[5];
      _world.lampShotSprite = results[6];
      _world.lampLeftFragmentSprite = results[7];
      _world.lampRightFragmentSprite = results[8];
      setState(() {});
    } catch (_) {
      // Fallback paint in painter until assets are available.
    }
  }

  Future<ui.Image?> _decodeAssetImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _removeFlightOverlay();
    _windButtonHeld = false;
    _world.setWindHeld(false);
    _world.setGunTrigger(false);
    _world.sodaCanSprite?.dispose();
    _world.sodaCanSprite = null;
    _world.sodaCanShotSprite?.dispose();
    _world.sodaCanShotSprite = null;
    _world.stage4GunSprite?.dispose();
    _world.stage4GunSprite = null;
    _world.oilBarrelSprite?.dispose();
    _world.oilBarrelSprite = null;
    _world.oilBarrelShotSprite?.dispose();
    _world.oilBarrelShotSprite = null;
    _world.lampSprite?.dispose();
    _world.lampSprite = null;
    _world.lampShotSprite?.dispose();
    _world.lampShotSprite = null;
    _world.lampLeftFragmentSprite?.dispose();
    _world.lampLeftFragmentSprite = null;
    _world.lampRightFragmentSprite?.dispose();
    _world.lampRightFragmentSprite = null;
    unawaited(ref.read(angryWordsGunAudioProvider).stop());
    unawaited(ref.read(angryWordsSlingAudioProvider).stopStretch());
    _ticker.dispose();
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
        f.t = (f.t + dt / 0.68).clamp(0.0, 1.0);
        allDone = false;
      }
      if (f.t >= 1 && !f.settled) {
        f.settled = true;
        anySettled = true;
        revealed = math.max(revealed, i + 1);
        HapticFeedback.selectionClick();
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
      HapticFeedback.lightImpact();
      unawaited(_clearWrongAfterFlash());
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
    if (_sparkLife > 0) {
      _sparkLife = (_sparkLife - dt * 3.2).clamp(0.0, 1.0);
    }
    for (final e in _explosions) {
      final decay = e.material == AngryWordsPropMaterial.foam ||
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
          HapticFeedback.selectionClick();
        }
        _world.shotsFiredThisFrame = 0;
      }
      _syncWindFromSources(hapticOnAimEnter: true);
      _syncSlingStretchAudio();
      final softLock = _world.softLockLetterId;
      if (_world.aiming &&
          softLock != null &&
          softLock != _lastSoftLockId) {
        HapticFeedback.selectionClick();
      }
      _lastSoftLockId = _world.aiming ? softLock : null;
      final propPops = _world.takePropPops();
      // Always allow pop.WAV (own player + rate limit) — single or spray.
      for (final pop in propPops) {
        _spawnPropExplosion(pop, playSound: true);
      }
      final canHits = _world.takeCanShootSfx();
      if (canHits > 0) {
        final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
        final canAudio = ref.read(angryWordsCanShootAudioProvider);
        for (var i = 0; i < canHits; i++) {
          canAudio.play(enabled: sfx);
        }
      }
      final lampHits = _world.takeLampShotSfx();
      if (lampHits > 0) {
        final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
        final lampAudio = ref.read(angryWordsLampShotAudioProvider);
        for (var i = 0; i < lampHits; i++) {
          lampAudio.play(enabled: sfx);
        }
      }
      for (final at in _world.takeOilFireFx()) {
        _spawnOilBarrelFireBurst(at);
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
      if (_trail.length > 10) _trail.removeAt(0);
      _awaitingReload = true;
    } else if (!_world.aiming) {
      _trail.clear();
    }

    if (_world.cageCombo >= 2) {
      _combo = math.max(_combo, _world.cageCombo);
    }

    if (mounted) setState(() {});
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

    if (correctForActive) {
      var tint = 0;
      var eggR = 16.0;
      for (final L in _world.letters) {
        if (L.letter.id == hit.id) {
          tint = L.tintIndex;
          eggR = L.radius;
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
      // Stage 22-style: primary holdsCargoWell + porcelain → jug shatter (no yolk).
      final primarySpec = kWbArchetypes[_world.loadout.primaryArchetype];
      final porcelainShell = primarySpec != null &&
          primarySpec.holdsCargoWell &&
          primarySpec.material == AngryWordsPropMaterial.porcelain;
      final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
      if (porcelainShell) {
        _spawnPropExplosion(
          AngryWordsPropPop(
            at: hitPos,
            palette: tint,
            radius: eggR,
            material: AngryWordsPropMaterial.porcelain,
            archetype: _world.loadout.primaryArchetype,
          ),
        );
      } else {
        // Found letter-egg cracks: shell burst + yolk spills to the floor pool.
        _world.spillYolkAt(hitPos, fromRadius: eggR, seed: hit.id);
        _spawnEggLetterBreak(hitPos);
        ref.read(angryWordsEggCrackAudioProvider).play(enabled: sfx);
      }
      _sparkLife = 1;
      HapticFeedback.mediumImpact();
    } else {
      _pathAnchors.clear();
      _world.scatterFromWrongHit(hit.id);
      HapticFeedback.heavyImpact();
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
      }
      if (after?.feedbackMessage == '__correct' ||
          after?.feedbackMessage == '__correct_perfect') {
        _combo += 1;
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
        HapticFeedback.mediumImpact();
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
      HapticFeedback.heavyImpact();
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
    final motionScale =
        mounted ? WbMotion.of(context).particleScale : 1.0;
    final bitBudget = math.max(
      2,
      (profile.count * motionScale).round().clamp(2, 16),
    );
    final life = (profile.life * (0.55 + 0.45 * motionScale)).clamp(
      0.35,
      WbShatterRecipe.kMaxPlayableLifetimeSec,
    );
    final bits = <AngryWordsExplosionBit>[];
    if (pop.material == AngryWordsPropMaterial.egg) {
      // Shell shards only — yolk becomes a live floor puddle.
      const shell = Color(0xFFFFF8E1);
      const shellDark = Color(0xFFE8D5B5);
      final eggN = math.max(4, (12 * motionScale).round());
      for (var i = 0; i < eggN; i++) {
        final a = i * math.pi * 2 / eggN + rng.nextDouble() * 0.4;
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
      for (var i = 0; i < bitBudget; i++) {
        final a = i * math.pi * 2 / bitBudget + rng.nextDouble() * 0.55;
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
    if (pop.steamy) {
      final steamN = math.max(2, (6 * motionScale).round());
      for (var i = 0; i < steamN; i++) {
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
    final oilFire = pop.archetype == WbPropArchetype.oilDrum;
    if (oilFire) {
      // Bigger boom on final rupture.
      _appendOilFireBits(bits, rng, motionScale, big: true);
    }
    _explosions.add(
      AngryWordsLetterExplosion(
        at: pop.at,
        char: '',
        life: oilFire
            ? (0.75 + 0.25 * motionScale).clamp(0.55, 1.05)
            : life,
        bits: bits,
        juicy: profile.juicy || oilFire,
        steamy: pop.steamy,
        fiery: oilFire,
        ringA: oilFire ? const Color(0xFFFFAB40) : profile.ringA,
        ringB: oilFire ? const Color(0xFFFF3D00) : profile.ringB,
        material: pop.material,
      ),
    );
    _sparkLife = 1;
    HapticFeedback.mediumImpact();
    if (playSound) {
      final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
      if (pop.material == AngryWordsPropMaterial.egg) {
        // Keep dedicated eggshell sample for letter/wall eggs.
        ref.read(angryWordsEggCrackAudioProvider).play(enabled: sfx);
      } else if (pop.archetype == WbPropArchetype.sodaCan) {
        ref.read(angryWordsCanShootAudioProvider).play(enabled: sfx);
      } else if (pop.archetype == WbPropArchetype.oilDrum) {
        // Final rupture: boom + fire already in juice.
        ref.read(angryWordsExplosionAudioProvider).play(enabled: sfx);
      } else if (pop.archetype == WbPropArchetype.oilLamp) {
        // Same random glass-break sample as a non-lethal hit.
        ref.read(angryWordsLampShotAudioProvider).play(enabled: sfx);
      } else {
        final arch = pop.archetype;
        final spec = arch != null ? kWbArchetypes[arch] : null;
        final family =
            spec?.soundFamily ?? wbSoundFamilyForMaterial(pop.material);
        final pitch = spec?.soundPitch ?? family.defaultPitch;
        ref.read(angryWordsPropBreakAudioProvider).play(
              family: family,
              basePitch: pitch,
              enabled: sfx,
              applyJitter: true,
              priority: 0,
            );
      }
    }
  }

  void _spawnOilBarrelFireBurst(Offset at) {
    final motionScale = mounted ? WbMotion.of(context).particleScale : 1.0;
    final rng = math.Random(at.dx.round() ^ at.dy.round() ^ DateTime.now().microsecond);
    final bits = <AngryWordsExplosionBit>[];
    _appendOilFireBits(bits, rng, motionScale);
    _explosions.add(
      AngryWordsLetterExplosion(
        at: at,
        char: '',
        life: (0.55 + 0.2 * motionScale).clamp(0.4, 0.85),
        bits: bits,
        juicy: true,
        fiery: true,
        ringA: const Color(0xFFFFAB40),
        ringB: const Color(0xFFFF3D00),
        material: AngryWordsPropMaterial.magma,
      ),
    );
    while (_explosions.length > 28) {
      _explosions.removeAt(0);
    }
  }

  void _appendOilFireBits(
    List<AngryWordsExplosionBit> bits,
    math.Random rng,
    double motionScale, {
    bool big = false,
  }) {
    const colors = <Color>[
      Color(0xFFFFF176),
      Color(0xFFFFAB40),
      Color(0xFFFF6D00),
      Color(0xFFFF3D00),
      Color(0xFFBF360C),
    ];
    final scale = big ? 1.55 : 1.0;
    final n = math.max(8, ((big ? 22 : 14) * motionScale).round());
    for (var i = 0; i < n; i++) {
      // Bias upward (flames rise); big boom sprays wider.
      final a = -math.pi * 0.5 + (rng.nextDouble() - 0.5) * (big ? 2.6 : 1.8);
      bits.add(
        AngryWordsExplosionBit(
          angle: a,
          speed: (70 + rng.nextDouble() * 160) * scale,
          size: (2.8 + rng.nextDouble() * 5.5) * scale,
          color: colors[i % colors.length],
          shape: i.isEven ? AngryWordsBitShape.spark : AngryWordsBitShape.round,
        ),
      );
    }
    final smokeN = math.max(2, (((big ? 8 : 4) * motionScale).round()));
    for (var i = 0; i < smokeN; i++) {
      bits.add(
        AngryWordsExplosionBit(
          angle: -math.pi * 0.5 + (rng.nextDouble() - 0.5) * 1.4,
          speed: (30 + rng.nextDouble() * 55) * scale,
          size: (5 + rng.nextDouble() * 7) * scale,
          color: const Color(0xFF78909C),
          shape: AngryWordsBitShape.dust,
        ),
      );
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
        count: 28,
        speedMin: 130,
        speedMax: 300,
        sizeMin: 2.0,
        sizeMax: 5.2,
        shapes: [AngryWordsBitShape.shard, AngryWordsBitShape.dust],
        ringA: Color(0xFFFAFAFA),
        ringB: Color(0xFFBDBDBD),
        accent: Color(0xFFEEEEEE),
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
  }

  Future<void> _onCorrectWord({required bool perfect}) async {
    if (_celebrateBusy) return;
    _celebrateBusy = true;
    _successFlash = 1;
    _prefixFlash = 0;
    _attemptClean = true;
    _combo = perfect ? math.max(_combo, 2) : _combo;
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
          ),
      ]);
    _pathAnchors.clear();
    _flightCompleter = Completer<void>();
    _syncFlightOverlay();

    await _flightCompleter!.future.timeout(
      const Duration(milliseconds: 2400),
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
    final selectedIds = s?.path.map((e) => e.id).toSet() ?? {};
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
        final punch =
            motion.allowScreenShake ? _world.screenPunch : 0.0;
        final shake = punch > 0.01
            ? Offset(
                math.sin(_world.simTime * 70) * punch * 5,
                math.cos(_world.simTime * 55) * punch * 3.5,
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
                            HapticFeedback.selectionClick();
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
                            HapticFeedback.selectionClick();
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
                            HapticFeedback.mediumImpact();
                            return;
                          }
                          if (_world.usesGun) {
                            unawaited(_setGunTrigger(false));
                            _syncWindFromSources();
                            return;
                          }
                          if (_world.isDraggingLetter) {
                            final focused = _world.endLetterDrag();
                            HapticFeedback.lightImpact();
                            if (focused) {
                              HapticFeedback.selectionClick();
                            }
                            return;
                          }
                          final power = _world.powerNorm;
                          final launched = _world.releaseAim();
                          final sfx = ref.read(wordBuilderGameSfxEnabledProvider);
                          unawaited(
                            ref.read(angryWordsSlingAudioProvider).onRelease(
                                  enabled: sfx,
                                  powerNorm: power,
                                  launched: launched,
                                ),
                          );
                          _syncWindFromSources();
                          if (launched) {
                            HapticFeedback.mediumImpact();
                          }
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
                      unawaited(ref.read(angryWordsSlingAudioProvider).stopStretch());
                    }
                    _lastSoftLockId = null;
                    _syncWindFromSources();
                  },
                  child: CustomPaint(
                    size: size,
                    painter: AngryWordsBoardPainter(
                      world: _world,
                      selectedIds: selectedIds,
                      wrongFlash: _wrongFlash,
                      successFlash: _successFlash,
                      prefixFlash: _prefixFlash,
                      combo: _combo,
                      trail: List.of(_trail),
                      sparkLife: _sparkLife,
                      explosions: List.of(_explosions),
                      isDark: isDark,
                      scheme: scheme,
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
                        if (held) HapticFeedback.selectionClick();
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
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: IgnorePointer(
                      child: Text(
                        _world.usesHammer
                            ? 'Drag to smash bottles · ${_world.loadout.wallHint} · ${_world.revealedLetterCount} / ${_world.revealedLetterCount + _world.remainingCargoCount}'
                            : _world.usesGun
                            ? (_world.loadout.gun ==
                                        AngryWordsGunKind.doomsdayMg ||
                                    (_world.loadout.gun ==
                                            AngryWordsGunKind.tankCannon &&
                                        _world.loadout.pelletCount >= 2)
                                ? 'Hold & spray · ${_world.loadout.label} · ${_world.loadout.chapterTag} · ${_world.loadout.wallHint}'
                                : _world.remainingCargoCount == 0 &&
                                        _world.revealedLetterCount > 0
                                ? 'Clear the wall · ${_world.loadout.label} · ${_world.loadout.wallHint}'
                                : 'Blast letter orbs · ${_world.loadout.label} · ${_world.revealedLetterCount} / ${_world.revealedLetterCount + _world.remainingCargoCount} · ${_world.loadout.wallHint}')
                            : _world.phase == AngryWordsPhase.freeing
                            ? 'Letters unlocked!'
                            : l10n.wordBuilderAngryWordsAimHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

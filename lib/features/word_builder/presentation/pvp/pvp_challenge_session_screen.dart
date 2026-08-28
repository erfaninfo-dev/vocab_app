import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/language/language_provider.dart';
import '../../../../domain/api_providers.dart';
import '../../application/pvp_challenge_providers.dart';
import '../../application/pvp_challenge_session_notifier.dart';
import '../../domain/pvp_scoring.dart';
import '../widgets/magic_background.dart';
import 'pvp_challenge_letter_tray.dart';
import 'pvp_challenge_ui.dart';

class PvpChallengeSessionScreen extends ConsumerStatefulWidget {
  const PvpChallengeSessionScreen({super.key, required this.matchId});

  final int matchId;

  @override
  ConsumerState<PvpChallengeSessionScreen> createState() =>
      _PvpChallengeSessionScreenState();
}

class _PvpChallengeSessionScreenState
    extends ConsumerState<PvpChallengeSessionScreen> {
  bool _started = false;
  bool _submitting = false;
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(pvpChallengeDetailProvider(widget.matchId));
    final play = ref.watch(pvpChallengeSessionProvider);
    final notifier = ref.read(pvpChallengeSessionProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Challenge', style: GoogleFonts.fredoka(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MagicBackground(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          matchAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (match) {
            if (!match.viewer.canPlay) {
              return Center(
                child: Text(
                  'Not your turn or match not ready.',
                  style: GoogleFonts.fredoka(fontSize: 16),
                ),
              );
            }
            if (!_bootstrapped && play.circleLetters.isEmpty) {
              _bootstrapped = true;
              _bootstrap(match);
            }
            if (!_started) {
              return _intro(match, () {
                setState(() => _started = true);
                notifier.start();
              });
            }
            if (play.finished && !_submitting) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _submit(match, play);
              });
            }
            return _playView(match, play, notifier);
          },
        ),
        ],
      ),
    );
  }

  void _bootstrap(dynamic match) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categories = await ref.read(apiGameWordCategoriesProvider.future);
      final dict = pvpDictionaryForCategoryId(match.category.id, categories);
      ref.read(pvpChallengeSessionProvider.notifier).init(
            letters: match.letters,
            dictionary: dict,
            durationSec: match.durationSec,
          );
    });
  }

  Future<void> _submit(dynamic match, PvpChallengePlayState play) async {
    setState(() => _submitting = true);
    final started = play.startedAt ?? DateTime.now().toUtc();
    final completed = DateTime.now().toUtc();
    try {
      await ref.read(pvpChallengeActionsProvider).submit(
            matchId: widget.matchId,
            startedAt: started,
            completedAt: completed,
            words: play.submittedWords,
          );
      if (!mounted) return;
      context.go('/word-builder/challenge/${widget.matchId}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submit failed: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _submit(match, play),
          ),
        ),
      );
    }
  }

  Widget _intro(dynamic match, VoidCallback onStart) {
    final lang = ref.watch(langProvider);
    final preferKur = lang == TranslationLang.kur;
    final topic = match.category.label(preferKur: preferKur);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pvpCategoryIcon(match.category.icon), size: 64, color: kPvpGold),
            const SizedBox(height: 16),
            Text(topic, style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              '${match.durationSec} seconds — find as many words as you can!',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Each letter = 1 point',
              style: GoogleFonts.fredoka(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: kPvpGold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Start', style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playView(
    dynamic match,
    PvpChallengePlayState play,
    PvpChallengeSessionNotifier notifier,
  ) {
    final built = play.path.map((e) => e.char.toUpperCase()).join();
    final timerColor = play.secondsLeft <= 10 ? kPvpCrimson : kPvpGold;

    if (_submitting) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: kToolbarHeight + 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pill('Time', '${play.secondsLeft}s', timerColor),
            _pill('Score', '${play.liveScore}', Colors.green.shade700),
          ],
        ),
        if (built.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              built,
              style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: PvpChallengeLetterTray(
              letters: play.circleLetters,
              path: play.path,
              pathWrong: play.pathWrong,
              enabled: play.running && !play.finished,
              onLetter: notifier.appendLetter,
              onRelease: notifier.evaluatePathOnRelease,
              onClearPath: notifier.clearPath,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final w in play.foundWords)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      '$w (+${pvpScoreForWord(w)})',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.fredoka(fontSize: 12)),
          Text(value, style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

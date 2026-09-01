import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/language/language_provider.dart';
import '../../application/pvp_challenge_providers.dart';
import '../../application/word_builder_play_mode_controller.dart';
import '../../domain/word_builder_play_mode.dart';
import '../../pvp_challenge_session_key.dart';
import '../word_builder_session_screen.dart';
import '../widgets/magic_background.dart';

class PvpChallengeSessionScreen extends ConsumerStatefulWidget {
  const PvpChallengeSessionScreen({super.key, required this.matchId});

  final int matchId;

  @override
  ConsumerState<PvpChallengeSessionScreen> createState() =>
      _PvpChallengeSessionScreenState();
}

class _PvpChallengeSessionScreenState
    extends ConsumerState<PvpChallengeSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(wordBuilderPlayModeProvider.notifier)
          .setMode(WordBuilderPlayMode.classic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(pvpChallengeDetailProvider(widget.matchId));
    final lang = ref.watch(langProvider);
    final preferKur = lang == TranslationLang.kur;

    return matchAsync.when(
      loading: () => Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MagicBackground(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e', style: GoogleFonts.fredoka())),
      ),
      data: (match) {
        if (!match.viewer.canPlay) {
          return Scaffold(
            body: Center(
              child: Text(
                'Not your turn or match not ready.',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          );
        }
        final topic = match.category.label(preferKur: preferKur);
        final bookKey = encodePvpChallengeSessionKey(widget.matchId);
        return WordBuilderSessionScreen(
          bookKey: bookKey,
          pvpMatchId: widget.matchId,
          pvpTopicLabel: topic,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/profile/profile_avatar.dart';
import '../../../../data/models/pvp_challenge.dart';
import '../../application/pvp_challenge_providers.dart';
import '../widgets/magic_background.dart';
import 'pvp_challenge_ui.dart';

class PvpChallengeDetailScreen extends ConsumerWidget {
  const PvpChallengeDetailScreen({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(pvpChallengeDetailProvider(matchId));
    final session = ref.watch(authProvider).valueOrNull;
    final myId = session?.user.id;

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
          data: (match) => _body(context, ref, match, myId),
        ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    PvpMatch match,
    int? myId,
  ) {
    final lang = ref.watch(langProvider);
    final preferKur = lang == TranslationLang.kur;
    final topic = match.category.label(preferKur: preferKur);
    final other = myId == match.challenger?.userId
        ? match.opponent
        : match.challenger;
    final me = match.playerFor(myId ?? -1);
    PvpMatchPlayer? otherPlayer;
    for (final p in match.players) {
      if (p.userId != (myId ?? -1)) {
        otherPlayer = p;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pvpChallengeDetailProvider(matchId));
        await ref.read(pvpChallengeDetailProvider(matchId).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 16, 20, 24),
        children: [
          _headerCard(match, other, topic),
          const SizedBox(height: 16),
          if (match.status == PvpMatchStatus.pending && match.viewer.canAccept)
            _pendingActions(context, ref, match),
          if (match.status == PvpMatchStatus.accepted && match.viewer.canPlay)
            _playButton(context, ref, match),
          if (match.status == PvpMatchStatus.accepted &&
              !match.viewer.canPlay &&
              me?.playerStatus != PvpPlayerStatus.submitted)
            _waitingCard(),
          if (me?.playerStatus == PvpPlayerStatus.submitted &&
              match.status != PvpMatchStatus.completed)
            _savedCard(me!.score ?? 0),
          if (match.status == PvpMatchStatus.completed)
            _resultCard(context, match, myId, me, otherPlayer),
          if (match.letters.isNotEmpty && match.status != PvpMatchStatus.pending)
            _lettersPreview(match.letters),
        ],
      ),
    );
  }

  Widget _headerCard(PvpMatch match, PvpUserBrief? other, String topic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: pvpChallengeGradient(Brightness.light),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPvpGold.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          if (other != null) ...[
            ProfileAvatar(avatarId: other.avatar, userId: other.userId, size: 72),
            const SizedBox(height: 8),
            Text(other.displayName, style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(pvpCategoryIcon(match.category.icon), color: kPvpGold),
              const SizedBox(width: 8),
              Text(topic, style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Classic tray — find 3 words from this topic',
            style: GoogleFonts.fredoka(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _statusLabel(match.status),
            style: GoogleFonts.fredoka(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _pendingActions(BuildContext context, WidgetRef ref, PvpMatch match) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              await ref.read(pvpChallengeActionsProvider).decline(match.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Challenge declined')),
                );
              }
            },
            child: const Text('No'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPvpGold, foregroundColor: Colors.black87),
            onPressed: () async {
              final accepted =
                  await ref.read(pvpChallengeActionsProvider).accept(match.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Challenge accepted!')),
              );
              if (accepted.viewer.canPlay) {
                context.push('/word-builder/challenge/${match.id}/play');
              }
            },
            child: const Text('Yes'),
          ),
        ),
      ],
    );
  }

  Widget _playButton(BuildContext context, WidgetRef ref, PvpMatch match) {
    final lang = ref.watch(langProvider);
    final preferKur = lang == TranslationLang.kur;
    final topic = match.category.label(preferKur: preferKur);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(pvpCategoryIcon(match.category.icon), color: kPvpGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Topic: $topic',
                    style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kPvpCrimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => context.push('/word-builder/challenge/$matchId/play'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Play Now', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _waitingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Waiting for your opponent to play…',
          style: GoogleFonts.fredoka(fontSize: 16),
        ),
      ),
    );
  }

  Widget _savedCard(int score) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Your score ($score) is saved. Waiting for opponent.',
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _resultCard(
    BuildContext context,
    PvpMatch match,
    int? myId,
    PvpMatchPlayer? me,
    PvpMatchPlayer? other,
  ) {
    final myScore = me?.score ?? 0;
    final otherScore = other?.score ?? 0;
    String headline;
    Color color;
    if (match.isDraw) {
      headline = 'Draw!';
      color = Colors.blueGrey;
    } else if (match.winnerId == myId) {
      headline = 'You Win!';
      color = Colors.green.shade700;
    } else {
      headline = 'Nice try!';
      color = Colors.orange.shade800;
    }

    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(headline, style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 12),
            Text('You: $myScore', style: GoogleFonts.fredoka(fontSize: 18)),
            Text('Opponent: $otherScore', style: GoogleFonts.fredoka(fontSize: 18)),
            if (me?.words != null && me!.words!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Your words: ${me.words!.join(', ')}', style: GoogleFonts.fredoka(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lettersPreview(List<String> letters) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shared letters', style: GoogleFonts.fredoka(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final l in letters)
                  Chip(label: Text(l.toUpperCase(), style: GoogleFonts.fredoka(fontWeight: FontWeight.w700))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(PvpMatchStatus status) {
    return switch (status) {
      PvpMatchStatus.pending => 'Waiting for acceptance',
      PvpMatchStatus.accepted => 'In progress',
      PvpMatchStatus.completed => 'Completed',
      PvpMatchStatus.declined => 'Declined',
      PvpMatchStatus.expired => 'Expired',
      PvpMatchStatus.cancelled => 'Cancelled',
    };
  }
}

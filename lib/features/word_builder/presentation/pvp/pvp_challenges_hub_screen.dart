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

class PvpChallengesHubScreen extends ConsumerWidget {
  const PvpChallengesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final bucketsAsync = ref.watch(pvpChallengesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Challenges', style: GoogleFonts.fredoka(fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MagicBackground(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          session == null
            ? _guest(context)
            : bucketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _errorState(context, ref, e),
                data: (b) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pvpChallengesProvider);
                    await ref.read(pvpChallengesProvider.future);
                  },
                  child: _list(context, ref, b),
                ),
              ),
        ],
      ),
    );
  }

  Widget _guest(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sign in to challenge friends', style: GoogleFonts.fredoka(fontSize: 18)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => context.push('/login'), child: const Text('Sign in')),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
    final message = error.toString();
  final hint = message.contains('HTTP 500') || message.contains('helpers.php')
        ? 'Upload pvp_challenge_helpers.php and pvp_challenge_submit.php to the server, then run pvp_challenge_schema.sql on MySQL.'
        : message.contains('503') || message.contains('schema.sql')
        ? 'Run api/pvp_challenge_schema.sql on your MySQL database.'
        : 'Check your connection and try again.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: kPvpCrimson.withValues(alpha: 0.85)),
            const SizedBox(height: 16),
            Text(
              'Could not load challenges',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => ref.invalidate(pvpChallengesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, PvpMatchListBuckets b) {
    final sections = <({String title, List<PvpMatchSummaryCard> items, Color accent})>[
      (title: 'Needs your action', items: [...b.incomingPending, ...b.myTurn], accent: kPvpCrimson),
      (title: 'Waiting', items: b.waitingOpponent, accent: Colors.orange),
      (title: 'Recent results', items: b.completedRecent, accent: Colors.green.shade700),
    ];

    final total = sections.fold<int>(0, (n, s) => n + s.items.length);
    if (total == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.sports_martial_arts_rounded, size: 64, color: kPvpGold.withValues(alpha: 0.8)),
                  const SizedBox(height: 12),
                  Text(
                    'No challenges yet',
                    style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open someone\'s profile from League and tap Challenge.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 12, 16, 24),
      children: [
        for (final section in sections)
          if (section.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                section.title,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: section.accent,
                ),
              ),
            ),
            for (final card in section.items)
              _ChallengeCard(card: card),
          ],
      ],
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.card});

  final PvpMatchSummaryCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final topic = card.category.label(preferKur: lang == TranslationLang.kur);
    final other = card.otherUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/word-builder/challenge/${card.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (other != null)
                ProfileAvatar(avatarId: other.avatar, userId: other.userId, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other?.displayName ?? 'Challenge',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(topic, style: GoogleFonts.fredoka(color: Colors.black54, fontSize: 13)),
                    Text(
                      _status(card),
                      style: GoogleFonts.fredoka(fontSize: 12, color: kPvpGold),
                    ),
                  ],
                ),
              ),
              if (card.isMyTurn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPvpCrimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('GO', style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: kPvpCrimson)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _status(PvpMatchSummaryCard card) {
    if (card.status == PvpMatchStatus.pending) return 'Pending acceptance';
    if (card.isMyTurn) return 'Your turn';
    if (card.status == PvpMatchStatus.completed) {
      if (card.isDraw) return 'Draw';
      return 'Finished';
    }
    return 'Waiting';
  }
}

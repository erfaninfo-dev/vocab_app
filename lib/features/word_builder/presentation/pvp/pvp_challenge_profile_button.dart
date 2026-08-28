import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../data/models/pvp_challenge.dart';
import '../../application/pvp_challenge_providers.dart';
import 'pvp_challenge_ui.dart';

class PvpChallengeProfileButton extends ConsumerWidget {
  const PvpChallengeProfileButton({
    super.key,
    required this.opponentUserId,
    required this.opponentName,
  });

  final int opponentUserId;
  final String opponentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    if (session == null) {
      return FilledButton.icon(
        onPressed: () => context.push('/login'),
        icon: const Icon(Icons.login_rounded),
        label: const Text('Sign in to Challenge'),
      );
    }
    if (session.user.id == opponentUserId) {
      return const SizedBox.shrink();
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: kPvpCrimson,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: () => _confirmChallenge(context, ref),
      icon: const Icon(Icons.sports_martial_arts_rounded),
      label: Text(
        'Challenge',
        style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Future<void> _confirmChallenge(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Challenge $opponentName?', style: GoogleFonts.fredoka()),
        content: const Text(
          'Topic: Random\nTime: 60 seconds each\n\nYour opponent can play whenever they are ready.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Challenge')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final match = await ref
          .read(pvpChallengeActionsProvider)
          .createChallenge(opponentUserId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge sent to $opponentName!')),
      );
      context.push('/word-builder/challenge/${match.id}');
    } on PvpActiveMatchException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have an active challenge with this player.')),
      );
      if (e.matchId > 0) {
        context.push('/word-builder/challenge/${e.matchId}');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

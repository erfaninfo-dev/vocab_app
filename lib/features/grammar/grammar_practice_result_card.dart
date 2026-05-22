import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/profile/profile_avatar.dart';
import '../../data/models/grammar_result.dart';
import '../../l10n/app_localizations.dart';

enum GrammarLeaderboardMedal { gold, silver, bronze }

/// Personal vs community styling for grammar result rows.
enum GrammarPracticeResultCardStyle {
  /// Logged-in user or teacher viewing a student: chips + time + privacy + ring.
  personal,

  /// Community tab: user header + chips + time (no privacy pill) + ring.
  community,
}

class GrammarPracticeResultCard extends StatelessWidget {
  const GrammarPracticeResultCard({
    super.key,
    required this.r,
    required this.style,
    this.rank,
    this.leaderboardMedal,
    this.practiceTotalsLabel,
  });

  final GrammarResult r;
  final GrammarPracticeResultCardStyle style;
  final int? rank;
  final GrammarLeaderboardMedal? leaderboardMedal;
  final String? practiceTotalsLabel;

  /// Topic labels: JSON [selectedGrammarsRaw] or `quizName` split by ` + `.
  static List<String> topicLabelsForResult(GrammarResult r) {
    final raw = r.selectedGrammarsRaw;
    final s = (raw ?? '').trim();
    if (s.isNotEmpty) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .take(16)
              .toList();
        }
      } catch (_) {
        return [s];
      }
    }
    final q = r.quizName.trim();
    if (q.isEmpty) return const [];
    final parts = q
        .split(RegExp(r'\s*\+\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(16)
        .toList();
    if (parts.isNotEmpty) {
      return parts;
    }
    return [q];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final chips = topicLabelsForResult(r);
    final isPublic = r.public == 1;
    final displayName = (r.userName ?? '').trim().isEmpty
        ? l10n.guestUser
        : r.userName!.trim();

    final int? score = r.score;
    final int? total = r.totalQuestions;
    final hasScore = score != null && total != null && total > 0;
    final double ratio;
    if (score != null && total != null && total > 0) {
      ratio = score / total;
    } else {
      ratio = 0.0;
    }

    final showCommunityHeader = style == GrammarPracticeResultCardStyle.community;
    final showPrivacyPill = style == GrammarPracticeResultCardStyle.personal;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              scheme.surface.withValues(alpha: 0.98),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              if (showCommunityHeader && rank != null) ...[
                _CommunityRankBadge(
                  rank: rank!,
                  medal: leaderboardMedal,
                  scheme: scheme,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showCommunityHeader)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _UserAvatar(
                            scheme: scheme,
                            avatarId: r.avatar,
                            userId: r.userId,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (practiceTotalsLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    practiceTotalsLabel!,
                                    style: tt.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (showCommunityHeader && chips.isNotEmpty)
                      const SizedBox(height: 8),
                    if (chips.isNotEmpty)
                      _GrammarTopicChipsWrap(
                        labels: chips,
                        scheme: scheme,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatCreatedAtRaw(r.createdAt),
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (showPrivacyPill)
                          _PrivacyPill(isPublic: isPublic, scheme: scheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ScoreRing(
                score: score,
                total: total,
                ratio: ratio,
                hasScore: hasScore,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatGrammarDisplayDateTime(DateTime dt) {
  if (dt.millisecondsSinceEpoch == 0) return '—';
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y/$m/$d · $h:$min';
}

String _formatCreatedAtRaw(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '—';
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized);
  if (dt == null) return raw;
  return _formatGrammarDisplayDateTime(dt);
}

class _GrammarTopicChipsWrap extends StatelessWidget {
  const _GrammarTopicChipsWrap({
    required this.labels,
    required this.scheme,
  });

  final List<String> labels;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTag = (constraints.maxWidth * 0.48).clamp(72.0, 148.0);

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.start,
          children: [
            for (final c in labels)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c,
                    style: tt.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CommunityRankBadge extends StatelessWidget {
  const _CommunityRankBadge({
    required this.rank,
    required this.scheme,
    this.medal,
  });

  final int rank;
  final ColorScheme scheme;
  final GrammarLeaderboardMedal? medal;

  Color? _medalColor() {
    switch (medal) {
      case GrammarLeaderboardMedal.gold:
        return const Color(0xFFC9A227);
      case GrammarLeaderboardMedal.silver:
        return const Color(0xFF90A4AE);
      case GrammarLeaderboardMedal.bronze:
        return const Color(0xFFB87333);
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mc = _medalColor();
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (medal != null)
            Icon(
              Icons.emoji_events_rounded,
              size: 22,
              color: mc ?? scheme.primary,
            ),
          Text(
            '$rank',
            textAlign: TextAlign.center,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.scheme,
    this.avatarId,
    this.userId,
  });

  final ColorScheme scheme;
  final String? avatarId;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    final id = (avatarId ?? '').trim();
    if (id.isNotEmpty) {
      return ProfileAvatar(
        avatarId: id,
        userId: userId,
        size: 40,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.85),
      foregroundColor: scheme.onPrimaryContainer,
      child: Icon(
        Icons.person_rounded,
        color: scheme.primary,
        size: 22,
      ),
    );
  }
}

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill({
    required this.isPublic,
    required this.scheme,
  });

  final bool isPublic;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublic
            ? scheme.secondaryContainer.withValues(alpha: 0.75)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: isPublic
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? l10n.resultVisibilityPublic : l10n.resultVisibilityPrivate,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPublic
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.total,
    required this.ratio,
    required this.hasScore,
    required this.scheme,
  });

  final int? score;
  final int? total;
  final double ratio;
  final bool hasScore;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pct = hasScore ? (ratio * 100).round() : null;
    final ratioLabel = hasScore ? '$score/$total' : '';
    final totalQ = total;
    final compact = hasScore &&
        (ratioLabel.length > 5 || (totalQ != null && totalQ >= 100));

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: hasScore ? ratio.clamp(0.0, 1.0) : null,
              strokeWidth: 4,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.9,
              ),
              color: scheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasScore) ...[
                    Text(
                      ratioLabel,
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontSize: compact ? 9.5 : null,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: tt.labelSmall?.copyWith(
                        fontSize: compact ? 8.5 : 10,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else
                    Text(
                      '—',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

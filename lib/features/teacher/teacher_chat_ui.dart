import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Shared visuals for teacher inbox + chat (Telegram-inspired, matches app theme).
class TeacherChatUi {
  TeacherChatUi._();

  static BoxDecoration screenBackground(ColorScheme scheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.primary.withValues(alpha: 0.09),
          scheme.surfaceContainerLowest,
          scheme.surface,
        ],
      ),
    );
  }

  /// Today → time; yesterday → label; last 7 days → weekday; older → date.
  static String formatListTimestamp({
    required DateTime messageLocal,
    required DateTime nowLocal,
    required AppLocalizations l10n,
    required String localeName,
  }) {
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final d = DateTime(messageLocal.year, messageLocal.month, messageLocal.day);
    final diffDays = today.difference(d).inDays;
    if (diffDays == 0) {
      return DateFormat.jm(localeName).format(messageLocal);
    }
    if (diffDays == 1) {
      return l10n.chatListYesterday;
    }
    if (diffDays < 7) {
      return DateFormat.E(localeName).format(messageLocal);
    }
    return DateFormat.yMMMd(localeName).format(messageLocal);
  }

  static DateTime? tryParseApiDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized)?.toLocal();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Shared visuals for teacher inbox + chat (Telegram-inspired, matches app theme).
class TeacherChatUi {
  TeacherChatUi._();

  /// Soft gradient for teacher student list (progress panel).
  static BoxDecoration teacherPanelBackground(ColorScheme scheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: 0.14),
          scheme.secondary.withValues(alpha: 0.08),
          scheme.tertiary.withValues(alpha: 0.05),
          scheme.surface,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ),
    );
  }

  /// Chat thread screen (inside conversation).
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

  /// Full-screen decorative layer for the **inbox list** — whisper-light outline icons only.
  static Widget inboxListBackgroundDecor(ColorScheme scheme) {
    // One very low-contrast ink so every watermark matches the “faint envelope” look.
    final ink = scheme.onSurface.withValues(alpha: 0.034);

    Widget faintIcon(IconData data, double size) {
      return Icon(data, size: size, color: ink);
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(scheme.surface, scheme.secondaryContainer, 0.12)!,
                  scheme.surface,
                  Color.lerp(scheme.surface, scheme.primaryContainer, 0.08)!,
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 52,
            right: 12,
            child: faintIcon(Icons.mark_email_unread_outlined, 78),
          ),
          Positioned(
            top: 168,
            left: 8,
            child: faintIcon(Icons.chat_bubble_outline_rounded, 70),
          ),
          Positioned(
            top: 300,
            right: 20,
            child: faintIcon(Icons.mail_outline_rounded, 64),
          ),
          Positioned(
            bottom: 140,
            left: 16,
            child: faintIcon(Icons.send_outlined, 56),
          ),
          Positioned(
            bottom: 240,
            right: 12,
            child: faintIcon(Icons.forum_outlined, 68),
          ),
          Positioned(
            top: 380,
            left: 28,
            child: Transform.rotate(
              angle: -0.1,
              child: faintIcon(Icons.mail_outline_rounded, 52),
            ),
          ),
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

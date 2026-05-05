import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/datetime/class_session_recorded_at.dart';
import '../../data/models/teacher_student.dart';
import '../../l10n/app_localizations.dart';

/// Teacher: [+] and numbered squares with check + date. Student: same without [+].
class ClassSessionsStrip extends StatelessWidget {
  const ClassSessionsStrip({
    super.key,
    required this.sessions,
    this.readOnly = false,
    this.onAdd,
    this.isAdding = false,
  });

  final List<ClassSessionEntry> sessions;
  final bool readOnly;

  /// When [readOnly] is false, called when user taps +.
  final VoidCallback? onAdd;

  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final loc = Localizations.localeOf(context).toString();

    Widget addButton() {
      return Material(
        color: scheme.primaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: (readOnly || isAdding || onAdd == null) ? null : onAdd,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 32,
            height: 32,
            child: isAdding
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: scheme.primary,
                    ),
                  )
                : Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
          ),
        ),
      );
    }

    String formatSessionDate(String raw) {
      final dt = parseClassSessionRecordedAtFromApi(raw);
      if (dt == null) return raw.trim().isEmpty ? '—' : raw;
      return DateFormat.yMMMd(loc).add_Hm().format(dt);
    }

    final chips = <Widget>[];
    if (!readOnly) {
      chips.add(
        Tooltip(
          message: l10n.teacherClassSessionAddTooltip,
          child: addButton(),
        ),
      );
    }

    for (var i = 0; i < sessions.length; i++) {
      final e = sessions[i];
      final n = e.index > 0 ? e.index : i + 1;
      chips.add(
        _SessionCell(
          index: n,
          dateLabel: formatSessionDate(e.recordedAtRaw),
          scheme: scheme,
          tt: tt,
        ),
      );
    }

    if (chips.isEmpty && readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.youClassSessionsEmpty,
          style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }
}

class _SessionCell extends StatelessWidget {
  const _SessionCell({
    required this.index,
    required this.dateLabel,
    required this.scheme,
    required this.tt,
  });

  final int index;
  final String dateLabel;
  final ColorScheme scheme;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.4),
              width: 1,
            ),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$index',
                style: tt.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.check_circle_rounded,
                size: 11,
                color: scheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 92),
          child: Text(
            dateLabel,
            style: tt.labelSmall?.copyWith(
              fontSize: 9,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

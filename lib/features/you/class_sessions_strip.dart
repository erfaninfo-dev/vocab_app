import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: (readOnly || isAdding || onAdd == null) ? null : onAdd,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 56,
            child: isAdding
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  )
                : Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: scheme.onPrimaryContainer,
                  ),
          ),
        ),
      );
    }

    String formatSessionDate(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return '—';
      final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
      final dt = DateTime.tryParse(normalized);
      if (dt == null) return raw;
      return DateFormat.yMMMd(loc).add_Hm().format(dt.toLocal());
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
        spacing: 10,
        runSpacing: 12,
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$index',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            dateLabel,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

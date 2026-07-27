import 'package:flutter/material.dart';

import '../../../core/widgets/app_jelly_style.dart';
import '../../../data/models/section_info.dart';
import '../../../l10n/app_localizations.dart';

/// Single-unit quiz with no sections: compact unit label so scope is clear.
class BookQuizLockedUnitCard extends StatelessWidget {
  const BookQuizLockedUnitCard({
    super.key,
    required this.l10nEn,
    required this.unit,
  });

  final AppLocalizations l10nEn;
  final int unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppJellyCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: InputChip(
            label: Text(
              l10nEn.unitLabel(unit),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                  ),
            ),
            selected: true,
            showCheckmark: true,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

class BookQuizSectionsPanel extends StatelessWidget {
  const BookQuizSectionsPanel({
    super.key,
    required this.l10n,
    required this.l10nEn,
    required this.sectionsByUnit,
    required this.selectedSectionsByUnit,
    required this.onSectionToggle,
    required this.onSelectAllForUnit,
    required this.onClearUnit,
  });

  final AppLocalizations l10n;
  final AppLocalizations l10nEn;
  final Map<int, List<SectionInfo>> sectionsByUnit;
  final Map<int, Set<int>> selectedSectionsByUnit;
  final void Function(int unit, int section, bool selected) onSectionToggle;
  final void Function(int unit) onSelectAllForUnit;
  final void Function(int unit) onClearUnit;

  @override
  Widget build(BuildContext context) {
    if (sectionsByUnit.isEmpty) return const SizedBox.shrink();

    final units = sectionsByUnit.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < units.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _UnitSectionsCard(
            l10n: l10n,
            l10nEn: l10nEn,
            unit: units[i],
            sections: sectionsByUnit[units[i]]!,
            selected: selectedSectionsByUnit[units[i]] ?? const {},
            onToggle: onSectionToggle,
            onSelectAll: () => onSelectAllForUnit(units[i]),
            onClear: () => onClearUnit(units[i]),
          ),
        ],
      ],
    );
  }
}

class _UnitSectionsCard extends StatelessWidget {
  const _UnitSectionsCard({
    required this.l10n,
    required this.l10nEn,
    required this.unit,
    required this.sections,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClear,
  });

  final AppLocalizations l10n;
  final AppLocalizations l10nEn;
  final int unit;
  final List<SectionInfo> sections;
  final Set<int> selected;
  final void Function(int unit, int section, bool selected) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  String _sectionLabel(SectionInfo info) {
    final d = info.sectionDetails?.trim();
    if (d != null && d.isNotEmpty) {
      return d;
    }
    return l10n.sectionNumberLabel(info.section);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = sections.every((s) => selected.contains(s.section));
    final noneSelected = selected.isEmpty;

    return AppJellyCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.view_module_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10nEn.unitLabel(unit),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: allSelected ? null : onSelectAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.bookQuizSectionsSelectAll),
              ),
              TextButton(
                onPressed: noneSelected ? null : onClear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.bookQuizSectionsClear),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final info in sections)
                  FilterChip(
                    label: Text(
                      _sectionLabel(info),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    selected: selected.contains(info.section),
                    onSelected: (v) => onToggle(unit, info.section, v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

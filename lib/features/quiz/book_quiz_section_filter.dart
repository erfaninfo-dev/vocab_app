import '../../data/models/section_info.dart';
import '../../data/models/vocab_entry.dart';

/// Merges API sections with distinct `section` values from [allWords].
Map<int, List<SectionInfo>> buildQuizSectionsCatalog({
  required Map<int, List<SectionInfo>> apiSections,
  required List<VocabEntry> allWords,
  required Set<int> selectedUnits,
}) {
  final out = <int, List<SectionInfo>>{
    for (final e in apiSections.entries)
      if (e.value.isNotEmpty) e.key: List<SectionInfo>.from(e.value),
  };

  for (final unit in selectedUnits) {
    if (out.containsKey(unit) && out[unit]!.isNotEmpty) continue;
    final nums = <int>{};
    for (final e in allWords) {
      if (e.unit != unit) continue;
      final s = e.section;
      if (s == null || s <= 0) continue;
      nums.add(s);
    }
    if (nums.isEmpty) continue;
    final sorted = nums.toList()..sort();
    out[unit] = [for (final n in sorted) SectionInfo(section: n)];
  }
  return out;
}

List<int> sortedUnitList(Set<int> units) {
  final list = units.toList()..sort();
  return list;
}

/// True when [allWords] already contains section numbers for any [selectedUnits].
bool selectedUnitsMayHaveSections(
  List<VocabEntry> allWords,
  Set<int> selectedUnits,
) {
  for (final e in allWords) {
    if (!selectedUnits.contains(e.unit)) continue;
    final s = e.section;
    if (s != null && s > 0) return true;
  }
  return false;
}

/// Query segments `unit:section`, e.g. `3:1,3:4,5:2`.
Map<int, Set<int>> parseBookQuizSectionsQuery(String csv) {
  final out = <int, Set<int>>{};
  if (csv.trim().isEmpty) return out;
  for (final part in csv.split(',')) {
    final p = part.trim();
    if (p.isEmpty) continue;
    final sep = p.indexOf(':');
    if (sep <= 0) continue;
    final unit = int.tryParse(p.substring(0, sep).trim());
    final section = int.tryParse(p.substring(sep + 1).trim());
    if (unit == null || section == null) continue;
    out.putIfAbsent(unit, () => <int>{}).add(section);
  }
  return out;
}

String encodeBookQuizSectionsQuery(Map<int, Set<int>> byUnit) {
  final parts = <String>[];
  final units = byUnit.keys.toList()..sort();
  for (final unit in units) {
    final secs = byUnit[unit]!.toList()..sort();
    for (final s in secs) {
      parts.add('$unit:$s');
    }
  }
  return parts.join(',');
}

bool vocabEntryMatchesBookQuizScope({
  required VocabEntry entry,
  required Set<int> selectedUnits,
  required Map<int, List<int>> unitsWithSections,
  required Map<int, Set<int>> selectedSectionsByUnit,
}) {
  if (!selectedUnits.contains(entry.unit)) return false;
  final sectionNums = unitsWithSections[entry.unit];
  if (sectionNums == null || sectionNums.isEmpty) return true;
  final picked = selectedSectionsByUnit[entry.unit];
  if (picked == null || picked.isEmpty) return false;
  final s = entry.section;
  if (s == null) return false;
  return picked.contains(s);
}

/// Omits units where every section is still selected (shorter quiz URLs).
Map<int, Set<int>> compactSectionSelectionForQuery({
  required Map<int, List<int>> unitsWithSections,
  required Map<int, Set<int>> selectedSectionsByUnit,
  required Set<int> selectedUnits,
}) {
  final out = <int, Set<int>>{};
  for (final unit in selectedUnits) {
    final all = unitsWithSections[unit];
    if (all == null || all.isEmpty) continue;
    final allSet = all.toSet();
    final picked = selectedSectionsByUnit[unit] ?? allSet;
    if (picked.length >= allSet.length && picked.containsAll(allSet)) {
      continue;
    }
    if (picked.isNotEmpty) {
      out[unit] = Set<int>.from(picked);
    }
  }
  return out;
}

class UnitInfo {
  const UnitInfo({
    required this.unit,
    this.unitDetails,
  });

  final int unit;
  final String? unitDetails;

  factory UnitInfo.fromJson(Map<String, dynamic> json) {
    return UnitInfo(
      unit: (json['unit'] as num).toInt(),
      unitDetails: json['unit_details']?.toString(),
    );
  }

  bool matchesQuery(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final details = unitDetails?.trim().toLowerCase() ?? '';
    if (details.contains(query)) return true;

    if (RegExp(r'^\d+$').hasMatch(query) && unit.toString() == query) {
      return true;
    }

    return false;
  }
}

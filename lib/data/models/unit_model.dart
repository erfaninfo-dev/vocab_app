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
}

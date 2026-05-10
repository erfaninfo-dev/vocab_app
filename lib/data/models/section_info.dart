class SectionInfo {
  const SectionInfo({required this.section, this.sectionDetails});

  final int section;

  /// Title from `words.section_details` when set on any row in this section.
  final String? sectionDetails;

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    final details = json['section_details']?.toString().trim();
    return SectionInfo(
      section: (json['section'] as num).toInt(),
      sectionDetails: (details == null || details.isEmpty) ? null : details,
    );
  }
}

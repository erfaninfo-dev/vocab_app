class BookAsset {
  const BookAsset({required this.assetPath});

  final String assetPath;

  /// Last segment of the path (e.g. "Ielts Essential words.xlsx")
  String get filename => assetPath.split('/').last;

  /// Human-readable title derived from the filename.
  String get title {
    final fname = filename;
    final dotIndex = fname.lastIndexOf('.');
    final nameWithoutExt =
        dotIndex == -1 ? fname : fname.substring(0, dotIndex);
    return formatTitle(nameWithoutExt);
  }

  bool get isExcel =>
      assetPath.endsWith('.xlsx') || assetPath.endsWith('.xls');

  /// Converts a raw filename (without extension) to a display title.
  /// e.g. "ielts essential words" → "IELTS Essential Words"
  static String formatTitle(String raw) {
    final normalized = raw
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return 'Untitled Book';

    const acronyms = {'ielts', 'toefl', 'gre', 'gmat', 'sat'};

    return normalized.split(' ').map((word) {
      final lower = word.toLowerCase();
      if (acronyms.contains(lower)) return lower.toUpperCase();
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

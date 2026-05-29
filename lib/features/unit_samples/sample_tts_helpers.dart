import 'dart:math' as math;

/// Layout of concatenated English paragraphs for full-sample TTS playback.
class SampleEnglishLayout {
  const SampleEnglishLayout({
    required this.fullText,
    required this.paragraphStarts,
  });

  final String fullText;
  final List<int> paragraphStarts;

  factory SampleEnglishLayout.fromParagraphTexts(List<String> paragraphEns) {
    final starts = <int>[];
    final buffer = StringBuffer();
    var wrote = false;
    for (final raw in paragraphEns) {
      final en = raw.trim();
      starts.add(buffer.length);
      if (en.isEmpty) continue;
      if (wrote) buffer.write('\n\n');
      buffer.write(en);
      wrote = true;
    }
    return SampleEnglishLayout(
      fullText: buffer.toString(),
      paragraphStarts: starts,
    );
  }

  /// Maps a global character index in [fullText] to a local index inside [paragraphEn].
  static (int localStart, int localEnd) karaokeRangeForParagraph({
    required String paragraphEn,
    required int paragraphGlobalStart,
    required int globalStart,
    required int globalEnd,
    required bool karaoke,
    required bool lingering,
  }) {
    final len = paragraphEn.length;
    if (len == 0) return (0, 0);

    if (lingering) {
      return (0, len);
    }
    if (!karaoke) {
      return (0, 0);
    }

    final paraEnd = paragraphGlobalStart + len;
    final gStart = globalStart.clamp(paragraphGlobalStart, paraEnd);
    final gEnd = globalEnd.clamp(paragraphGlobalStart, paraEnd);
    var a = (gStart - paragraphGlobalStart).clamp(0, len);
    var b = (gEnd - paragraphGlobalStart).clamp(0, len);
    if (b < a) b = a;
    if (b <= a && a < len) {
      b = (a + 1).clamp(0, len);
    }
    return (a, b);
  }

  static String previewTitle(String title, String fullText) {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    final plain = fullText.trim();
    if (plain.isEmpty) return '';
    final line = plain.split(RegExp(r'\n+')).first.trim();
    if (line.length <= 56) return line;
    return '${line.substring(0, 53)}…';
  }

  static double progressFraction(int current, int total) {
    if (total <= 0) return 0;
    return (current / total).clamp(0.0, 1.0);
  }

  static int seekIndexFromFraction(double fraction, int total) {
    return (total * fraction.clamp(0.0, 1.0)).round().clamp(0, math.max(0, total));
  }
}

class SampleTtsSession {
  const SampleTtsSession({
    required this.sampleId,
    required this.title,
    required this.paragraphIndex,
    required this.paragraphEnglishText,
  });

  final int sampleId;
  final String title;
  final int paragraphIndex;

  /// English text for the paragraph currently loaded in the player.
  final String paragraphEnglishText;

  @Deprecated('Use paragraphEnglishText')
  String get fullEnglishText => paragraphEnglishText;
}

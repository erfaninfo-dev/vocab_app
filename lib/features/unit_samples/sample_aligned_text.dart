class SampleAlignedPair {
  const SampleAlignedPair(this.en, this.local);
  final String en;
  final String local;
}

final RegExp _bidiControls = RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]');

String _cleanSampleLine(String line) =>
    line.trim().replaceAll(_bidiControls, '').trim();

/// Matches CMS headers: `English:`, `فارسی:`, `کوردی:`, RTL `:کوردی`, etc.
final RegExp _englishSectionLabelLine = RegExp(
  r'^(?:'
  r'(?:english|en)\s*:+\s*'
  r'|:\s*(?:english|en)\s*'
  r')',
  unicode: true,
  caseSensitive: false,
);

final RegExp _localSectionLabelLine = RegExp(
  r'^(?:'
  r'(?:fa|kurdish(?:\s+sorani)?|kur|فارسی|(?:کردی|كوردي|کوردی|كوردی)(?:\s*(?:\(\s*سورانی\s*\)|سورانی))?)\s*:+\s*'
  r'|:\s*(?:fa|kurdish(?:\s+sorani)?|kur|فارسی|(?:کردی|كوردي|کوردی|كوردی)(?:\s*(?:\(\s*سورانی\s*\)|سورانی))?)\s*'
  r')',
  unicode: true,
  caseSensitive: false,
);

bool _isEnglishSectionLabel(String line) =>
    _englishSectionLabelLine.hasMatch(_cleanSampleLine(line));

bool _isLocalSectionLabel(String line) =>
    _localSectionLabelLine.hasMatch(_cleanSampleLine(line));

String _stripLeadingSectionLabel(String raw) {
  final cleaned = _cleanSampleLine(raw);
  if (cleaned.isEmpty) return '';

  if (_englishSectionLabelLine.hasMatch(cleaned)) {
    return cleaned.replaceFirst(_englishSectionLabelLine, '');
  }
  if (_localSectionLabelLine.hasMatch(cleaned)) {
    return cleaned.replaceFirst(_localSectionLabelLine, '');
  }
  return cleaned;
}

List<String> _splitSampleParagraphs(String text) {
  final t = text.trim();
  if (t.isEmpty) return const [];
  return t
      .split(RegExp(r'\n\s*\n+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

List<SampleAlignedPair> _zipSampleParagraphPairs(
  String enBlock,
  String localBlock,
) {
  final enParts = _splitSampleParagraphs(enBlock);
  final localParts = _splitSampleParagraphs(localBlock);
  final maxLen = enParts.length > localParts.length
      ? enParts.length
      : localParts.length;
  if (maxLen == 0) return const [];
  return List.generate(maxLen, (i) {
    final en = i < enParts.length ? enParts[i] : '';
    final local = i < localParts.length ? localParts[i] : '';
    return SampleAlignedPair(en, local);
  });
}

/// When EN/local paragraph counts match, zip 1:1; otherwise keep one bilingual
/// block (avoids EN-only + local-only book pages from CMS misalignment).
List<SampleAlignedPair> pairsFromAlignedBlocks(String enBlock, String localBlock) {
  final en = enBlock.trim();
  final local = localBlock.trim();
  if (en.isEmpty && local.isEmpty) return const [];

  final enParts = _splitSampleParagraphs(en);
  final localParts = _splitSampleParagraphs(local);
  if (enParts.isNotEmpty &&
      localParts.isNotEmpty &&
      enParts.length == localParts.length) {
    final zipped = _zipSampleParagraphPairs(en, local);
    final hasOrphanSide = zipped.any(
      (p) => p.en.trim().isEmpty || p.local.trim().isEmpty,
    );
    if (!hasOrphanSide) return zipped;
  }
  return [SampleAlignedPair(en, local)];
}

/// Book mode safety net: consecutive EN-only rows then local-only rows → one page.
List<SampleAlignedPair> mergeOrphanBookPairs(List<SampleAlignedPair> pairs) {
  if (pairs.length < 2) return pairs;

  final out = <SampleAlignedPair>[];
  var i = 0;
  while (i < pairs.length) {
    final en = pairs[i].en.trim();
    final local = pairs[i].local.trim();

    if (en.isNotEmpty && local.isEmpty) {
      final enParts = <String>[];
      while (i < pairs.length) {
        final blockEn = pairs[i].en.trim();
        final blockLocal = pairs[i].local.trim();
        if (blockEn.isEmpty || blockLocal.isNotEmpty) break;
        enParts.add(blockEn);
        i++;
      }

      final localParts = <String>[];
      while (i < pairs.length) {
        final blockEn = pairs[i].en.trim();
        final blockLocal = pairs[i].local.trim();
        if (blockEn.isNotEmpty || blockLocal.isEmpty) break;
        localParts.add(blockLocal);
        i++;
      }

      if (localParts.isNotEmpty) {
        out.add(
          SampleAlignedPair(
            enParts.join('\n\n'),
            localParts.join('\n\n'),
          ),
        );
        continue;
      }

      for (final part in enParts) {
        out.add(SampleAlignedPair(part, ''));
      }
      continue;
    }

    out.add(pairs[i]);
    i++;
  }
  return out;
}

String _stripSampleHeadingPrefix(String input) {
  final raw = _cleanSampleLine(input);
  if (raw.isEmpty) return '';
  return _stripLeadingSectionLabel(raw).trim();
}

List<SampleAlignedPair> parseSampleAlignedPairs(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];

  final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).toList();

  final hasAnyLabels = lines.any(_isEnglishSectionLabel) ||
      lines.any(_isLocalSectionLabel);
  if (hasAnyLabels) {
    final out = <SampleAlignedPair>[];

    final enBuf = StringBuffer();
    final localBuf = StringBuffer();
    String mode = '';

    void flushPair() {
      final en = _stripSampleHeadingPrefix(enBuf.toString().trim());
      final local = _stripSampleHeadingPrefix(localBuf.toString().trim());
      enBuf.clear();
      localBuf.clear();
      if (en.isEmpty && local.isEmpty) return;

      final zipped = pairsFromAlignedBlocks(en, local);
      out.addAll(zipped);
    }

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (_isEnglishSectionLabel(line)) {
        if (mode == 'local') {
          flushPair();
        }
        mode = 'en';
        final rest = _stripLeadingSectionLabel(line);
        if (rest.isNotEmpty) {
          enBuf.writeln(rest);
        }
        continue;
      }

      if (_isLocalSectionLabel(line)) {
        if (mode == 'local') {
          if (localBuf.isNotEmpty) {
            flushPair();
          }
        } else if (mode.isNotEmpty && mode != 'en') {
          flushPair();
        }
        mode = 'local';
        final rest = _stripLeadingSectionLabel(line);
        if (rest.isNotEmpty) {
          localBuf.writeln(rest);
        }
        continue;
      }

      if (mode == 'en') {
        enBuf.writeln(line);
        continue;
      }
      if (mode == 'local') {
        localBuf.writeln(line);
        continue;
      }

      final rtlCount = RegExp(r'[\u0600-\u06FF]').allMatches(line).length;
      if (rtlCount > (line.length / 6)) {
        localBuf.writeln(line);
      } else {
        enBuf.writeln(line);
      }
    }

    flushPair();
    return out;
  }

  final sepIndex = lines.indexWhere(
    (l) => l == '---' || l == '—' || l == '–––' || l == '———',
  );
  if (sepIndex >= 0) {
    final en = _stripSampleHeadingPrefix(lines.take(sepIndex).join('\n').trim());
    final local = _stripSampleHeadingPrefix(
      lines.skip(sepIndex + 1).join('\n').trim(),
    );
    if (en.isNotEmpty || local.isNotEmpty) {
      final pairs = pairsFromAlignedBlocks(en, local);
      if (pairs.isNotEmpty) return pairs;
      return [SampleAlignedPair(en, local)];
    }
  }

  final out = <SampleAlignedPair>[];

  String? pendingEn;
  for (final line in lines) {
    if (line.isEmpty) continue;

    final cleaned = _cleanSampleLine(line);

    if (_isEnglishSectionLabel(cleaned)) {
      pendingEn = _stripLeadingSectionLabel(cleaned);
      continue;
    }
    if (_isLocalSectionLabel(cleaned)) {
      final local = _stripLeadingSectionLabel(cleaned);
      if (pendingEn != null && pendingEn.trim().isNotEmpty) {
        out.add(SampleAlignedPair(pendingEn, local));
        pendingEn = null;
      }
      continue;
    }

    if (out.isEmpty) {
      final rtlCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
      if (rtlCount > (text.length / 20)) {
        return [SampleAlignedPair('', _stripSampleHeadingPrefix(text))];
      }
      return [SampleAlignedPair(_stripSampleHeadingPrefix(text), '')];
    }
  }

  return out;
}

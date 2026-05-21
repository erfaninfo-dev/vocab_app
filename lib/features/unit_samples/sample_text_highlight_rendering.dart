import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sample_text_highlights_controller.dart';

class EnWordToken {
  const EnWordToken({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}

TextStyle? styleForSegment({
  required int segStart,
  required int segEnd,
  required TextStyle? baseStyle,
  required List<SampleTextHighlight> userHighlights,
  required bool ttsLingering,
  required bool ttsKaraoke,
  required int ttsA,
  required int ttsB,
  required TextStyle? ttsReadStyle,
  required TextStyle? ttsCurrentStyle,
}) {
  if (ttsLingering && ttsReadStyle != null) {
    return ttsReadStyle;
  }
  if (ttsKaraoke) {
    if (segEnd <= ttsA) return ttsReadStyle ?? baseStyle;
    if (ttsA < ttsB && segStart < ttsB && segEnd > ttsA) {
      return ttsCurrentStyle ?? baseStyle;
    }
  }

  SampleTextHighlight? top;
  for (final h in userHighlights) {
    if (h.start < segEnd && h.end > segStart) {
      top = h;
    }
  }
  if (top != null) {
    return baseStyle?.copyWith(
      backgroundColor: top.color.withValues(alpha: 0.72),
    );
  }
  return baseStyle;
}

List<int> collectBreakpoints({
  required int textLength,
  required List<EnWordToken> tokens,
  required List<SampleTextHighlight> userHighlights,
  required bool ttsKaraoke,
  required int ttsA,
  required int ttsB,
}) {
  final points = <int>{0, textLength};
  for (final t in tokens) {
    points.add(t.start.clamp(0, textLength));
    points.add(t.end.clamp(0, textLength));
  }
  for (final h in userHighlights) {
    points.add(h.start.clamp(0, textLength));
    points.add(h.end.clamp(0, textLength));
  }
  if (ttsKaraoke) {
    points.add(ttsA.clamp(0, textLength));
    points.add(ttsB.clamp(0, textLength));
  }
  final sorted = points.toList()..sort();
  return sorted;
}

int? tokenIndexForRange({
  required List<EnWordToken> tokens,
  required int segStart,
  required int segEnd,
}) {
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.start == segStart && t.end == segEnd) return i;
  }
  return null;
}

List<InlineSpan> buildEnglishSpans({
  required String en,
  required List<EnWordToken> tokens,
  required List<SampleTextHighlight> userHighlights,
  required TextStyle? baseStyle,
  required TextStyle? ttsReadStyle,
  required TextStyle? ttsCurrentStyle,
  required bool ttsLingering,
  required bool ttsKaraoke,
  required int ttsA,
  required int ttsB,
  required List<TapGestureRecognizer> tapRecognizers,
  required void Function(int tokenIndex) onWordTap,
  required String Function(String) bidiWrap,
}) {
  if (en.isEmpty) return const [];

  final breakpoints = collectBreakpoints(
    textLength: en.length,
    tokens: tokens,
    userHighlights: userHighlights,
    ttsKaraoke: ttsKaraoke,
    ttsA: ttsA,
    ttsB: ttsB,
  );

  final children = <InlineSpan>[];
  for (var i = 0; i < breakpoints.length - 1; i++) {
    final segStart = breakpoints[i];
    final segEnd = breakpoints[i + 1];
    if (segEnd <= segStart) continue;

    final style = styleForSegment(
      segStart: segStart,
      segEnd: segEnd,
      baseStyle: baseStyle,
      userHighlights: userHighlights,
      ttsLingering: ttsLingering,
      ttsKaraoke: ttsKaraoke,
      ttsA: ttsA,
      ttsB: ttsB,
      ttsReadStyle: ttsReadStyle,
      ttsCurrentStyle: ttsCurrentStyle,
    );

    final tokenIndex = tokenIndexForRange(
      tokens: tokens,
      segStart: segStart,
      segEnd: segEnd,
    );

    TapGestureRecognizer? recognizer;
    if (tokenIndex != null && tokenIndex < tapRecognizers.length) {
      recognizer = tapRecognizers[tokenIndex]
        ..onTap = () => onWordTap(tokenIndex);
    }

    children.add(
      TextSpan(
        text: bidiWrap(en.substring(segStart, segEnd)),
        style: style,
        recognizer: recognizer,
      ),
    );
  }
  return children;
}

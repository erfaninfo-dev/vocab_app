import 'package:flutter/widgets.dart';

/// Detects the intrinsic direction of a chat message so Persian / Arabic / Hebrew
/// text aligns right-to-left while English stays left-to-right inside the same
/// bubble.
///
/// Strategy mirrors Unicode UBA "first strong" rule: we scan the text for the
/// first character that is strongly RTL or strongly LTR, ignoring neutrals
/// (punctuation, digits, whitespace, emoji, BiDi marks). If the first strong
/// character is RTL, we render the bubble RTL; otherwise LTR. When the string
/// is empty or contains only neutrals, [fallback] is returned.
TextDirection detectMessageDirection(
  String text, {
  TextDirection fallback = TextDirection.ltr,
}) {
  for (final rune in text.runes) {
    if (_isStrongRtl(rune)) return TextDirection.rtl;
    if (_isStrongLtr(rune)) return TextDirection.ltr;
  }
  return fallback;
}

/// True when [rune] is any strong right-to-left letter: Hebrew, Arabic, Syriac,
/// Thaana, N'Ko, Samaritan, Mandaic, plus the Arabic Presentation Forms blocks.
bool _isStrongRtl(int rune) {
  // Hebrew
  if (rune >= 0x0590 && rune <= 0x05FF) return true;
  // Arabic (main block)
  if (rune >= 0x0600 && rune <= 0x06FF) return true;
  // Syriac / Thaana / Arabic supplement
  if (rune >= 0x0700 && rune <= 0x07BF) return true;
  // N'Ko / Samaritan / Mandaic
  if (rune >= 0x07C0 && rune <= 0x08FF) return true;
  // Hebrew / Arabic presentation forms-A
  if (rune >= 0xFB1D && rune <= 0xFDFF) return true;
  // Arabic presentation forms-B
  if (rune >= 0xFE70 && rune <= 0xFEFF) return true;
  return false;
}

/// True when [rune] is a strong LTR letter (Latin, Greek, Cyrillic, CJK, etc.).
///
/// We deliberately keep this narrower than "not RTL" so neutral characters
/// (digits, punctuation, emoji) don't flip the direction.
bool _isStrongLtr(int rune) {
  // Basic Latin letters
  if ((rune >= 0x0041 && rune <= 0x005A) ||
      (rune >= 0x0061 && rune <= 0x007A)) {
    return true;
  }
  // Latin-1 Supplement letters (skip control + symbols)
  if (rune >= 0x00C0 && rune <= 0x00FF && rune != 0x00D7 && rune != 0x00F7) {
    return true;
  }
  // Latin Extended-A / -B / IPA
  if (rune >= 0x0100 && rune <= 0x02AF) return true;
  // Greek and Coptic + Cyrillic + Armenian (still LTR scripts)
  if (rune >= 0x0370 && rune <= 0x058F) return true;
  // CJK unified ideographs, Hangul, Hiragana, Katakana — treat as LTR.
  if (rune >= 0x3040 && rune <= 0x9FFF) return true;
  if (rune >= 0xAC00 && rune <= 0xD7AF) return true;
  return false;
}

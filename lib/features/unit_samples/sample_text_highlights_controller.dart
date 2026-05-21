import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/language/language_provider.dart';

const List<Color> kSampleHighlightPalette = [
  Color(0xFFFFF59D),
  Color(0xFFA5D6A7),
  Color(0xFFF48FB1),
  Color(0xFF90CAF9),
  Color(0xFFFFCC80),
  Color(0xFFCE93D8),
];

class SampleTextHighlight {
  const SampleTextHighlight({
    required this.id,
    required this.sampleId,
    required this.langKey,
    required this.paragraphIndex,
    required this.start,
    required this.end,
    required this.colorValue,
  });

  final String id;
  final int sampleId;
  final String langKey;
  final int paragraphIndex;
  final int start;
  final int end;
  final int colorValue;

  Color get color => Color(colorValue);

  bool intersects(int selStart, int selEnd) =>
      start < selEnd && end > selStart;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sampleId': sampleId,
    'langKey': langKey,
    'paragraphIndex': paragraphIndex,
    'start': start,
    'end': end,
    'color': colorValue,
  };

  factory SampleTextHighlight.fromJson(Map<String, dynamic> json) {
    return SampleTextHighlight(
      id: (json['id'] ?? '').toString(),
      sampleId: _asInt(json['sampleId']),
      langKey: (json['langKey'] ?? 'fa').toString(),
      paragraphIndex: _asInt(json['paragraphIndex']),
      start: _asInt(json['start']),
      end: _asInt(json['end']),
      colorValue: _asInt(json['color']),
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class SampleTextHighlightsState {
  const SampleTextHighlightsState({
    required this.highlights,
    required this.defaultColor,
    this.hydrated = false,
  });

  final List<SampleTextHighlight> highlights;
  final Color defaultColor;
  final bool hydrated;

  List<SampleTextHighlight> forParagraph({
    required int sampleId,
    required String langKey,
    required int paragraphIndex,
  }) {
    return highlights
        .where(
          (h) =>
              h.sampleId == sampleId &&
              h.langKey == langKey &&
              h.paragraphIndex == paragraphIndex,
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  SampleTextHighlightsState copyWith({
    List<SampleTextHighlight>? highlights,
    Color? defaultColor,
    bool? hydrated,
  }) {
    return SampleTextHighlightsState(
      highlights: highlights ?? this.highlights,
      defaultColor: defaultColor ?? this.defaultColor,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

final sampleTextHighlightsProvider =
    NotifierProvider<SampleTextHighlightsController, SampleTextHighlightsState>(
      SampleTextHighlightsController.new,
    );

class SampleTextHighlightsController extends Notifier<SampleTextHighlightsState> {
  static const _highlightsKey = 'unit_sample_text_highlights_v1';
  static const _defaultColorKey = 'unit_sample_highlight_default_color_v1';

  @override
  SampleTextHighlightsState build() {
    _hydrate();
    return SampleTextHighlightsState(
      highlights: const [],
      defaultColor: kSampleHighlightPalette[0],
      hydrated: false,
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_highlightsKey);
    final items = <SampleTextHighlight>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map<String, dynamic>) {
              items.add(SampleTextHighlight.fromJson(e));
            } else if (e is Map) {
              items.add(
                SampleTextHighlight.fromJson(Map<String, dynamic>.from(e)),
              );
            }
          }
        }
      } catch (_) {}
    }
    final colorRaw = prefs.getInt(_defaultColorKey);
    final defaultColor = colorRaw != null
        ? Color(colorRaw)
        : kSampleHighlightPalette[0];
    state = SampleTextHighlightsState(
      highlights: items,
      defaultColor: defaultColor,
      hydrated: true,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.highlights.map((e) => e.toJson()).toList());
    await prefs.setString(_highlightsKey, encoded);
    await prefs.setInt(_defaultColorKey, state.defaultColor.toARGB32());
  }

  Future<void> setDefaultColor(Color color) async {
    state = state.copyWith(defaultColor: color);
    await _persist();
  }

  Future<void> addHighlight({
    required int sampleId,
    required String langKey,
    required int paragraphIndex,
    required int start,
    required int end,
    required String plainText,
    Color? color,
  }) async {
    final normalized = _normalizeSelection(plainText, start, end);
    if (normalized == null) return;
    final (s, e) = normalized;
    final chosen = color ?? state.defaultColor;
    final id =
        '${sampleId}_${langKey}_${paragraphIndex}_${s}_${e}_${DateTime.now().millisecondsSinceEpoch}';
    final next = [
      ...state.highlights,
      SampleTextHighlight(
        id: id,
        sampleId: sampleId,
        langKey: langKey,
        paragraphIndex: paragraphIndex,
        start: s,
        end: e,
        colorValue: chosen.toARGB32(),
      ),
    ];
    state = state.copyWith(highlights: next);
    await _persist();
  }

  /// Replaces any highlights overlapping [start, end) with a single span.
  Future<void> replaceHighlightForSelection({
    required int sampleId,
    required String langKey,
    required int paragraphIndex,
    required int start,
    required int end,
    required String plainText,
    required Color color,
  }) async {
    final normalized = _normalizeSelection(plainText, start, end);
    if (normalized == null) return;
    final (s, e) = normalized;
    final kept = state.highlights.where((h) {
      if (h.sampleId != sampleId ||
          h.langKey != langKey ||
          h.paragraphIndex != paragraphIndex) {
        return true;
      }
      return !h.intersects(s, e);
    }).toList();
    final id =
        '${sampleId}_${langKey}_${paragraphIndex}_${s}_${e}_${DateTime.now().millisecondsSinceEpoch}';
    kept.add(
      SampleTextHighlight(
        id: id,
        sampleId: sampleId,
        langKey: langKey,
        paragraphIndex: paragraphIndex,
        start: s,
        end: e,
        colorValue: color.toARGB32(),
      ),
    );
    state = state.copyWith(highlights: kept);
    await _persist();
  }

  (int start, int end)? normalizedSelectionRange(
    String plainText,
    int start,
    int end,
  ) =>
      _normalizeSelection(plainText, start, end);

  bool selectionOverlapsHighlights({
    required String plainText,
    required int sampleId,
    required String langKey,
    required int paragraphIndex,
    required int start,
    required int end,
  }) {
    final normalized = _normalizeSelection(plainText, start, end);
    if (normalized == null) return false;
    final (s, e) = normalized;
    return state.highlights.any(
      (h) =>
          h.sampleId == sampleId &&
          h.langKey == langKey &&
          h.paragraphIndex == paragraphIndex &&
          h.intersects(s, e),
    );
  }

  Future<void> removeIntersecting({
    required int sampleId,
    required String langKey,
    required int paragraphIndex,
    required int start,
    required int end,
    required String plainText,
  }) async {
    final normalized = _normalizeSelection(plainText, start, end);
    if (normalized == null) return;
    final (s, e) = normalized;
    final next = state.highlights.where((h) {
      if (h.sampleId != sampleId ||
          h.langKey != langKey ||
          h.paragraphIndex != paragraphIndex) {
        return true;
      }
      return !h.intersects(s, e);
    }).toList();
    state = state.copyWith(highlights: next);
    await _persist();
  }

  (int start, int end)? _normalizeSelection(
    String text,
    int start,
    int end, {
    bool trimEdges = true,
  }) {
    var s = start.clamp(0, text.length);
    var e = end.clamp(0, text.length);
    if (e < s) {
      final t = s;
      s = e;
      e = t;
    }
    if (e <= s) return null;
    if (trimEdges && text.isNotEmpty) {
      while (s < e && text[s].trim().isEmpty) {
        s++;
      }
      while (e > s && text[e - 1].trim().isEmpty) {
        e--;
      }
    }
    if (e <= s) return null;
    return (s, e);
  }
}

String sampleTextLangKey(TranslationLang lang) =>
    lang == TranslationLang.fa ? 'fa' : 'kur';

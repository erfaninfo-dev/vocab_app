import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vocab_entry.dart';

// ─── Translation Language Enum ────────────────────────────────────────────────

enum TranslationLang {
  fa('فارسی', 'Persian'),
  kur('کوردی (سورانی)', 'Kurdish (Sorani)');

  const TranslationLang(this.nativeLabel, this.englishLabel);
  final String nativeLabel;
  final String englishLabel;
}

// ─── Key ──────────────────────────────────────────────────────────────────────

const _kLang = 'translation_lang_v1';

// ─── Notifier ─────────────────────────────────────────────────────────────────

class LangNotifier extends StateNotifier<TranslationLang> {
  LangNotifier() : super(TranslationLang.fa) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kLang);
    if (saved == TranslationLang.kur.name) {
      state = TranslationLang.kur;
    } else {
      state = TranslationLang.fa;
    }
  }

  Future<void> setLang(TranslationLang lang) async {
    state = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, lang.name);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final langProvider = StateNotifierProvider<LangNotifier, TranslationLang>(
  (_) => LangNotifier(),
);

bool _looksCorruptLocalText(String value) {
  final compact = value.replaceAll(
    RegExp(r'[\s\p{P}\p{S}]+', unicode: true),
    '',
  );
  if (compact.isEmpty) return false;
  if (compact.contains('\uFFFD')) return true;
  final questionMarks = '?'.allMatches(compact).length;
  return compact.length >= 3 && questionMarks / compact.length >= 0.6;
}

String _cleanLocalFallback(List<String> values) {
  for (final raw in values) {
    final value = raw.trim();
    if (value.isNotEmpty && !_looksCorruptLocalText(value)) return value;
  }
  return '';
}

// ─── Convenience extension on VocabEntry ─────────────────────────────────────

extension VocabLang on VocabEntry {
  /// Returns the meaning for the selected language.
  /// Falls back to the other local language, then English, when a local value is
  /// empty or already arrived from the server as replacement/question marks.
  String meaningFor(TranslationLang lang) {
    if (lang == TranslationLang.kur) {
      return _cleanLocalFallback([meaningKur, meaningFa, meaningEn]);
    }
    return _cleanLocalFallback([meaningFa, meaningKur, meaningEn]);
  }

  /// Returns the example sentence for the selected language.
  /// Falls back to the other local language, then English, when needed.
  String exampleLocalFor(TranslationLang lang) {
    if (lang == TranslationLang.kur) {
      return _cleanLocalFallback([exampleKur, exampleFa, exampleEn]);
    }
    return _cleanLocalFallback([exampleFa, exampleKur, exampleEn]);
  }

  /// True when the selected language uses RTL text direction.
  /// Both Persian and Kurdish (Sorani) are RTL.
  bool get isLocalRtl => true;
}

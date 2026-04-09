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

// ─── Convenience extension on VocabEntry ─────────────────────────────────────

extension VocabLang on VocabEntry {
  /// Returns the meaning for the selected language.
  /// Falls back to meaningFa if meaningKur is empty, and vice versa.
  String meaningFor(TranslationLang lang) {
    if (lang == TranslationLang.kur) {
      return meaningKur.isNotEmpty ? meaningKur : meaningFa;
    }
    return meaningFa.isNotEmpty ? meaningFa : meaningKur;
  }

  /// Returns the example sentence for the selected language.
  /// Falls back to the other language if the selected one is empty.
  String exampleLocalFor(TranslationLang lang) {
    if (lang == TranslationLang.kur) {
      return exampleKur.isNotEmpty ? exampleKur : exampleFa;
    }
    return exampleFa.isNotEmpty ? exampleFa : exampleKur;
  }

  /// True when the selected language uses RTL text direction.
  /// Both Persian and Kurdish (Sorani) are RTL.
  bool get isLocalRtl => true;
}

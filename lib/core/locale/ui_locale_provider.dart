import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUiLocaleCode = 'ui_locale_v1';

/// App interface locales: English, Persian, Kurdish (Sorani).
final uiLocaleProvider = StateNotifierProvider<UiLocaleNotifier, Locale>((ref) {
  return UiLocaleNotifier();
});

class UiLocaleNotifier extends StateNotifier<Locale> {
  UiLocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kUiLocaleCode);
    if (code == null || code.isEmpty) {
      return;
    }
    state = Locale(code);
  }

  /// Persists [languageCode]: `en`, `fa`, or `ckb`.
  Future<void> setLocaleCode(String languageCode) async {
    state = Locale(languageCode);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUiLocaleCode, languageCode);
  }
}

import 'package:flutter/material.dart';

class AppReleaseNotes {
  const AppReleaseNotes({
    this.en = '',
    this.fa = '',
    this.ku = '',
  });

  final String en;
  final String fa;
  final String ku;

  static const empty = AppReleaseNotes();

  factory AppReleaseNotes.fromJson(Object? json) {
    if (json is! Map) return AppReleaseNotes.empty;
    return AppReleaseNotes(
      en: (json['en'] ?? '').toString(),
      fa: (json['fa'] ?? '').toString(),
      ku: (json['ku'] ?? '').toString(),
    );
  }

  String bodyFor(Locale locale) {
    final code = locale.languageCode;
    if (code == 'fa') {
      final t = fa.trim();
      if (t.isNotEmpty) return t;
    } else if (code == 'ckb') {
      final t = ku.trim();
      if (t.isNotEmpty) return t;
    } else {
      final t = en.trim();
      if (t.isNotEmpty) return t;
    }
    for (final t in [en, fa, ku]) {
      final s = t.trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}

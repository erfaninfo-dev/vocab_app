import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/flashcard_session.dart';

const Duration _kSessionExpiry = Duration(days: 7);

class FlashcardSessionStorage {
  const FlashcardSessionStorage._();

  static Future<FlashcardSessionModel?> loadSession(String deckKey) async {
    if (deckKey.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(deckKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final model = FlashcardSessionModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (model.deckKey != deckKey) return null;
      return model;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSession(FlashcardSessionModel model) async {
    if (model.deckKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(model.deckKey, jsonEncode(model.toJson()));
  }

  static Future<void> clearSession(String deckKey) async {
    if (deckKey.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(deckKey);
  }

  /// A saved session is only resumable when it is in-progress and not expired.
  static Future<bool> hasResumableSession(String deckKey) async {
    final saved = await loadSession(deckKey);
    if (saved == null) return false;
    if (saved.wordIds.isEmpty) return false;
    if (saved.currentIndex <= 0 || saved.currentIndex >= saved.wordIds.length) {
      return false;
    }
    final age = DateTime.now().difference(saved.updatedAt);
    return age <= _kSessionExpiry;
  }
}

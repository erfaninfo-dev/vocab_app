import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/api_service.dart';
import '../../domain/api_providers.dart';

/// Local outbox for updates that should be persisted on server.
///
/// Current use: toggling `important` on a `words` row.
const _kPendingImportantKey = 'pending_word_important_v1';

Future<Map<int, int>> loadPendingImportant() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPendingImportantKey);
  if (raw == null || raw.trim().isEmpty) return <int, int>{};
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <int, int>{};
    for (final entry in decoded.entries) {
      final id = int.tryParse(entry.key);
      final v = (entry.value as num?)?.toInt();
      if (id != null && id > 0 && (v == 0 || v == 1)) {
        out[id] = v!;
      }
    }
    return out;
  } catch (_) {
    return <int, int>{};
  }
}

Future<void> _savePendingImportant(Map<int, int> map) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = <String, int>{
    for (final e in map.entries) '${e.key}': e.value,
  };
  await prefs.setString(_kPendingImportantKey, jsonEncode(encoded));
}

Future<void> enqueuePendingImportant({
  required int id,
  required int important,
}) async {
  final next = important == 1 ? 1 : 0;
  final map = await loadPendingImportant();
  map[id] = next;
  await _savePendingImportant(map);
}

Future<void> removePendingImportant(int id) async {
  final map = await loadPendingImportant();
  if (!map.containsKey(id)) return;
  map.remove(id);
  await _savePendingImportant(map);
}

/// Attempts to flush all pending important updates to the server.
/// Keeps remaining items in outbox if any update fails.
Future<int> syncPendingImportantUpdates(WidgetRef ref) async {
  final pending = await loadPendingImportant();
  if (pending.isEmpty) return 0;

  final ApiService api = ref.read(apiServiceProvider);
  var ok = 0;

  for (final entry in pending.entries) {
    try {
      await api.setWordImportant(id: entry.key, important: entry.value);
      ok++;
      await removePendingImportant(entry.key);
    } catch (_) {
      // Keep it in outbox; we'll retry next refresh.
    }
  }
  return ok;
}


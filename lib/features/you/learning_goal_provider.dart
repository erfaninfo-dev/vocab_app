import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningGoal {
  const LearningGoal({
    required this.startedOn,
    required this.totalDays,
    this.title = '',
  });

  final DateTime startedOn;
  final int totalDays;

  /// Free-text description of what the user is working towards
  /// (e.g. "IELTS band 7", "500 new words"). May be empty.
  final String title;

  DateTime get targetOn => startedOn.add(Duration(days: totalDays));

  int elapsedDays(DateTime now) {
    final today = _dateOnly(now);
    final start = _dateOnly(startedOn);
    return today.difference(start).inDays.clamp(0, totalDays);
  }

  int remainingDays(DateTime now) => totalDays - elapsedDays(now);

  double progress(DateTime now) {
    if (totalDays <= 0) return 0;
    return elapsedDays(now) / totalDays;
  }

  LearningGoal copyWith({DateTime? startedOn, int? totalDays, String? title}) {
    return LearningGoal(
      startedOn: startedOn ?? this.startedOn,
      totalDays: totalDays ?? this.totalDays,
      title: title ?? this.title,
    );
  }

  String encode() =>
      '${_dateOnly(startedOn).toIso8601String()}\x1F$totalDays\x1F$title';

  static LearningGoal? decode(String raw) {
    final parts = raw.split('\x1F');
    if (parts.length < 2) return null;

    final startedOn = DateTime.tryParse(parts[0]);
    final totalDays = int.tryParse(parts[1]);
    if (startedOn == null || totalDays == null || totalDays <= 0) {
      return null;
    }

    final title = parts.length >= 3 ? parts.sublist(2).join('\x1F') : '';

    return LearningGoal(
      startedOn: _dateOnly(startedOn),
      totalDays: totalDays,
      title: title,
    );
  }
}

class LearningGoalController extends Notifier<LearningGoal?> {
  static const _storageKey = 'learning_goal_v1';

  @override
  LearningGoal? build() {
    _hydrate();
    return null;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    state = LearningGoal.decode(raw);
  }

  Future<void> setGoal(int days, String title) async {
    final normalizedDays = days.clamp(1, 3650);
    state = LearningGoal(
      startedOn: _dateOnly(DateTime.now()),
      totalDays: normalizedDays,
      title: title.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, state!.encode());
  }

  Future<void> clearGoal() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

final learningGoalProvider =
    NotifierProvider<LearningGoalController, LearningGoal?>(
      LearningGoalController.new,
    );

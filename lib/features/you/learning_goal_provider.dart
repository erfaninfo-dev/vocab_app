import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningGoal {
  const LearningGoal({required this.startedOn, required this.totalDays});

  final DateTime startedOn;
  final int totalDays;

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

  LearningGoal copyWith({DateTime? startedOn, int? totalDays}) {
    return LearningGoal(
      startedOn: startedOn ?? this.startedOn,
      totalDays: totalDays ?? this.totalDays,
    );
  }

  String encode() => '${_dateOnly(startedOn).toIso8601String()}\x1F$totalDays';

  static LearningGoal? decode(String raw) {
    final parts = raw.split('\x1F');
    if (parts.length != 2) return null;
    final startedOn = DateTime.tryParse(parts[0]);
    final totalDays = int.tryParse(parts[1]);
    if (startedOn == null || totalDays == null || totalDays <= 0) {
      return null;
    }
    return LearningGoal(startedOn: _dateOnly(startedOn), totalDays: totalDays);
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

  Future<void> setGoalDays(int days) async {
    final normalizedDays = days.clamp(1, 3650);
    state = LearningGoal(
      startedOn: _dateOnly(DateTime.now()),
      totalDays: normalizedDays,
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

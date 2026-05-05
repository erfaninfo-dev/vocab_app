import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/class_schedule_slot.dart';

/// Weekday order for list UI: Persian/Kurdish calendars often start Saturday.
List<int> weekdayDisplayOrder(Locale locale) {
  switch (locale.languageCode) {
    case 'fa':
    case 'ckb':
      return const [6, 7, 1, 2, 3, 4, 5];
    default:
      return const [1, 2, 3, 4, 5, 6, 7];
  }
}

TimeOfDay? parseScheduleHm(String raw) {
  final p = raw.trim().split(':');
  if (p.length < 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

String scheduleHm(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String weekdayTitle(BuildContext context, int weekday) {
  final loc = Localizations.localeOf(context).toString();
  final d = DateTime(2024, 1, 1).add(Duration(days: weekday - 1));
  return DateFormat.EEEE(loc).format(d);
}

String formatScheduleRange(
  ClassScheduleSlot s,
  String locale,
  DateFormat timeFmt,
) {
  final st = parseScheduleHm(s.startTime);
  if (st == null) return s.startTime;
  final dtSt = DateTime(2000, 1, 1, st.hour, st.minute);
  final endRaw = s.endTime;
  if (endRaw == null || endRaw.isEmpty) {
    return timeFmt.format(dtSt);
  }
  final et = parseScheduleHm(endRaw);
  if (et == null) return timeFmt.format(dtSt);
  final dtEt = DateTime(2000, 1, 1, et.hour, et.minute);
  return '${timeFmt.format(dtSt)} – ${timeFmt.format(dtEt)}';
}

int timeOfDayToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

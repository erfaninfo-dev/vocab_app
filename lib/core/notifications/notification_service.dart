import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─── Keys ─────────────────────────────────────────────────────────────────────

const _kNotifEnabled = 'notif_enabled';
const _kNotifHour    = 'notif_hour';
const _kNotifMinute  = 'notif_minute';
const _notifId       = 1;

// ─── Plugin instance (singleton) ─────────────────────────────────────────────

final _plugin = FlutterLocalNotificationsPlugin();

// ─── Init (call once in main) ─────────────────────────────────────────────────

Future<void> initNotifications() async {
  tz.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/app_icon');
  const initSettings = InitializationSettings(android: androidSettings);
  await _plugin.initialize(initSettings);
}

// ─── Notification State ───────────────────────────────────────────────────────

class NotifSettings {
  const NotifSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  NotifSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      NotifSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotifNotifier extends StateNotifier<NotifSettings> {
  NotifNotifier() : super(const NotifSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = NotifSettings(
      enabled: p.getBool(_kNotifEnabled) ?? false,
      hour:    p.getInt(_kNotifHour)    ?? 20,
      minute:  p.getInt(_kNotifMinute)  ?? 0,
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifEnabled, state.enabled);
    await p.setInt(_kNotifHour,    state.hour);
    await p.setInt(_kNotifMinute,  state.minute);
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await _save();
    if (value) {
      await _schedule();
    } else {
      await _cancel();
    }
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _save();
    if (state.enabled) await _schedule();
  }

  Future<void> _schedule() async {
    await _cancel();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      state.hour,
      state.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'ielts_daily',
      'Erfan Academy',
      channelDescription: 'Daily vocabulary review reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/app_icon',
    );

    await _plugin.zonedSchedule(
      _notifId,
      '📚 Erfan Academy — Study time!',
      'You have words to review. Keep your streak going!',
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _cancel() async {
    await _plugin.cancel(_notifId);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notifProvider = StateNotifierProvider<NotifNotifier, NotifSettings>(
  (_) => NotifNotifier(),
);

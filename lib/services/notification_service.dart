// lib/services/notification_service.dart
//
// Wraps flutter_local_notifications.
// Call NotificationService.init() once in main().
// Call scheduleAlarm() when an alarm is created/enabled.
// Call cancelAlarm() when an alarm is deleted/disabled.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../screens/alarm_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── Init ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap – navigate to alarm screen if needed.
    debugPrint('Notification tapped: ${response.id}');
  }

  // ─── Schedule ────────────────────────────────────────────────────────────

  /// Schedule a repeating or one-time alarm notification.
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;
    await init();

    final bool isRepeating = alarm.repeatDays.contains(true);

    if (isRepeating) {
      // Schedule one notification per active weekday.
      for (int i = 0; i < 7; i++) {
        if (!alarm.repeatDays[i]) continue;
        final notifId = _notifId(alarm.id, dayIndex: i);
        final scheduledDate =
        _nextWeekdayTime(alarm.hour, alarm.minute, i);
        await _scheduleOne(
          id: notifId,
          title: '⏰ ${alarm.label}',
          body: alarm.timeString,
          scheduledDate: scheduledDate,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      // One-shot alarm for the next occurrence of the time.
      final notifId = _notifId(alarm.id);
      final scheduledDate = _nextOccurrence(alarm.hour, alarm.minute);
      await _scheduleOne(
        id: notifId,
        title: '⏰ ${alarm.label}',
        body: alarm.timeString,
        scheduledDate: scheduledDate,
        matchDateTimeComponents: null, // fire once
      );
    }
  }

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents? matchDateTimeComponents,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime, // ✅ ADD THIS
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint(
        'Scheduled notification $id for $scheduledDate (repeat: $matchDateTimeComponents)');
  }

  // ─── Cancel ──────────────────────────────────────────────────────────────

  /// Cancel all notifications for a given alarm.
  static Future<void> cancelAlarm(String alarmId) async {
    await init();
    // Cancel one-shot id.
    await _plugin.cancel(_notifId(alarmId));
    // Cancel all weekday ids.
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_notifId(alarmId, dayIndex: i));
    }
  }

  /// Cancel ALL scheduled notifications.
  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Convert alarm id + optional day to a unique int notification id.
  /// We use the last 6 digits of the alarm id hash + day offset.
  static int _notifId(String alarmId, {int? dayIndex}) {
    final base = alarmId.hashCode.abs() % 100000;
    return dayIndex == null ? base : base + (dayIndex + 1) * 100000;
  }

  /// Next occurrence of [hour]:[minute] from now (today if still in future,
  /// otherwise tomorrow).
  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Next occurrence of [hour]:[minute] on ISO weekday [dayIndex]
  /// where 0 = Monday … 6 = Sunday (matching AlarmModel.repeatDays).
  static tz.TZDateTime _nextWeekdayTime(int hour, int minute, int dayIndex) {
    // Flutter weekday: Mon=1…Sun=7.  dayIndex: Mon=0…Sun=6.
    final targetWeekday = dayIndex + 1;
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    // Advance until we hit the right weekday and the time is in the future.
    for (int i = 0; i < 8; i++) {
      if (candidate.weekday == targetWeekday &&
          candidate.isAfter(now)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
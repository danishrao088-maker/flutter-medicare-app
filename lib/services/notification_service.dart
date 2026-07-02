import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Wraps `flutter_local_notifications` so the rest of the app can schedule
/// and cancel reminders without dealing with platform-specific details.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Hook for navigating into the app from a tapped notification.
      },
    );

    await _requestAndroidPermissions();
    _initialized = true;
  }

  Future<void> _requestAndroidPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.id == null) return;
    await cancelReminder(reminder.id!);
    if (!reminder.isActive) return;

    final parts = reminder.time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    const androidDetails = AndroidNotificationDetails(
      'medicare_reminders',
      'Medicine Reminders',
      channelDescription: 'Reminders to take your medicine on time',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00D4AA),
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    const title = '💊 Medicine Reminder';
    final body = 'Time to take ${reminder.medicineName} - ${reminder.dose}';

    try {
      if (reminder.days.isEmpty) {
        await _plugin.zonedSchedule(
          reminder.id!,
          title,
          body,
          _nextInstanceOfTime(hour, minute),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        for (final day in reminder.days) {
          final notifId = reminder.id! * 10 + day;
          await _plugin.zonedSchedule(
            notifId,
            title,
            body,
            _nextInstanceOfDayAndTime(day, hour, minute),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    } catch (e) {
      // Exact-alarm permission may be denied; fall back gracefully without
      // crashing the app.
      debugPrint('scheduleReminder failed: $e');
    }
  }

  Future<void> showLowStockNotification(String medicineName, int remaining) async {
    const androidDetails = AndroidNotificationDetails(
      'medicare_stock',
      'Low Stock Alerts',
      channelDescription: 'Alerts when a medicine\'s stock is running low',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF6B6B),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(
      id,
      '⚠️ Low Stock Alert',
      '$medicineName is running low — only $remaining left.',
      details,
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    await _plugin.cancel(reminderId);
    // Day-specific notifications use reminderId*10 + day (1..7).
    for (int i = 1; i <= 7; i++) {
      await _plugin.cancel(reminderId * 10 + i);
    }
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != day) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

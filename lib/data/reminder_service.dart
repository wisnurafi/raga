import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// The weekly weigh-in nudge. One notification, every Sunday at 9 AM
// local time. Inexact scheduling on purpose — no exact-alarm permission
// needed, and a reminder doesn't have to be precise to the minute.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _weeklyId = 1001;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
    );
  }

  // Android 13+ needs runtime permission; older versions grant it by default.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> scheduleWeekly() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    while (next.weekday != DateTime.sunday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _weeklyId,
      'Weigh-in time',
      'Hop on the scale and log your weight in Raga.',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'raga_weekly',
          'Weekly reminder',
          channelDescription: 'Weekly weigh-in reminder',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancel() => _plugin.cancel(_weeklyId);
}

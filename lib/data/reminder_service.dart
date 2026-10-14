import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// The weekly weigh-in nudge. One notification a week, on the day and time
// the user picks. Inexact scheduling on purpose — no exact-alarm permission
// needed, and a reminder doesn't have to be precise to the minute.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _weeklyId = 1001;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    // tz.local defaults to UTC — point it at the device timezone so the
    // reminder fires at the wall-clock time the user picked.
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Keep UTC; the reminder still fires, just offset from local time.
    }
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

  /// The next wall-clock occurrence of a weekly (weekday, time) schedule.
  static tz.TZDateTime nextOccurrence(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static Future<void> scheduleWeekly({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final next = nextOccurrence(weekday, hour, minute);
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

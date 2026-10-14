import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// The weekly weigh-in nudge. One notification a week, on the day and time
// the user picks. Scheduled with an exact alarm so it actually fires on
// time — inexact alarms get deferred for hours (or never fire) on most
// phones once the app is swiped away.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _weeklyId = 1001;
  static const _testId = 1002;

  static const _androidDetails = AndroidNotificationDetails(
    'raga_weekly',
    'Weekly reminder',
    channelDescription: 'Weekly weigh-in reminder',
    importance: Importance.high,
    icon: 'ic_stat_notify',
  );

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
        android: AndroidInitializationSettings('ic_stat_notify'),
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

  // Android 12+ gates exact alarms behind a Settings toggle
  // ("Alarms & reminders"). True when we're allowed to use them.
  static Future<bool> canScheduleExact() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  // Opens the system Settings page where the user can allow exact alarms.
  static Future<void> requestExactAlarmsPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
    } catch (_) {
      // Older Android — nothing to grant.
    }
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

  static Future<void> _schedule({
    required int weekday,
    required int hour,
    required int minute,
    required AndroidScheduleMode mode,
  }) async {
    final next = nextOccurrence(weekday, hour, minute);
    await _plugin.zonedSchedule(
      _weeklyId,
      'Weigh-in time',
      'Hop on the scale and log your weight in Raga.',
      next,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> scheduleWeekly({
    required int weekday,
    required int hour,
    required int minute,
  }) =>
      _schedule(
        weekday: weekday,
        hour: hour,
        minute: minute,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );

  static Future<void> scheduleWeeklyInexact({
    required int weekday,
    required int hour,
    required int minute,
  }) =>
      _schedule(
        weekday: weekday,
        hour: hour,
        minute: minute,
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

  /// Schedules with exact alarms when allowed, otherwise inexact.
  /// Returns true when the exact path was used.
  static Future<bool> scheduleBestEffort({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    if (await canScheduleExact()) {
      await scheduleWeekly(weekday: weekday, hour: hour, minute: minute);
      return true;
    }
    await scheduleWeeklyInexact(weekday: weekday, hour: hour, minute: minute);
    return false;
  }

  static Future<void> cancel() => _plugin.cancel(_weeklyId);

  // Immediate test notification (developer mode). Proves the channel,
  // permission, and icon all work without waiting a week.
  static Future<void> showTest() async {
    await _plugin.show(
      _testId,
      'Test notification',
      'Reminders are working — your weekly nudge will arrive on schedule.',
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

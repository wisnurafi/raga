import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// The weekly weigh-in nudge. One notification a week, on the day and time
// the user picks. Scheduled with an exact alarm so it actually fires on
// time — inexact alarms get deferred for hours (or never fire) on most
// phones once the app is swiped away.
//
// Hardening notes (learned the hard way): the plugin validates the icon
// natively and throws PlatformException when it's missing from the APK.
// A notification failure must NEVER kill the app, so init is wrapped and
// every schedule/show retries with the default icon as fallback.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _weeklyId = 1001;
  static const _testId = 1002;

  // Log hook: main.dart wires this to the developer sync log so every
  // scheduling decision is inspectable on-device, without logcat.
  static void Function(String msg) onLog = debugPrint;

  static const _androidDetails = AndroidNotificationDetails(
    'raga_weekly',
    'Weekly reminder',
    channelDescription: 'Weekly weigh-in reminder',
    importance: Importance.high,
    icon: 'ic_stat_notify',
  );

  // Same channel, default icon. Used when the custom icon didn't survive
  // the build (resource shrinking) — a plain notification beats none.
  static const _androidDetailsFallback = AndroidNotificationDetails(
    'raga_weekly',
    'Weekly reminder',
    channelDescription: 'Weekly weigh-in reminder',
    importance: Importance.high,
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
    try {
      // '@mipmap/ic_launcher' is guaranteed in the APK (the manifest
      // references it), so init can never die on a missing icon.
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
        ),
      );
    } catch (_) {
      // Notifications just won't work; the app itself must stay alive.
    }
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

  /// The occurrence [weeksAhead] weeks after the next one. Used to arm
  /// several future weeks as one-time exact alarms (see _schedule).
  static tz.TZDateTime occurrenceInWeeks(
      int weekday, int hour, int minute, int weeksAhead) {
    return nextOccurrence(weekday, hour, minute)
        .add(Duration(days: 7 * weeksAhead));
  }

  // Runs [fn] with the custom icon, retrying with the default icon when
  // the custom one didn't survive the build.
  static Future<T> _withIconFallback<T>(
      Future<T> Function(NotificationDetails d) fn) async {
    const withIcon = NotificationDetails(
      android: _androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    const fallback = NotificationDetails(
      android: _androidDetailsFallback,
      iOS: DarwinNotificationDetails(),
    );
    try {
      return await fn(withIcon);
    } catch (_) {
      return await fn(fallback);
    }
  }

  /// One notification id per weekday per week, so several days can be
  /// armed at once and each week is a separate one-time alarm.
  /// Week 0: 1101..1107; week 1: 1201..1207; week 2: 1301..1307;
  /// week 3: 1401..1407. The legacy single-day id 1001 is kept for
  /// cancel only.
  static int _idForDay(int weekday, [int week = 0]) =>
      1100 + weekday + week * 100;

  /// How many future weeks to arm. Each week is a separate one-time
  /// exact alarm (no matchDateTimeComponents — see _schedule).
  static const _weeksToArm = 4;

  static Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required AndroidScheduleMode mode,
  }) async {
    onLog('reminder: schedule #$id -> $when '
        '(tz=${tz.local.name}, mode=$mode)');
    await _withIconFallback(
      (d) => _plugin.zonedSchedule(
        id,
        'Weigh-in time',
        'Hop on the scale and log your weight in Raga.',
        when,
        d,
        // One-time exact alarm. NOTE: no matchDateTimeComponents here.
        // With matchDateTimeComponents set, the plugin switches to its
        // repeating path which does not honor exactAllowWhileIdle on
        // modern Android — the alarm shows as "registered" but never
        // fires. Weekly repetition is achieved by arming several future
        // weeks as separate one-time alarms (see scheduleBestEffortDays).
        androidScheduleMode: mode,
      ),
    );
    // Verify the OS actually registered it — a silently dropped alarm is
    // the worst kind of bug: everything "succeeds" and nothing fires.
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final found = pending.any((p) => p.id == id);
      onLog('reminder: OS pending check -> '
          '${found ? "registered" : "MISSING!"} (${pending.length} total)');
    } catch (e) {
      onLog('reminder: pending check failed: $e');
    }
  }

  /// Schedules with exact alarms when allowed, otherwise inexact.
  /// Arms [_weeksToArm] future weeks as separate one-time alarms
  /// (no matchDateTimeComponents — see _schedule).
  /// Returns true when the exact path was used. Never throws — worst
  /// case the reminder just doesn't get scheduled.
  static Future<bool> scheduleBestEffort({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      if (await canScheduleExact()) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    for (var w = 0; w < _weeksToArm; w++) {
      final when = occurrenceInWeeks(weekday, hour, minute, w);
      final id = _idForDay(weekday, w);
      try {
        await _schedule(id: id, when: when, mode: mode);
      } catch (_) {
        // Permission lost between check and schedule — fall back to
        // inexact for this and remaining weeks.
        if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
          mode = AndroidScheduleMode.inexactAllowWhileIdle;
          try {
            await _schedule(id: id, when: when, mode: mode);
          } catch (_) {}
        }
      }
    }
    return mode == AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// Arms the nudge on every selected weekday. Cancels stale days first
  /// so shrinking the selection doesn't leave ghost alarms behind.
  /// Returns true when every day got the exact path.
  static Future<bool> scheduleBestEffortDays({
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) async {
    await cancelAll();
    if (weekdays.isEmpty) return false;
    var allExact = true;
    for (final d in weekdays.toSet().toList()..sort()) {
      final exact = await scheduleBestEffort(
        weekday: d,
        hour: hour,
        minute: minute,
      );
      if (!exact) allExact = false;
    }
    return allExact;
  }

  static Future<void> cancel() async {
    try {
      await _plugin.cancel(_weeklyId);
    } catch (_) {}
  }

  /// Cancels the legacy id plus every per-day per-week id.
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancel(_weeklyId);
      for (var w = 0; w < _weeksToArm; w++) {
        for (var d = 1; d <= 7; d++) {
          await _plugin.cancel(_idForDay(d, w));
        }
      }
    } catch (_) {}
  }

  // What's actually registered with the OS right now. Surfaced in
  // developer mode so a "scheduled but never fires" report can be
  // diagnosed on-device instead of guessed at.
  static Future<List<PendingNotificationRequest>> pendingAlarms() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  // Immediate test notification (developer mode). Proves the channel,
  // permission, and icon all work without waiting a week.
  // Returns false when nothing could be shown.
  static Future<bool> showTest() async {
    try {
      await _withIconFallback(
        (d) => _plugin.show(
          _testId,
          'Test notification',
          'Reminders are working — your weekly nudge will arrive on schedule.',
          d,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

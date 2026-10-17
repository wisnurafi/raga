import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:raga/data/reminder_service.dart';

// H2: the weekly reminder once died silently in production because the
// exact-alarm path wasn't honored. These tests pin the fallback logic —
// exact when allowed, downgrade to inexact when the OS rejects it —
// through the @visibleForTesting seam, plus the pure scheduling math.

class _Call {
  final int id;
  final tz.TZDateTime when;
  final AndroidScheduleMode mode;
  _Call(this.id, this.when, this.mode);
}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  Future<bool> run({
    required List<_Call> calls,
    required Future<bool> Function() canUseExact,
    Future<void> Function(_Call c)? onSchedule,
  }) {
    return ReminderService.scheduleWithMode(
      weekday: 7,
      hour: 8,
      minute: 30,
      canUseExact: canUseExact,
      schedule: ({required int id, required tz.TZDateTime when,
          required AndroidScheduleMode mode}) async {
        final c = _Call(id, when, mode);
        calls.add(c);
        await onSchedule?.call(c);
      },
    );
  }

  test('exact allowed -> 4 exact one-time alarms, ids unique', () async {
    final calls = <_Call>[];
    final exact = await run(
        calls: calls, canUseExact: () async => true);
    expect(exact, isTrue);
    expect(calls.length, 4);
    expect(
        calls.map((c) => c.mode).toSet(),
        {AndroidScheduleMode.exactAllowWhileIdle});
    // Documented id scheme: week 0 = 1101..1107, week 1 = 1201..1207...
    expect(calls.map((c) => c.id).toList(), [1107, 1207, 1307, 1407]);
    for (var i = 1; i < calls.length; i++) {
      expect(calls[i].when.difference(calls[i - 1].when),
          const Duration(days: 7));
      expect(calls[i].when.weekday, 7);
    }
  });

  test('exact denied -> all inexact, returns false', () async {
    final calls = <_Call>[];
    final exact = await run(
        calls: calls, canUseExact: () async => false);
    expect(exact, isFalse);
    expect(calls.length, 4);
    expect(
        calls.map((c) => c.mode).toSet(),
        {AndroidScheduleMode.inexactAllowWhileIdle});
  });

  test('permission check throws -> falls back to inexact', () async {
    final calls = <_Call>[];
    final exact = await run(
        calls: calls, canUseExact: () async => throw StateError('no'));
    expect(exact, isFalse);
    expect(calls.length, 4);
    expect(calls.first.mode, AndroidScheduleMode.inexactAllowWhileIdle);
  });

  test('exact rejected mid-loop -> downgrade that week and the rest',
      () async {
    final calls = <_Call>[];
    final modes = <AndroidScheduleMode>[];
    final exact = await run(
      calls: calls,
      canUseExact: () async => true,
      onSchedule: (c) async {
        modes.add(c.mode);
        // OS revokes the permission after week 0's alarm was armed.
        if (c.mode == AndroidScheduleMode.exactAllowWhileIdle &&
            c.id != 1107) {
          throw StateError('exact not allowed');
        }
      },
    );
    expect(exact, isFalse);
    // week 0 exact, week 1 exact-fails-then-inexact-retry, weeks 2-3 inexact.
    expect(modes, [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]);
    expect(calls.length, 5);
  });

  test('inexact also throws -> swallowed, never throws', () async {
    final calls = <_Call>[];
    final exact = await run(
      calls: calls,
      canUseExact: () async => false,
      onSchedule: (_) async => throw StateError('os busy'),
    );
    expect(exact, isFalse);
    expect(calls.length, 4); // one attempt per week, all absorbed
  });

  test('occurrenceInWeeks keeps weekday and 7-day spacing', () {
    final w0 = ReminderService.occurrenceInWeeks(3, 8, 0, 0);
    final w2 = ReminderService.occurrenceInWeeks(3, 8, 0, 2);
    expect(w0.weekday, 3);
    expect(w2.difference(w0), const Duration(days: 14));
    expect(w2.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
  });
}

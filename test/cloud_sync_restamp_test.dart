import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:raga/data/cloud_sync.dart';
import 'package:raga/models/bmi_record.dart';

// H1: the backup restamp path (restampAllRecords) twice bit production
// with RLS 42501. These tests drive the per-record loop — skipIds,
// upsert-vs-insert, and the 42501 re-insert healer — through the
// @visibleForTesting seam, with the Supabase upsert faked.

BmiRecord _rec(String id) => BmiRecord(
      id: id,
      profileId: 'p1',
      heightCm: 170,
      weightKg: 70,
    );

const _rlsDenied =
    PostgrestException(message: 'new row violates row-level security',
        code: '42501');

void main() {
  test('all upserts succeed -> ok, nothing healed', () async {
    final seen = <String>[];
    final o = await CloudSync.restampRecordsWith(
      [_rec('a'), _rec('b')],
      upsert: (r) async => seen.add(r.id),
    );
    expect(o.ok, isTrue);
    expect(o.healed, isEmpty);
    expect(o.done, ['a', 'b']);
    expect(seen, ['a', 'b']);
    expect(o.lastFailure, isEmpty);
  });

  test('skipIds are marked done without an upsert', () async {
    final seen = <String>[];
    final o = await CloudSync.restampRecordsWith(
      [_rec('a'), _rec('b')],
      skipIds: {'a'},
      upsert: (r) async => seen.add(r.id),
    );
    expect(o.ok, isTrue);
    expect(seen, ['b']);
    expect(o.done, ['a', 'b']);
  });

  test('42501 -> healer re-inserts with a fresh id', () async {
    final seen = <BmiRecord>[];
    final o = await CloudSync.restampRecordsWith(
      [_rec('a'), _rec('b')],
      upsert: (r) async {
        seen.add(r);
        if (r.id == 'a') throw _rlsDenied;
      },
    );
    expect(o.ok, isTrue);
    expect(o.healed.keys, ['a']);
    final fresh = o.healed['a']!;
    expect(fresh, isNot('a'));
    // The re-inserted copy keeps the payload, only the id is fresh.
    final copy = seen.firstWhere((r) => r.id == fresh);
    expect(copy.id, fresh);
    expect(copy.weightKg, 70);
    expect(copy.profileId, 'p1');
    // done carries the fresh id, never the blocked one.
    expect(o.done, contains(fresh));
    expect(o.done, isNot(contains('a')));
  });

  test('non-42501 PostgrestException -> ok=false, no heal attempt',
      () async {
    var calls = 0;
    final o = await CloudSync.restampRecordsWith(
      [_rec('a')],
      upsert: (_) async {
        calls++;
        throw const PostgrestException(
            message: 'duplicate', code: '23505');
      },
    );
    expect(o.ok, isFalse);
    expect(o.healed, isEmpty);
    expect(o.done, isEmpty);
    expect(calls, 1); // no re-insert retry for other codes
    expect(o.lastFailure, isNotEmpty);
  });

  test('generic exception -> ok=false', () async {
    final o = await CloudSync.restampRecordsWith(
      [_rec('a')],
      upsert: (_) async => throw StateError('offline'),
    );
    expect(o.ok, isFalse);
    expect(o.healed, isEmpty);
    expect(o.done, isEmpty);
  });

  test('healer re-insert also fails -> ok=false, nothing healed',
      () async {
    final o = await CloudSync.restampRecordsWith(
      [_rec('a'), _rec('b')],
      upsert: (r) async {
        if (r.id == 'a') throw _rlsDenied;
        if (r.id != 'b') throw _rlsDenied; // the fresh id fails too
      },
    );
    expect(o.ok, isFalse);
    expect(o.healed, isEmpty);
    // 'b' still went through; 'a' is left for syncPending to retry.
    expect(o.done, ['b']);
  });

  test('empty list -> ok with nothing done', () async {
    final o = await CloudSync.restampRecordsWith(
      const [],
      upsert: (_) async {},
    );
    expect(o.ok, isTrue);
    expect(o.done, isEmpty);
  });
}

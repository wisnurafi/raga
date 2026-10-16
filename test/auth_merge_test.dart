import 'package:flutter_test/flutter_test.dart';
import 'package:raga/models/bmi_record.dart';
import 'package:raga/state/app_state.dart';

BmiRecord _rec(String id, double kg, DateTime at) => BmiRecord(
      id: id,
      profileId: 'p1',
      heightCm: 170,
      weightKg: kg,
      createdAt: at,
    );

void main() {
  group('mergeRecordLists', () {
    test('union by id, newest first', () {
      final local = [
        _rec('a', 70, DateTime(2026, 10, 10)),
        _rec('b', 69, DateTime(2026, 10, 12)),
      ];
      final incoming = [
        _rec('b', 69, DateTime(2026, 10, 12)), // duplicate
        _rec('c', 68, DateTime(2026, 10, 14)), // new
      ];
      final merged = mergeRecordLists(local, incoming);
      expect(merged.map((r) => r.id).toList(), ['c', 'b', 'a']);
    });

    test('empty incoming keeps local order', () {
      final local = [
        _rec('b', 69, DateTime(2026, 10, 12)),
        _rec('a', 70, DateTime(2026, 10, 10)),
      ];
      final merged = mergeRecordLists(local, const []);
      expect(merged.map((r) => r.id).toList(), ['b', 'a']);
    });

    test('empty local takes all incoming, sorted', () {
      final incoming = [
        _rec('a', 70, DateTime(2026, 10, 10)),
        _rec('c', 68, DateTime(2026, 10, 14)),
      ];
      final merged = mergeRecordLists(const [], incoming);
      expect(merged.map((r) => r.id).toList(), ['c', 'a']);
    });

    test('local rows win the dedupe (same id kept once)', () {
      final local = [_rec('a', 70, DateTime(2026, 10, 10))];
      final incoming = [_rec('a', 71, DateTime(2026, 10, 10))];
      final merged = mergeRecordLists(local, incoming);
      expect(merged, hasLength(1));
      expect(merged.first.weightKg, 70);
    });
  });
}

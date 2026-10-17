import 'package:flutter_test/flutter_test.dart';
import 'package:raga/data/cloud_sync.dart';

// M6: the backup code is the entire auth for restore — parsing and
// generation must be pinned. normalizeCode/generateBackupCode are pure,
// so no seam is needed.

void main() {
  group('normalizeCode', () {
    test('lowercase without dashes -> dashed uppercase', () {
      expect(CloudSync.normalizeCode('abcdefghijklmnop'),
          'ABCD-EFGH-IJKL-MNOP');
    });

    test('already dashed code is unchanged', () {
      expect(CloudSync.normalizeCode('ABCD-EFGH-IJKL-MNOP'),
          'ABCD-EFGH-IJKL-MNOP');
    });

    test('strips spaces and symbols, uppercases', () {
      expect(CloudSync.normalizeCode(' abcd efgh!ijkl@mnop '),
          'ABCD-EFGH-IJKL-MNOP');
    });

    test('wrong length passes through cleaned (caller validates)', () {
      // Documents current behavior: no dashes added, no throw.
      expect(CloudSync.normalizeCode('abc'), 'ABC');
      expect(
          CloudSync.normalizeCode('ABCD-EFGH-IJKL-MNOP-QRST'),
          'ABCDEFGHIJKLMNOPQRST');
    });
  });

  group('generateBackupCode', () {
    final pattern = RegExp(
        r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}'
        r'(-[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{4}){3}$');

    test('matches XXXX-XXXX-XXXX-XXXX from the unambiguous alphabet',
        () {
      for (var i = 0; i < 50; i++) {
        expect(pattern.hasMatch(CloudSync.generateBackupCode()), isTrue,
            reason: 'generation #$i');
      }
    });

    test('never emits ambiguous chars (0/O/1/I/L)', () {
      for (var i = 0; i < 50; i++) {
        final code = CloudSync.generateBackupCode();
        expect(code.contains(RegExp(r'[0O1IL]')), isFalse);
      }
    });

    test('generations are unique', () {
      final codes =
          List.generate(200, (_) => CloudSync.generateBackupCode());
      expect(codes.toSet().length, 200);
    });

    test('normalizeCode is idempotent on generated codes', () {
      final code = CloudSync.generateBackupCode();
      expect(CloudSync.normalizeCode(code), code);
      expect(CloudSync.normalizeCode(code.toLowerCase()), code);
    });
  });
}

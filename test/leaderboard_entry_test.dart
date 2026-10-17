import 'package:flutter_test/flutter_test.dart';
import 'package:raga/models/leaderboard_entry.dart';
import 'package:raga/screens/arena_screen.dart' show formatLeaderboardValue;

// M7: the arena board shows business-sensitive numbers — the % loss
// (server caps it at 3%/week anti-abuse), streaks, and opt-in state.
// These pin the entry parsing and the display formatting so a cap or
// label change can't slip through silently.

void main() {
  group('LeaderboardEntry.fromJson', () {
    test('parses a full row, trims the display name', () {
      final e = LeaderboardEntry.fromJson({
        'display_name': '  Wisnu  ',
        'avatar_url': 'https://x/y.png',
        'value': 2,
      });
      expect(e.displayName, 'Wisnu');
      expect(e.avatarUrl, 'https://x/y.png');
      expect(e.value, 2.0);
    });

    test('missing fields fall back to safe defaults', () {
      final e = LeaderboardEntry.fromJson({});
      expect(e.displayName, '');
      expect(e.avatarUrl, isNull);
      expect(e.value, 0.0);
    });

    test('null display name -> empty, never null', () {
      final e = LeaderboardEntry.fromJson({'display_name': null});
      expect(e.displayName, '');
    });
  });

  group('formatLeaderboardValue', () {
    test('% metric: one decimal + % sign', () {
      expect(formatLeaderboardValue(2.54, 0, 'id'), '2.5%');
      expect(formatLeaderboardValue(3.0, 0, 'en'), '3.0%');
      expect(formatLeaderboardValue(0.0, 0, 'id'), '0.0%');
    });

    test('streak metric: localized weeks, rounded', () {
      expect(formatLeaderboardValue(3, 1, 'id'), '3 minggu');
      expect(formatLeaderboardValue(1, 1, 'en'), '1 week');
      expect(formatLeaderboardValue(5, 1, 'en'), '5 weeks');
      expect(formatLeaderboardValue(2.6, 1, 'id'), '3 minggu');
    });
  });
}

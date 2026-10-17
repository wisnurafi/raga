import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raga/avatar/avatar_manifest.dart';
import 'package:raga/avatar/avatar_models.dart';
import 'package:raga/data/local_store.dart';

// Evidence I.7/I.9 (storage half): per-profile avatar persistence,
// isolation, deletion and corruption handling.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStore store;
  late AvatarManifest manifest;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.load();
    manifest = await AvatarManifest.load();
  });

  AvatarProfileState stateWithXp(String pid, int xp) {
    final ledger = [
      XpEvent(
          profileId: pid,
          type: 't',
          key: 'k',
          amount: xp,
          date: DateTime(2026, 10, 19)),
    ];
    return AvatarProfileState.initial(manifest)
        .copyWith(ledger: ledger, bestStreak: 5);
  }

  group('LocalStore avatar storage', () {
    test('roundtrip per profile', () async {
      final st = stateWithXp('p1', 123);
      await store.saveAvatarState('p1', st);
      final back = store.avatarState('p1')!;
      expect(back.totalXp, 123);
      expect(back.bestStreak, 5);
      expect(back.unlockedItemIds, st.unlockedItemIds);
      expect(back.config, st.config);
      expect(back.ledger.map((e) => e.uid), st.ledger.map((e) => e.uid));
    });

    test('missing profile returns null (caller migrates)', () async {
      expect(store.avatarState('nobody'), isNull);
    });

    test('profiles are isolated', () async {
      await store.saveAvatarState('a', stateWithXp('a', 100));
      await store.saveAvatarState('b', stateWithXp('b', 7));
      expect(store.avatarState('a')!.totalXp, 100);
      expect(store.avatarState('b')!.totalXp, 7);
      // Overwriting A leaves B alone.
      await store.saveAvatarState('a', stateWithXp('a', 101));
      expect(store.avatarState('b')!.totalXp, 7);
    });

    test('removeAvatarState deletes only that profile', () async {
      await store.saveAvatarState('a', stateWithXp('a', 100));
      await store.saveAvatarState('b', stateWithXp('b', 7));
      await store.removeAvatarState('a');
      expect(store.avatarState('a'), isNull);
      expect(store.avatarState('b')!.totalXp, 7);
      expect(store.avatarProfileIds, ['b']);
    });

    test('corrupt json returns null instead of crashing', () async {
      SharedPreferences.setMockInitialValues(
          {'raga.avatar.broken': 'not-json{{'});
      store = await LocalStore.load();
      expect(store.avatarState('broken'), isNull);
    });

    test('wrong schemaVersion returns null (caller migrates)', () async {
      await store.saveAvatarState('p1', stateWithXp('p1', 10));
      // Tamper the stored blob's version directly.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('raga.avatar.p1')!;
      final tampered =
          raw.replaceFirst('"schemaVersion":1', '"schemaVersion":999');
      expect(tampered, isNot(raw));
      await prefs.setString('raga.avatar.p1', tampered);
      expect(store.avatarState('p1'), isNull);
    });

    test('clearAll wipes avatar states', () async {
      await store.saveAvatarState('a', stateWithXp('a', 100));
      await store.clearAll();
      expect(store.avatarState('a'), isNull);
      expect(store.avatarProfileIds, isEmpty);
    });
  });

  group('avatar backup blob', () {
    test('avatarBlob roundtrips through json', () async {
      // The shape _saveBackupBlob puts under settings['avatar'].
      final blob = {
        'a': stateWithXp('a', 100).toJson(),
        'b': stateWithXp('b', 7).toJson(),
      };
      // Simulate the JSON trip through Supabase.
      final restored = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(blob)) as Map);
      final states = <String, AvatarProfileState>{};
      for (final e in restored.entries) {
        states[e.key] = AvatarProfileState.fromJson(
            Map<String, dynamic>.from(e.value as Map));
      }
      expect(states['a']!.totalXp, 100);
      expect(states['b']!.totalXp, 7);
      expect(states['a']!.unlockedItemIds,
          stateWithXp('a', 100).unlockedItemIds);
    });
  });
}

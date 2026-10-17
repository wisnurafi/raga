import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raga/data/local_store.dart';

// M9: corrupt local JSON used to vanish silently (fail-open). Now the raw
// payload is salvaged to a timestamped backup key, the incident is logged
// via the onCorrupt hook, and reads still return safe defaults.

void main() {
  setUp(() {
    LocalStore.onCorrupt = null;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    LocalStore.onCorrupt = null;
  });

  test('corrupt profiles JSON: salvaged, logged, default returned',
      () async {
    SharedPreferences.setMockInitialValues({'raga.profiles': '[[broken'});
    final logged = <String>[];
    LocalStore.onCorrupt = logged.add;

    final store = await LocalStore.load();
    expect(store.profiles, isEmpty);
    expect(logged.single, contains('raga.profiles'));

    final prefs = await SharedPreferences.getInstance();
    final salvageKeys = prefs
        .getKeys()
        .where((k) => k.startsWith('raga.profiles.corrupt.'));
    expect(salvageKeys.length, 1);
    expect(prefs.getString(salvageKeys.single), '[[broken');
  });

  test('corrupt records JSON: salvaged without losing the raw payload',
      () async {
    SharedPreferences.setMockInitialValues({'raga.records': '{oops'});
    LocalStore.onCorrupt = (_) {};
    final store = await LocalStore.load();
    expect(store.records, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    final salvageKeys = prefs
        .getKeys()
        .where((k) => k.startsWith('raga.records.corrupt.'));
    expect(salvageKeys.length, 1);
    expect(prefs.getString(salvageKeys.single), '{oops');
  });

  test('schema version is stamped on load', () async {
    await LocalStore.load();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('raga.schema_version'), 1);
  });

  test('valid JSON is untouched: no salvage key, no log', () async {
    SharedPreferences.setMockInitialValues({'raga.milestones_seen': '[1,2]'});
    final logged = <String>[];
    LocalStore.onCorrupt = logged.add;

    final store = await LocalStore.load();
    expect(store.milestonesSeen, [1, 2]);
    expect(logged, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.contains('.corrupt.')), isEmpty);
  });
}

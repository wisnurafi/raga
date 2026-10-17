import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';

// Evidence I.1: every asset path the manifest can produce must be bundled
// and loadable. rootBundle.load throws for a missing path — a loud
// failure here, never a silent fallback in the app.
//
// NOTE: the catalogue itself is the source of path truth. Flutter no
// longer bundles AssetManifest.json for tests, so this file deliberately
// does not look it up.

/// Preview renders shipped with the pack (not manifest-driven — the
/// manifest only describes composable layers).
const _compositeNames = [
  'bun-coral',
  'curly-amber',
  'frame-fire',
  'frame-leaf',
  'wavy-mint',
  'wisnu-default',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AvatarManifest manifest;
  setUpAll(() async {
    manifest = await AvatarManifest.load();
  });

  group('parsing', () {
    test('14 items in 4 categories', () {
      expect(manifest.totalItems, 14);
      expect(manifest.itemsIn('hair').map((e) => e.id),
          ['short', 'wavy', 'bun', 'curly']);
      expect(manifest.itemsIn('shirt').map((e) => e.id),
          ['lavender', 'mint', 'coral', 'amber', 'blue', 'pulse']);
      expect(
          manifest.itemsIn('accessory').map((e) => e.id),
          ['glasses', 'band']);
      expect(manifest.itemsIn('frame').map((e) => e.id), ['leaf', 'fire']);
    });

    test('defaults come from the manifest, not the code', () {
      final d = manifest.defaults;
      expect(d.skin, 'skin-2');
      expect(d.hair, 'short');
      expect(d.hairColor, 'navy');
      expect(d.shirt, 'lavender');
      expect(d.accessory, isNull);
      expect(d.frame, isNull);
    });

    test('layer order: 9 layers, frame drawn outside the clip last', () {
      expect(manifest.layerOrder, [
        '00_bg',
        '01_back-hair',
        '02_shirt',
        '03_neck',
        '04_head',
        '05_front-hair',
        '06_face',
        '07_accessory',
        '08_frame',
      ]);
    });

    test('known unlock requirements', () {
      AvatarUnlock unlocked(String id) => manifest.itemById(id).unlock!;
      expect(unlocked('curly').type, 'streak_days');
      expect(unlocked('curly').value, 7);
      expect(unlocked('coral').type, 'records_count');
      expect(unlocked('coral').value, 10);
      expect(unlocked('amber').type, 'level');
      expect(unlocked('amber').value, 8);
      expect(unlocked('blue').type, 'goal_reached');
      expect(unlocked('blue').value, isTrue);
      expect(unlocked('pulse').type, 'level');
      expect(unlocked('pulse').value, 10);
      expect(unlocked('fire').type, 'streak_days');
      expect(unlocked('fire').value, 30);
    });

    test('unlock null means open from the start', () {
      for (final id in [
        'short',
        'wavy',
        'bun',
        'lavender',
        'mint',
        'glasses',
        'band',
        'leaf'
      ]) {
        expect(manifest.itemById(id).unlock, isNull, reason: id);
      }
    });

    test('palettes', () {
      expect(manifest.palettes['skin']!.keys.toSet(),
          {'skin-1', 'skin-2', 'skin-3', 'skin-4'});
      expect(manifest.palettes['hairColor']!.keys.toSet(),
          {'navy', 'brown', 'black', 'blond'});
      expect(manifest.palettes['shirt']!.keys.toSet(),
          {'lavender', 'mint', 'coral', 'amber', 'blue', 'pulse'});
    });

    test('unknown item id throws', () {
      expect(() => manifest.itemById('nope'), throwsStateError);
    });
  });

  group('assets', () {
    test('every manifest asset path is bundled and loads', () async {
      final paths = <String>{
        'assets/avatar/${manifest.mask}',
        'assets/avatar/avatar_manifest.json',
        'assets/avatar/progression.json',
        'assets/avatar/layers/00_bg/bg.svg',
        'assets/avatar/layers/06_face/default.svg',
        for (final skin in manifest.palettes['skin']!.keys) ...[
          'assets/avatar/layers/03_neck/$skin.svg',
          'assets/avatar/layers/04_head/$skin.svg',
        ],
        for (final item in manifest.items)
          for (final p in item.allAssetPaths(manifest.palettes))
            'assets/avatar/layers/$p',
        for (final name in _compositeNames) ...[
          'assets/avatar/composites/$name.svg',
          'assets/avatar/composites/$name.png',
        ],
      };
      // Sanity: the catalogue really expands to dozens of files — a tiny
      // set would mean the template expansion silently broke.
      expect(paths.length, greaterThan(50));
      for (final p in paths) {
        // Throws on any missing/unreadable asset — loud, by design.
        await rootBundle.load(p);
      }
    });
  });
}

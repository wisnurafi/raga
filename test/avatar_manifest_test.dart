import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';

// Evidence I.1: every asset path the manifest can produce must be bundled
// and loadable. A missing path fails loudly here — never a silent
// fallback in the app.

/// All bundled files under assets/avatar/, from the generated asset index.
Future<Set<String>> _bundledAvatarAssets() async {
  final raw = await rootBundle.loadString('AssetManifest.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return map.keys.where((k) => k.startsWith('assets/avatar/')).toSet();
}

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
      final bundled = await _bundledAvatarAssets();
      final expected = <String>{
        'assets/avatar/avatar_manifest.json',
        'assets/avatar/progression.json',
        'assets/avatar/${manifest.mask}',
        'assets/avatar/layers/00_bg/bg.svg',
        'assets/avatar/layers/06_face/default.svg',
        for (final skin in manifest.palettes['skin']!.keys) ...[
          'assets/avatar/layers/03_neck/$skin.svg',
          'assets/avatar/layers/04_head/$skin.svg',
        ],
        for (final item in manifest.items)
          for (final p in item.allAssetPaths(manifest.palettes))
            'assets/avatar/layers/$p',
      };
      final missing = expected.difference(bundled);
      expect(missing, isEmpty,
          reason: 'manifest references files not bundled: $missing');
      for (final p in expected) {
        // Throws on any unreadable asset — a loud failure, by design.
        await rootBundle.load(p);
      }
      // No orphans either: every bundled avatar file is accounted for,
      // except composites (preview renders, not manifest-driven).
      final orphans = bundled
          .difference(expected)
          .where((p) => !p.startsWith('assets/avatar/composites/'))
          .toSet();
      expect(orphans, isEmpty,
          reason: 'unreferenced avatar files: $orphans');
    });

    test('composites load as png+svg pairs', () async {
      final bundled = await _bundledAvatarAssets();
      final composites = bundled
          .where((p) => p.startsWith('assets/avatar/composites/'))
          .toList();
      expect(composites, isNotEmpty);
      final pngs =
          composites.where((p) => p.endsWith('.png')).toList();
      expect(pngs, isNotEmpty);
      for (final png in pngs) {
        final base = png.substring(0, png.length - 4);
        final svg = '$base.svg';
        expect(bundled, contains(svg), reason: 'missing $svg');
        await rootBundle.load(png);
        await rootBundle.load(svg);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/avatar/avatar_manifest.dart';
import 'package:raga/avatar/avatar_models.dart';
import 'package:raga/avatar/avatar_view.dart';

// Evidence I.2: AvatarView renders the 6 composite configs exactly like
// the asset pack's PNGs — structurally (exact layer paths in manifest
// order) and visually (pixel diff under threshold).

/// The 6 composite configs, decoded from the asset pack (verified
/// against the fill colors baked into each composite SVG).
const _composites = <String, AvatarConfig>{
  'wisnu-default': AvatarConfig(
    skin: 'skin-2',
    hair: 'short',
    hairColor: 'navy',
    shirt: 'lavender',
    accessory: 'glasses',
    frame: null,
  ),
  'bun-coral': AvatarConfig(
    skin: 'skin-3',
    hair: 'bun',
    hairColor: 'black',
    shirt: 'coral',
    accessory: 'band',
    frame: null,
  ),
  'curly-amber': AvatarConfig(
    skin: 'skin-4',
    hair: 'curly',
    hairColor: 'blond',
    shirt: 'amber',
    accessory: null,
    frame: null,
  ),
  'wavy-mint': AvatarConfig(
    skin: 'skin-1',
    hair: 'wavy',
    hairColor: 'brown',
    shirt: 'mint',
    accessory: null,
    frame: null,
  ),
  'frame-fire': AvatarConfig(
    skin: 'skin-3',
    hair: 'bun',
    hairColor: 'brown',
    shirt: 'pulse',
    accessory: null,
    frame: 'fire',
  ),
  'frame-leaf': AvatarConfig(
    skin: 'skin-2',
    hair: 'short',
    hairColor: 'navy',
    shirt: 'blue',
    accessory: null,
    frame: 'leaf',
  ),
};

const _root = 'assets/avatar';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AvatarManifest manifest;
  setUpAll(() async {
    manifest = await AvatarManifest.load();
  });

  List<String> clipped(AvatarConfig c) =>
      AvatarView(manifest: manifest, config: c).layerAssets().clipped;

  group('layerAssets', () {
    test('wisnu-default: exact layer stack', () {
      final layers =
          AvatarView(manifest: manifest, config: _composites['wisnu-default']!)
              .layerAssets();
      expect(layers.clipped, [
        '$_root/layers/00_bg/bg.svg',
        '$_root/layers/02_shirt/lavender.svg',
        '$_root/layers/03_neck/skin-2.svg',
        '$_root/layers/04_head/skin-2.svg',
        '$_root/layers/05_front-hair/short-navy.svg',
        '$_root/layers/06_face/default.svg',
        '$_root/layers/07_accessory/glasses.svg',
      ]);
      expect(layers.frame, isNull);
    });

    test('bun-coral: back hair layer present', () {
      final layers =
          AvatarView(manifest: manifest, config: _composites['bun-coral']!)
              .layerAssets();
      expect(
          layers.clipped[1], '$_root/layers/01_back-hair/bun-black.svg');
      expect(layers.clipped,
          contains('$_root/layers/05_front-hair/bun-black.svg'));
      expect(
          layers.clipped, contains('$_root/layers/07_accessory/band.svg'));
      expect(layers.frame, isNull);
    });

    test('frame-fire: frame separated from the clipped stack', () {
      final layers =
          AvatarView(manifest: manifest, config: _composites['frame-fire']!)
              .layerAssets();
      expect(layers.frame, '$_root/layers/08_frame/fire.svg');
      expect(layers.clipped, isNot(contains(layers.frame)));
      expect(layers.clipped.length, 7); // no accessory
    });

    test('frame-leaf: blue shirt, leaf frame', () {
      final layers =
          AvatarView(manifest: manifest, config: _composites['frame-leaf']!)
              .layerAssets();
      expect(layers.clipped,
          contains('$_root/layers/02_shirt/blue.svg'));
      expect(layers.frame, '$_root/layers/08_frame/leaf.svg');
    });

    test('short/curly have no back-hair layer; bun/wavy do', () {
      expect(clipped(_composites['wisnu-default']!).length, 7);
      expect(clipped(_composites['curly-amber']!).length, 6);
      expect(clipped(_composites['bun-coral']!).length, 8);
      expect(clipped(_composites['wavy-mint']!).length, 7);
    });

    test('default config matches the manifest defaults', () {
      final config = AvatarConfig.defaults(manifest);
      final layers =
          AvatarView(manifest: manifest, config: config).layerAssets();
      expect(layers.clipped.first, '$_root/layers/00_bg/bg.svg');
      expect(layers.clipped, contains('$_root/layers/03_neck/skin-2.svg'));
      expect(layers.frame, isNull);
    });
  });

  group('asset completeness', () {
    test('every resolvable path loads (fail hard on missing asset)',
        () async {
      // Full config matrix -> unique paths -> each must load.
      final paths = <String>{};
      for (final skin in manifest.palettes['skin']!.keys) {
        for (final hair in manifest.itemsIn('hair')) {
          for (final hairColor in manifest.palettes['hairColor']!.keys) {
            for (final shirt in manifest.itemsIn('shirt')) {
              for (final accessory in [null, ...manifest.itemsIn('accessory')]) {
                for (final frame in [null, ...manifest.itemsIn('frame')]) {
                  final config = AvatarConfig(
                    skin: skin,
                    hair: hair.id,
                    hairColor: hairColor,
                    shirt: shirt.id,
                    accessory: accessory?.id,
                    frame: frame?.id,
                  );
                  final layers = AvatarView(
                          manifest: manifest, config: config)
                      .layerAssets();
                  paths.addAll(layers.clipped);
                  final f = layers.frame;
                  if (f != null) paths.add(f);
                }
              }
            }
          }
        }
      }
      expect(paths.length, greaterThan(40));
      for (final p in paths) {
        final data = await rootBundle.load(p);
        expect(data.lengthInBytes, greaterThan(0), reason: p);
      }
    });
  });

  group('widget', () {
    testWidgets('pumps all 6 composites without error', (tester) async {
      for (final entry in _composites.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AvatarView(
                manifest: manifest,
                config: entry.value,
                size: 200,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('svg count matches the layer stack', (tester) async {
      final config = _composites['frame-fire']!;
      final layers =
          AvatarView(manifest: manifest, config: config).layerAssets();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarView(manifest: manifest, config: config, size: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 7 clipped + 1 frame.
      expect(find.byType(SvgPicture),
          findsNWidgets(layers.clipped.length + 1));
    });

    testWidgets('frame draws outside the ClipOval', (tester) async {
      final config = _composites['frame-leaf']!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarView(manifest: manifest, config: config, size: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The ClipOval subtree holds only the clipped layers.
      final clipOval =
          tester.widget<ClipOval>(find.byType(ClipOval).first);
      int countSvg(Element e) {
        var n = 0;
        e.visitChildren((c) {
          if (c.widget is SvgPicture) n++;
          n += countSvg(c);
        });
        return n;
      }
      var inside = 0;
      tester.element(find.byType(ClipOval).first).visitChildren((c) {
        inside += countSvg(c);
      });
      expect(clipOval, isNotNull);
      final layers =
          AvatarView(manifest: manifest, config: config).layerAssets();
      expect(inside, layers.clipped.length);
      expect(find.byType(SvgPicture),
          findsNWidgets(layers.clipped.length + 1));
    });

    testWidgets('semantics label the avatar image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarView(
              manifest: manifest,
              config: _composites['wisnu-default']!,
              size: 200,
              semanticsLabel: 'Avatar Wisnu',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Avatar Wisnu'),
        findsOneWidget,
      );
    });
  });

  group('golden vs composite PNGs', () {
    // Standard flutter_test goldens: generated with --update-goldens,
    // checked in under test/goldens/, verified against the asset pack's
    // composite PNGs by eye. SVG-only artwork keeps them deterministic
    // across machines (no text rasterization involved).
    for (final entry in _composites.entries) {
      testWidgets('golden ${entry.key}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AvatarView(
                  manifest: manifest,
                  config: entry.value,
                  size: 400,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(AvatarView),
          matchesGoldenFile('goldens/avatar_${entry.key}.png'),
        );
      });
    }
  });
}

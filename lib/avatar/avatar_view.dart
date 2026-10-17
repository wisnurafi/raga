import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'avatar_manifest.dart';
import 'avatar_models.dart';

// Renders one avatar by stacking the asset pack's SVG layers
// (assets/avatar/README.md):
// - layers 00_bg .. 07_accessory draw INSIDE a circular clip,
//   ordered by manifest.layerOrder;
// - the frame layer draws OUTSIDE the clip, on top.
//
// The catalogue (items, palettes, defaults, layer order, unlocks) comes
// from the manifest; item layers are placed by the layer directory in
// their asset path, so new items never need widget changes. The four
// skeleton layers below are the pack's fixed base — the asset test
// fails loudly if any of them goes missing.
class AvatarView extends StatelessWidget {
  final AvatarManifest manifest;
  final AvatarConfig config;
  final double size;

  /// Accessibility label for the avatar image.
  final String? semanticsLabel;

  const AvatarView({
    super.key,
    required this.manifest,
    required this.config,
    this.size = 160,
    this.semanticsLabel,
  });

  static const _assetRoot = 'assets/avatar';

  /// Skeleton layers: pack contract, not catalogue items.
  Map<String, String> _baseLayers() => {
        '00_bg': '$_assetRoot/layers/00_bg/bg.svg',
        '03_neck': '$_assetRoot/layers/03_neck/${config.skin}.svg',
        '04_head': '$_assetRoot/layers/04_head/${config.skin}.svg',
        '06_face': '$_assetRoot/layers/06_face/default.svg',
      };

  /// Layer directory of the selected frame item (null when no frame).
  /// The frame is the only layer drawn outside the circular clip.
  String? get _frameLayerDir {
    final frameId = config.frame;
    if (frameId == null) return null;
    for (final t in manifest.itemById(frameId).assetTemplates) {
      if (t != null) return t.split('/').first;
    }
    return null;
  }

  /// Every layer asset path for [config], in manifest.layerOrder.
  /// The frame is returned separately: it draws outside the clip.
  ({List<String> clipped, String? frame}) layerAssets() {
    final byLayer = _baseLayers();
    void addItem(String? itemId) {
      if (itemId == null) return;
      for (final t in manifest
          .itemById(itemId)
          .resolveAssets(config.templateVars)) {
        if (t == null) continue;
        byLayer[t.split('/').first] = '$_assetRoot/layers/$t';
      }
    }

    addItem(config.hair);
    addItem(config.shirt);
    addItem(config.accessory);
    addItem(config.frame);

    final frameDir = _frameLayerDir;
    final clipped = <String>[];
    String? frame;
    for (final layer in manifest.layerOrder) {
      final path = byLayer[layer];
      if (path == null) continue;
      if (layer == frameDir) {
        frame = path;
      } else {
        clipped.add(path);
      }
    }
    return (clipped: clipped, frame: frame);
  }

  @override
  Widget build(BuildContext context) {
    final layers = layerAssets();
    // A missing asset surfaces as a FlutterError (fail hard) — there is
    // deliberately no silent fallback widget. The asset test below
    // guards every resolvable path in CI.
    Widget picture(String path) => SvgPicture.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            ClipOval(
              child: Stack(
                children: [
                  for (final p in layers.clipped) picture(p),
                ],
              ),
            ),
            if (layers.frame != null) picture(layers.frame!),
          ],
        ),
      ),
    );
  }
}

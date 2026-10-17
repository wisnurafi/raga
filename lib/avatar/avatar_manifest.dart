import 'dart:convert';

import 'package:flutter/services.dart';

// Parsed form of assets/avatar/avatar_manifest.json — the single source of
// truth for avatar items, palettes, defaults, layer order and unlock
// requirements. The UI and the progress service only ever read from here;
// nothing about the avatar catalogue is hardcoded in Dart.

/// Unlock condition types, as they appear in the manifest.
abstract class UnlockType {
  static const level = 'level';
  static const streakDays = 'streak_days';
  static const recordsCount = 'records_count';
  static const goalReached = 'goal_reached';

  static const all = [level, streakDays, recordsCount, goalReached];
}

/// Item categories, as they appear in the manifest.
abstract class AvatarCategory {
  static const hair = 'hair';
  static const shirt = 'shirt';
  static const accessory = 'accessory';
  static const frame = 'frame';
}

/// One unlock requirement. Null [AvatarItem.unlock] means open from start.
class AvatarUnlock {
  final String type;
  final dynamic value; // int for level/streak_days/records_count, bool for goal_reached

  const AvatarUnlock({required this.type, required this.value});

  factory AvatarUnlock.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    if (type == null || !UnlockType.all.contains(type)) {
      throw FormatException('Avatar manifest: unknown unlock type "$type"');
    }
    final value = j['value'];
    if (type == UnlockType.goalReached) {
      if (value is! bool) {
        throw FormatException(
            'Avatar manifest: goal_reached unlock needs a bool value');
      }
    } else if (value is! int) {
      throw FormatException(
          'Avatar manifest: "$type" unlock needs an int value');
    }
    return AvatarUnlock(type: type, value: value);
  }
}

/// One catalogue item (a hair style, a shirt, an accessory, a frame).
///
/// [assetTemplates] holds the layer asset paths with `{var}` placeholders
/// (e.g. `05_front-hair/short-{hairColor}.svg`). For hair items the list is
/// `[backHair?, frontHair]` where the back entry may be null (short hair
/// has no back layer); other categories carry a single entry. The layer
/// directory inside each path decides where it is drawn, following
/// [AvatarManifest.layerOrder].
class AvatarItem {
  final String id;
  final String category;
  final String name;
  final List<String?> assetTemplates;
  final AvatarUnlock? unlock;

  const AvatarItem({
    required this.id,
    required this.category,
    required this.name,
    required this.assetTemplates,
    required this.unlock,
  });

  factory AvatarItem.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String?;
    final category = j['category'] as String?;
    final name = j['name'] as String?;
    final asset = j['asset'];
    if (id == null || id.isEmpty) {
      throw const FormatException('Avatar manifest: item without id');
    }
    if (category == null || category.isEmpty) {
      throw FormatException('Avatar manifest: item "$id" without category');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('Avatar manifest: item "$id" without name');
    }
    if (asset is! List) {
      throw FormatException('Avatar manifest: item "$id" without asset list');
    }
    final unlockJson = j['unlock'];
    return AvatarItem(
      id: id,
      category: category,
      name: name,
      assetTemplates:
          asset.map((e) => e == null ? null : e as String).toList(),
      unlock: unlockJson == null
          ? null
          : AvatarUnlock.fromJson(
              unlockJson as Map<String, dynamic>),
    );
  }

  /// Concrete asset paths for one configuration, e.g. `{hairColor: navy}`.
  /// Null entries stay null. Throws when a placeholder has no value —
  /// a missing asset must fail loudly, never fall back silently.
  List<String?> resolveAssets(Map<String, String> vars) {
    final out = <String?>[];
    for (final t in assetTemplates) {
      if (t == null) {
        out.add(null);
        continue;
      }
      var r = t;
      for (final e in vars.entries) {
        r = r.replaceAll('{${e.key}}', e.value);
      }
      if (RegExp(r'\{\w+\}').hasMatch(r)) {
        throw StateError('Avatar manifest: unresolved template "$t" '
            'for item "$id" (vars: $vars)');
      }
      out.add(r);
    }
    return out;
  }

  /// Every concrete path this item can produce, expanding each `{var}`
  /// over the matching palette. Used by the asset-completeness test.
  List<String> allAssetPaths(
      Map<String, Map<String, String>> palettes) {
    final paths = <String>{};
    for (final t in assetTemplates) {
      if (t == null) continue;
      paths.addAll(_expand(t, palettes, id));
    }
    return paths.toList();
  }

  static List<String> _expand(String template,
      Map<String, Map<String, String>> palettes, String itemId) {
    final varNames = RegExp(r'\{(\w+)\}')
        .allMatches(template)
        .map((m) => m.group(1)!)
        .toList();
    if (varNames.isEmpty) return [template];
    var results = [template];
    for (final v in varNames) {
      final values = palettes[v]?.keys.toList() ?? const <String>[];
      if (values.isEmpty) {
        throw StateError('Avatar manifest: no palette "$v" to expand '
            'template "$template" of item "$itemId"');
      }
      results = [
        for (final r in results)
          for (final val in values) r.replaceFirst('{$v}', val),
      ];
    }
    return results;
  }
}

class AvatarDefaults {
  final String skin;
  final String hair;
  final String hairColor;
  final String shirt;
  final String? accessory;
  final String? frame;

  const AvatarDefaults({
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.shirt,
    required this.accessory,
    required this.frame,
  });

  factory AvatarDefaults.fromJson(Map<String, dynamic> j) {
    String req(String key) {
      final v = j[key] as String?;
      if (v == null || v.isEmpty) {
        throw FormatException(
            'Avatar manifest: defaults missing "$key"');
      }
      return v;
    }

    return AvatarDefaults(
      skin: req('skin'),
      hair: req('hair'),
      hairColor: req('hairColor'),
      shirt: req('shirt'),
      accessory: j['accessory'] as String?,
      frame: j['frame'] as String?,
    );
  }
}

class AvatarManifest {
  static const assetPath = 'assets/avatar/avatar_manifest.json';

  final int version;
  final int canvas;
  final String mask;
  final List<String> layerOrder;
  final AvatarDefaults defaults;
  final Map<String, Map<String, String>> palettes;
  final List<AvatarItem> items;

  const AvatarManifest({
    required this.version,
    required this.canvas,
    required this.mask,
    required this.layerOrder,
    required this.defaults,
    required this.palettes,
    required this.items,
  });

  factory AvatarManifest.fromJson(Map<String, dynamic> j) {
    final itemsJson = j['items'];
    final orderJson = j['layerOrder'];
    final palettesJson = j['palettes'];
    if (itemsJson is! List || itemsJson.isEmpty) {
      throw const FormatException(
          'Avatar manifest: "items" must be a non-empty list');
    }
    if (orderJson is! List || orderJson.isEmpty) {
      throw const FormatException(
          'Avatar manifest: "layerOrder" must be a non-empty list');
    }
    if (palettesJson is! Map) {
      throw const FormatException(
          'Avatar manifest: "palettes" must be a map');
    }
    final items = itemsJson
        .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final ids = items.map((e) => e.id).toSet();
    if (ids.length != items.length) {
      throw const FormatException(
          'Avatar manifest: duplicate item id');
    }
    return AvatarManifest(
      version: (j['version'] as num?)?.toInt() ?? 1,
      canvas: (j['canvas'] as num?)?.toInt() ?? 200,
      mask: j['mask'] as String? ?? 'mask/circle.svg',
      layerOrder: orderJson.map((e) => e as String).toList(),
      defaults: AvatarDefaults.fromJson(
          j['defaults'] as Map<String, dynamic>),
      palettes: (palettesJson as Map).map((k, v) => MapEntry(
          k as String,
          (v as Map)
              .map((pk, pv) => MapEntry(pk as String, pv as String)))),
      items: items,
    );
  }

  /// Loads and parses the manifest. Throws on any problem — a broken
  /// catalogue must never silently degrade into a wrong avatar.
  static Future<AvatarManifest> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final raw = await b.loadString(assetPath);
    return AvatarManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  AvatarItem itemById(String id) => items.firstWhere(
        (e) => e.id == id,
        orElse: () =>
            throw StateError('Avatar manifest: unknown item id "$id"'),
      );

  List<AvatarItem> itemsIn(String category) =>
      items.where((e) => e.category == category).toList();

  int get totalItems => items.length;
}

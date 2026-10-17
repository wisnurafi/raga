import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

// Parsed form of assets/avatar/progression.json — the ONLY place that
// holds progression numbers (level curve, titles, XP awards, streak
// milestones). Rebalance the economy by editing that file; no code
// change needed.

class LevelTitle {
  final int min;
  final int max;
  final String title;

  const LevelTitle({
    required this.min,
    required this.max,
    required this.title,
  });

  factory LevelTitle.fromJson(Map<String, dynamic> j) => LevelTitle(
        min: (j['min'] as num).toInt(),
        max: (j['max'] as num).toInt(),
        title: j['title'] as String,
      );
}

class ProgressionConfig {
  static const assetPath = 'assets/avatar/progression.json';

  final int version;
  final int maxLevel;

  /// XP needed to go from level n to level n+1, at index n-1.
  /// Length must be maxLevel - 1.
  final List<int> levelThresholds;
  final List<LevelTitle> titles;
  final Map<String, int> xpAwards;
  final List<int> streakMilestones;

  const ProgressionConfig({
    required this.version,
    required this.maxLevel,
    required this.levelThresholds,
    required this.titles,
    required this.xpAwards,
    required this.streakMilestones,
  });

  factory ProgressionConfig.fromJson(Map<String, dynamic> j) {
    final maxLevel = (j['maxLevel'] as num?)?.toInt() ?? 20;
    final thresholds = ((j['levelThresholds'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    if (thresholds.length != maxLevel - 1) {
      throw FormatException('progression.json: levelThresholds must hold '
          'maxLevel - 1 entries (got ${thresholds.length} for maxLevel '
          '$maxLevel)');
    }
    if (thresholds.any((e) => e <= 0)) {
      throw const FormatException(
          'progression.json: levelThresholds must all be positive');
    }
    final titles = ((j['levelTitles'] as List?) ?? const [])
        .map((e) => LevelTitle.fromJson(e as Map<String, dynamic>))
        .toList();
    if (titles.isEmpty) {
      throw const FormatException(
          'progression.json: levelTitles must not be empty');
    }
    final awards = ((j['xpAwards'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()));
    if (awards.values.any((e) => e < 0)) {
      throw const FormatException(
          'progression.json: xpAwards must not be negative');
    }
    return ProgressionConfig(
      version: (j['version'] as num?)?.toInt() ?? 1,
      maxLevel: maxLevel,
      levelThresholds: thresholds,
      titles: titles,
      xpAwards: awards,
      streakMilestones: ((j['streakMilestones'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }

  static Future<ProgressionConfig> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final raw = await b.loadString(assetPath);
    return ProgressionConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Total XP ever earned to REACH [level] (level 1 needs 0).
  int xpForLevel(int level) {
    var total = 0;
    final n = level.clamp(1, maxLevel) - 1;
    for (var i = 0; i < n; i++) {
      total += levelThresholds[i];
    }
    return total;
  }

  /// Level for a lifetime XP total. Caps at [maxLevel].
  int levelForXp(int xp) {
    if (xp < 0) return 1;
    var level = 1;
    var cumulative = 0;
    for (final t in levelThresholds) {
      if (xp < cumulative + t) break;
      cumulative += t;
      level++;
      if (level >= maxLevel) return maxLevel;
    }
    return level;
  }

  /// XP earned inside the current [level] (0 at the exact boundary).
  int xpIntoLevel(int xp, int level) =>
      math.max(0, xp - xpForLevel(level));

  /// XP still needed to leave [level]; 0 when already maxed.
  int xpToNextLevel(int level) =>
      level >= maxLevel ? 0 : levelThresholds[(level - 1).clamp(0, maxLevel - 2)];

  String titleFor(int level) {
    for (final t in titles) {
      if (level >= t.min && level <= t.max) return t.title;
    }
    return titles.last.title;
  }

  /// XP amount for an award type (e.g. 'daily_record'). Throws on
  /// unknown types — a typo must fail loudly, not grant 0 silently.
  int award(String type) {
    final v = xpAwards[type];
    if (v == null) {
      throw StateError('progression.json: unknown xp award "$type"');
    }
    return v;
  }
}

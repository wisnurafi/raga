/// Asset map + domain enums for the Detak companion.
///
/// Runtime sprites (pre-generated and committed) live in
/// `assets/images/detak/` and composed as Stack[body, sprout, accessory].
library;

/// Detak's mood. Also selects the facial expression sprite.
enum DetakMood { halo, senang, semangat, ngantuk, dukung, bangga }

/// Body color variants.
enum DetakColor { lavender, langit, mint, persik }

/// Accessories. [none] renders no overlay layer.
enum DetakAccessory { none, kacamata, pita }

/// Growth stage, derived from the closeness level:
/// Kuncup (Lv 1-2) -> Dua daun (Lv 3-4) -> Rimbun (Lv 5-7) -> Berbunga (Lv 8+).
enum DetakStage { kuncup, duaDaun, rimbun, berbunga }

DetakStage detakStageForLevel(int level) {
  if (level <= 2) return DetakStage.kuncup;
  if (level <= 4) return DetakStage.duaDaun;
  if (level <= 7) return DetakStage.rimbun;
  return DetakStage.berbunga;
}

/// XP needed to advance from [level] to [level + 1]: L^2 + 4.
/// Lv1->2 = 5, Lv2->3 = 8, Lv3->4 = 13, Lv4->5 = 20, ...
int detakXpForLevel(int level) => level * level + 4;

/// Total XP earned across the whole journey: everything banked in the
/// levels below [level], plus [xpInLevel] in the current one.
int detakTotalXp(int level, int xpInLevel) {
  var total = xpInLevel;
  for (var l = 1; l < level; l++) {
    total += detakXpForLevel(l);
  }
  return total;
}

/// Sprite path helpers. All sprites are 512x512 RGBA PNGs.
class DetakAssets {
  DetakAssets._();

  static String body(DetakMood mood, DetakColor color) =>
      'assets/images/detak/detak_${mood.name}_${color.name}.png';

  static String sprout(DetakStage stage) =>
      'assets/images/detak/detak_tunas_${stage.index + 1}.png';

  static String? accessory(DetakAccessory a) {
    switch (a) {
      case DetakAccessory.kacamata:
        return 'assets/images/detak/detak_acc_kacamata.png';
      case DetakAccessory.pita:
        return 'assets/images/detak/detak_acc_pita.png';
      case DetakAccessory.none:
        return null;
    }
  }

  /// Gauge needle pivot, as a fraction of the sprite size.
  /// Calibrated by the (now removed) tools/detak_build.py (kNeedlePivot) — keep in sync.
  static const double needlePivotX = 0.4995;
  static const double needlePivotY = 0.7944;
}

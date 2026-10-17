import 'package:flutter/widgets.dart';

import '../core/strings.dart';
import 'avatar_manifest.dart';

/// Human-readable requirement for a locked item, e.g. "Level 8",
/// "Streak 30 hari", "Catat 10+". The requirement itself comes from the
/// manifest; only the phrasing is localized here.
String unlockRequirementText(BuildContext context, AvatarUnlock unlock) {
  switch (unlock.type) {
    case UnlockType.level:
      return tx(context, 'avatar_unlock_level', {'n': unlock.value});
    case UnlockType.streakDays:
      return tx(context, 'avatar_unlock_streak', {'n': unlock.value});
    case UnlockType.recordsCount:
      return tx(context, 'avatar_unlock_records', {'n': unlock.value});
    case UnlockType.goalReached:
      return tx(context, 'avatar_unlock_goal');
    default:
      return '';
  }
}

/// Current progress toward [unlock] as (have, need) — e.g. "5 / 7 hari".
/// Null for goal_reached (boolean) and unknown types.
({int have, int need})? unlockProgress(
  AvatarUnlock unlock, {
  required int level,
  required int bestStreak,
  required int records,
}) {
  switch (unlock.type) {
    case UnlockType.level:
      return (have: level, need: unlock.value as int);
    case UnlockType.streakDays:
      return (have: bestStreak, need: unlock.value as int);
    case UnlockType.recordsCount:
      return (have: records, need: unlock.value as int);
    default:
      return null;
  }
}

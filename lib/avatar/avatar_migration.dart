import '../models/bmi_record.dart';
import 'avatar_models.dart';
import 'avatar_progress.dart';

// Rebuilds one profile's avatar state from its record history. Used for
// profiles that predate the avatar feature and for cloud restores whose
// blob has no (or corrupt) avatar data. Pure: no storage, no clock —
// the caller persists the result.
//
// Rules (spec D):
// - default config; XP and unlocks recomputed from [history];
// - history replays oldest-first through onRecordSaved; backdated
//   records earn no daily_record XP (spec E) but rebuild streaks,
//   records_count and unlocks;
// - profile_setup_complete is granted; an existing goal grants goal_set
//   once (baseline = latest weight) but never goal_reached — that fires
//   naturally on the next qualifying weigh-in;
// - everything unlocked by the migration is pre-marked seen, so the UI
//   never floods the user with notifications for old progress.
AvatarProfileState migrateAvatarState({
  required AvatarProgressService service,
  required String profileId,
  required List<BmiRecord> history,
  required double? goalKg,
  required bool hasWeighSchedule,
  required List<int> scheduleWeekdays,
}) {
  var state = AvatarProfileState.initial(service.manifest);
  final sorted = history.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final seen = <BmiRecord>[];
  for (final r in sorted) {
    seen.add(r);
    state = service
        .onRecordSaved(
          profileId: profileId,
          recordDate: r.createdAt,
          history: seen,
          state: state,
          hasWeighSchedule: hasWeighSchedule,
          scheduleWeekdays: scheduleWeekdays,
        )
        .nextState;
  }
  state =
      service.onProfileCreated(profileId: profileId, state: state).nextState;
  if (goalKg != null) {
    final baseline = sorted.isEmpty ? null : sorted.last.weightKg;
    state = service
        .onGoalSet(
          profileId: profileId,
          targetKg: goalKg,
          baselineKg: baseline,
          state: state,
        )
        .nextState;
  }
  return state.copyWith(unlockSeenIds: Set.of(state.unlockedItemIds));
}

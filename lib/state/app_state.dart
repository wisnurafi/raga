import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../models/profile.dart';
import '../models/bmi_record.dart';

// App-wide state. Kept simple on purpose: ChangeNotifier +
// InheritedNotifier, no extra dependencies.
class AppState extends ChangeNotifier {
  final LocalStore _store;

  // Grab the state from anywhere in the widget tree.
  static AppState of(BuildContext context) => AppStateScope.of(context);

  List<Profile> profiles = [];
  String activeProfileId = '';
  List<BmiRecord> records = [];
  bool metricUnits = true;
  String activity = 'Light';
  bool weeklyReminder = false;
  List<int> reminderWeekdays = [7];
  int reminderHour = 9;
  int reminderMinute = 0;
  bool darkMode = true;
  Map<String, double> goalWeights = {};
  bool devMode = false;
  bool onboardingDone = false;
  List<int> milestonesSeen = [];

  AppState(this._store);

  static Future<AppState> load() async {
    final store = await LocalStore.load();
    final state = AppState(store);
    state.profiles = store.profiles;
    state.records = store.records;
    state.metricUnits = store.metricUnits;
    state.activity = store.activity;
    state.weeklyReminder = store.weeklyReminder;
    state.reminderWeekdays = store.reminderWeekdays;
    state.reminderHour = store.reminderHour;
    state.reminderMinute = store.reminderMinute;
    state.darkMode = store.darkMode;
    state.goalWeights = store.goalWeights;
    state.devMode = store.devMode;
    state.onboardingDone = store.onboardingDone;
    state.milestonesSeen = store.milestonesSeen;
    if (state.profiles.isEmpty) {
      final p = Profile(name: 'You');
      state.profiles = [p];
      await store.saveProfiles(state.profiles);
    }
    state.activeProfileId =
        store.activeProfileId ?? state.profiles.first.id;
    if (!state.profiles.any((p) => p.id == state.activeProfileId)) {
      state.activeProfileId = state.profiles.first.id;
    }
    return state;
  }

  Profile get activeProfile => profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => profiles.first,
      );

  List<BmiRecord> recordsOf(String profileId) =>
      records.where((r) => r.profileId == profileId).toList();

  Future<void> setActiveProfile(String id) async {
    activeProfileId = id;
    await _store.saveActiveProfileId(id);
    notifyListeners();
  }

  Future<void> addProfile(String name) async {
    final p = Profile(name: name.trim().isEmpty ? 'Profile' : name.trim());
    profiles = [...profiles, p];
    await _store.saveProfiles(profiles);
    await setActiveProfile(p.id);
    await _saveBackupBlob();
  }

  Future<void> updateActiveProfile(Profile Function(Profile) fn) async {
    profiles = profiles
        .map((p) => p.id == activeProfileId ? fn(p) : p)
        .toList();
    await _store.saveProfiles(profiles);
    notifyListeners();
  }

  Future<void> removeProfile(String id) async {
    if (profiles.length <= 1) return;
    profiles = profiles.where((p) => p.id != id).toList();
    records = records.where((r) => r.profileId != id).toList();
    await _store.saveProfiles(profiles);
    await _store.saveRecords(records);
    if (activeProfileId == id) {
      await setActiveProfile(profiles.first.id);
    } else {
      notifyListeners();
    }
    await _saveBackupBlob();
  }

  // Save a result to history (local first, cloud when available).
  Future<void> saveRecord({
    required double heightCm,
    required double weightKg,
  }) async {
    final r = BmiRecord(
      profileId: activeProfileId,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    records = [r, ...records];
    await _store.saveRecords(records);
    notifyListeners();
    // Cloud backup runs in the background; check its status in Profile.
    // (No second notify: the push and the blob RPC don't change any
    // AppState field, so there's nothing new to broadcast.)
    await CloudSync.pushRecord(r);
    await _saveBackupBlob();
  }

  Future<void> setMetricUnits(bool v) async {
    metricUnits = v;
    await _store.saveMetricUnits(v);
    notifyListeners();
  }

  // Retry pending uploads, then refresh the UI.
  Future<void> refreshSync() async {
    await CloudSync.syncPending(records);
    await _saveBackupBlob();
    notifyListeners();
  }

  Future<void> setActivity(String v) async {
    activity = v;
    await _store.saveActivity(v);
    notifyListeners();
  }

  double? goalFor(String profileId) => goalWeights[profileId];

  Future<void> setGoalWeight(String profileId, double? kg) async {
    goalWeights = {...goalWeights};
    if (kg == null) {
      goalWeights.remove(profileId);
    } else {
      goalWeights[profileId] = kg;
    }
    await _store.saveGoalWeight(profileId, kg);
    await _saveBackupBlob();
    notifyListeners();
  }

  Future<void> setWeeklyReminder(bool v) async {
    weeklyReminder = v;
    await _store.saveWeeklyReminder(v);
    notifyListeners();
  }

  Future<void> setReminderSchedule({
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) async {
    reminderWeekdays = weekdays.toSet().toList()..sort();
    if (reminderWeekdays.isEmpty) reminderWeekdays = [7];
    reminderHour = hour;
    reminderMinute = minute;
    await _store.saveReminderWeekdays(reminderWeekdays);
    await _store.saveReminderSchedule(
        weekday: reminderWeekdays.first, hour: hour, minute: minute);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    darkMode = v;
    await _store.saveDarkMode(v);
    notifyListeners();
  }

  Future<void> setDevMode(bool v) async {
    devMode = v;
    await _store.saveDevMode(v);
    notifyListeners();
  }

  // First-launch setup: replaces any auto-created placeholder profile
  // with the real one, applies the goal, and marks onboarding done.
  Future<void> completeOnboarding({
    required String name,
    required bool isMale,
    required int age,
    required double heightCm,
    required double weightKg,
    double? goalKg,
  }) async {
    final p = Profile(
      name: name,
      isMale: isMale,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    profiles = [p];
    activeProfileId = p.id;
    if (goalKg != null) goalWeights = {p.id: goalKg};
    onboardingDone = true;
    await _store.saveProfiles(profiles);
    await _store.saveActiveProfileId(p.id);
    if (goalKg != null) await _store.saveGoalWeight(p.id, goalKg);
    await _store.saveOnboardingDone(true);
    await _saveBackupBlob();
    notifyListeners();
  }

  Future<void> markMilestoneSeen(int weeks) async {
    if (milestonesSeen.contains(weeks)) return;
    milestonesSeen = [...milestonesSeen, weeks];
    await _store.saveMilestonesSeen(milestonesSeen);
    await _saveBackupBlob();
    notifyListeners();
  }

  // Saves profiles/goals/settings next to the backup code. Cheap RPC,
  // no-op when the cloud isn't connected.
  Future<void> _saveBackupBlob() async {
    await CloudSync.saveBackupBlob(
      profiles: profiles,
      goalWeights: goalWeights,
      settings: {
        'activeProfileId': activeProfileId,
        'metricUnits': metricUnits,
        'activity': activity,
        'weeklyReminder': weeklyReminder,
        'reminderWeekdays': reminderWeekdays,
        'reminderWeekday': reminderWeekdays.first,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'darkMode': darkMode,
        'milestonesSeen': milestonesSeen,
      },
    );
  }

  // Replaces everything on this phone with the backup tied to [code].
  // Returns false when the code matches nothing or the cloud is down.
  Future<bool> restoreFromBackupCode(String code) async {
    final data = await CloudSync.restoreBackup(code);
    if (data == null || data.isEmpty || data.profiles.isEmpty) return false;
    final profileIds = data.profiles.map((p) => p.id).toSet();
    profiles = data.profiles;
    records = data.records
        .where((r) => profileIds.contains(r.profileId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    goalWeights = data.goals;
    final s = data.settings;
    final apid = s['activeProfileId'] as String?;
    activeProfileId =
        (apid != null && profileIds.contains(apid)) ? apid : profiles.first.id;
    metricUnits = s['metricUnits'] as bool? ?? true;
    activity = s['activity'] as String? ?? 'Light';
    weeklyReminder = s['weeklyReminder'] as bool? ?? false;
    // Sort: the normal path always stores sorted days, but a backup blob
    // can arrive in any order — without this the summary shows "Kam & Sen"
    // and .first (used as the legacy single-day) isn't the earliest day.
    final days = (s['reminderWeekdays'] as List?)
        ?.map((e) => (e as num).toInt())
        .where((d) => d >= 1 && d <= 7)
        .toList()
      ?..sort();
    reminderWeekdays = (days != null && days.isNotEmpty)
        ? days
        : [(s['reminderWeekday'] as num?)?.toInt() ?? 7];
    reminderHour = (s['reminderHour'] as num?)?.toInt() ?? 9;
    reminderMinute = (s['reminderMinute'] as num?)?.toInt() ?? 0;
    darkMode = s['darkMode'] as bool? ?? true;
    milestonesSeen = ((s['milestonesSeen'] as List?) ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    await _store.saveProfiles(profiles);
    await _store.saveRecords(records);
    await _store.saveGoalWeights(goalWeights);
    await _store.saveActiveProfileId(activeProfileId);
    await _store.saveMetricUnits(metricUnits);
    await _store.saveActivity(activity);
    await _store.saveWeeklyReminder(weeklyReminder);
    await _store.saveReminderWeekdays(reminderWeekdays);
    await _store.saveReminderSchedule(
        weekday: reminderWeekdays.first,
        hour: reminderHour,
        minute: reminderMinute);
    await _store.saveDarkMode(darkMode);
    await _store.saveMilestonesSeen(milestonesSeen);
    // A restored phone has obviously been through onboarding.
    onboardingDone = true;
    await _store.saveOnboardingDone(true);
    // Adopt the code so future entries stamp it, and don't re-push
    // rows that are already in the cloud.
    final normalized = CloudSync.normalizeCode(code);
    await _store.saveBackupCode(normalized);
    CloudSync.backupCode = normalized;
    await CloudSync.markSynced(records.map((r) => r.id));
    notifyListeners();
    if (weeklyReminder) {
      try {
        await ReminderService.scheduleBestEffortDays(
          weekdays: reminderWeekdays,
          hour: reminderHour,
          minute: reminderMinute,
        );
      } catch (_) {
        // The toggle flow will re-arm it on next launch.
      }
    } else {
      // The backup had the reminder off, but this phone may still have
      // alarms armed from before the restore — cancel them so a
      // "disabled" reminder can't keep firing.
      try {
        await ReminderService.cancelAll();
      } catch (_) {}
    }
    return true;
  }

  // Matches LocalStore.clearAll: memory and disk end up identical, so a
  // restart can't resurrect stale goals, milestones, or a phantom
  // placeholder profile that was never saved.
  Future<void> clearAllData() async {
    await _store.clearAll();
    final p = Profile(name: 'You');
    profiles = [p];
    activeProfileId = p.id;
    records = [];
    goalWeights = {};
    milestonesSeen = [];
    // A wiped phone is a fresh phone: onboarding runs again next launch.
    onboardingDone = false;
    await _store.saveProfiles(profiles);
    await _store.saveActiveProfileId(p.id);
    await _store.saveGoalWeights(goalWeights);
    await _store.saveMilestonesSeen(milestonesSeen);
    await _store.saveOnboardingDone(false);
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope tidak ditemukan di widget tree');
    return scope!.notifier!;
  }
}

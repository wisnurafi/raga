import 'package:flutter/material.dart';
import '../data/local_store.dart';
import '../data/cloud_sync.dart';
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
  int reminderWeekday = 7;
  int reminderHour = 9;
  int reminderMinute = 0;
  Map<String, double> goalWeights = {};

  AppState(this._store);

  static Future<AppState> load() async {
    final store = await LocalStore.load();
    final state = AppState(store);
    state.profiles = store.profiles;
    state.records = store.records;
    state.metricUnits = store.metricUnits;
    state.activity = store.activity;
    state.weeklyReminder = store.weeklyReminder;
    state.reminderWeekday = store.reminderWeekday;
    state.reminderHour = store.reminderHour;
    state.reminderMinute = store.reminderMinute;
    state.goalWeights = store.goalWeights;
    if (state.profiles.isEmpty) {
      final p = Profile(name: 'Wisnu');
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
    await CloudSync.pushRecord(r);
    notifyListeners();
  }

  Future<void> setMetricUnits(bool v) async {
    metricUnits = v;
    await _store.saveMetricUnits(v);
    notifyListeners();
  }

  // Retry pending uploads, then refresh the UI.
  Future<void> refreshSync() async {
    await CloudSync.syncPending(records);
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
    notifyListeners();
  }

  Future<void> setWeeklyReminder(bool v) async {
    weeklyReminder = v;
    await _store.saveWeeklyReminder(v);
    notifyListeners();
  }

  Future<void> setReminderSchedule({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    reminderWeekday = weekday;
    reminderHour = hour;
    reminderMinute = minute;
    await _store.saveReminderSchedule(
        weekday: weekday, hour: hour, minute: minute);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _store.clearAll();
    profiles = [Profile(name: 'Wisnu')];
    activeProfileId = profiles.first.id;
    records = [];
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

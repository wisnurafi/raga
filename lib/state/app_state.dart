import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local_store.dart';
import '../data/cloud_sync.dart';
import '../data/auth_service.dart';
import '../data/reminder_service.dart';
import '../models/profile.dart';
import '../models/bmi_record.dart';

// Outcome of the Google sign-in flow, so the UI can react precisely
// (cancelled vs failed vs first-login-migrated vs returning-with-cloud).
class SignInResult {
  final bool cancelled;
  final bool failed;
  final bool notConfigured;
  final String detail;
  final bool isFirstLogin;
  final int migratedCount;
  final int cloudCount;

  const SignInResult._({
    this.cancelled = false,
    this.failed = false,
    this.notConfigured = false,
    this.detail = '',
    this.isFirstLogin = false,
    this.migratedCount = 0,
    this.cloudCount = 0,
  });

  const SignInResult.cancelled() : this._(cancelled: true);
  const SignInResult.notConfigured() : this._(notConfigured: true);
  const SignInResult.failed(String detail) : this._(failed: true, detail: detail);
  const SignInResult.migrated(int n)
      : this._(isFirstLogin: true, migratedCount: n);
  const SignInResult.returning(int cloud)
      : this._(cloudCount: cloud);
}

// Pure helper (unit-tested): union of two record lists, deduped by the
// stable id, newest first. Incoming rows already carry stable ids
// (fromUserJson / fromCloudJson), so the same weigh-in never appears
// twice no matter which device it came from.
List<BmiRecord> mergeRecordLists(
    List<BmiRecord> local, List<BmiRecord> incoming) {
  final have = local.map((r) => r.id).toSet();
  final merged = [
    ...local,
    ...incoming.where((r) => !have.contains(r.id)),
  ];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}

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
  String locale = 'id';

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
    state.locale = store.locale;
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
    // Account changes (login/logout, name/photo edits) re-render the UI.
    AuthService.instance.addListener(state._onAccountChanged);
    return state;
  }

  void _onAccountChanged() => notifyListeners();

  // --- optional Google account (AuthService is the source of truth) ---
  bool get isLoggedIn => AuthService.instance.isLoggedIn;
  String? get accountName => AuthService.instance.displayName;
  String? get accountEmail => AuthService.instance.email;
  String? get accountAvatarUrl => AuthService.instance.avatarUrl;

  // Full Google sign-in flow:
  //   1. flush local data to the cloud through the existing backup
  //      machinery (export),
  //   2. native Google sign-in -> Supabase session,
  //   3. first login: move every local record into the account's
  //      `records` table (import); returning login: just count the
  //      cloud rows so the UI can offer a merge.
  Future<SignInResult> signInWithGoogle() async {
    await refreshSync();
    final User? user;
    try {
      user = await AuthService.instance.signInWithGoogle();
    } on AuthException catch (e) {
      if (e.message == 'not-configured') {
        return const SignInResult.notConfigured();
      }
      return SignInResult.failed(e.message);
    } catch (e) {
      return SignInResult.failed(e.toString().split('\n').first);
    }
    if (user == null) return const SignInResult.cancelled();
    final bool isFirst;
    try {
      isFirst = await AuthService.instance.ensureProfileRow();
    } catch (e) {
      // Account tables missing/misconfigured: don't leave a
      // half-logged-in session behind — back to anonymous.
      await AuthService.instance.signOut();
      return SignInResult.failed(e.toString().split('\n').first);
    }
    if (isFirst) {
      final n = await _migrateLocalToAccount();
      notifyListeners();
      return SignInResult.migrated(n);
    }
    final cloud = await CloudSync.cloudUserRecordCount();
    notifyListeners();
    return SignInResult.returning(cloud);
  }

  // Moves every local record into the account's `records` table.
  // pushRecord dual-writes there when logged in; its bmi_records half
  // keeps the backup-code path intact, so the code stays a recovery
  // route independent of Google.
  Future<int> _migrateLocalToAccount() async {
    var n = 0;
    for (final r in records) {
      if (await CloudSync.pushRecord(r)) n++;
    }
    CloudSync.logEvent(
        'auth: migrated $n/${records.length} records to account');
    return n;
  }

  // Pulls the account's `records` rows and unions them into the local
  // history. Pulled rows also go through pushRecord so the backup-code
  // path keeps seeing everything. Returns the new-row count, or -1 when
  // the pull itself failed.
  Future<int> mergeFromCloud() async {
    final cloud = await CloudSync.fetchUserRecords();
    if (cloud == null) return -1;
    if (cloud.isEmpty) return 0;
    final knownProfiles = profiles.map((p) => p.id).toSet();
    final have = records.map((r) => r.id).toSet();
    final fresh = <BmiRecord>[];
    for (final r in cloud) {
      if (have.contains(r.id)) continue;
      // A row may reference a profile id this device never had (saved on
      // another phone): fold it into the active profile instead of
      // orphaning it.
      fresh.add(knownProfiles.contains(r.profileId)
          ? r
          : BmiRecord(
              id: r.id,
              profileId: activeProfileId,
              heightCm: r.heightCm,
              weightKg: r.weightKg,
              createdAt: r.createdAt,
            ));
    }
    if (fresh.isEmpty) return 0;
    records = mergeRecordLists(records, fresh);
    await _store.saveRecords(records);
    for (final r in fresh) {
      // Through the backup-code path too, so code restore keeps seeing
      // everything (the dual-write also re-upserts the account table —
      // idempotent, harmless).
      await CloudSync.pushRecord(r);
    }
    CloudSync.logEvent('auth: merged ${fresh.length} cloud records');
    notifyListeners();
    return fresh.length;
  }

  // "Gabung" half of the restore choice: unions the backup's rows into
  // the local history instead of replacing it. Profiles/goals already
  // on this device win on id conflicts; settings are left alone
  // (they're device preferences). Returns the new-record count, or -1
  // when the code matched nothing / the cloud was unreachable.
  Future<int> mergeFromBackupCode(String code) async {
    final data = await CloudSync.restoreBackup(code);
    if (data == null || data.isEmpty) return -1;
    final have = records.map((r) => r.id).toSet();
    final freshRecords =
        data.records.where((r) => !have.contains(r.id)).toList();
    if (freshRecords.isNotEmpty) {
      records = mergeRecordLists(records, freshRecords);
      await _store.saveRecords(records);
      // They came from the cloud, so they're trivially "synced".
      await CloudSync.markSynced(freshRecords.map((r) => r.id));
    }
    final haveProfiles = profiles.map((p) => p.id).toSet();
    final freshProfiles =
        data.profiles.where((p) => !haveProfiles.contains(p.id)).toList();
    if (freshProfiles.isNotEmpty) {
      profiles = [...profiles, ...freshProfiles];
      await _store.saveProfiles(profiles);
    }
    final goals = Map<String, double>.from(goalWeights);
    var freshGoals = 0;
    for (final e in data.goals.entries) {
      if (!goals.containsKey(e.key)) {
        goals[e.key] = e.value;
        freshGoals++;
      }
    }
    if (freshGoals > 0) {
      goalWeights = goals;
      await _store.saveGoalWeights(goals);
    }
    // Adopt the code like the replace flow does, so future entries stamp
    // it and the next merge sees the full picture.
    final normalized = CloudSync.normalizeCode(code);
    await _store.saveBackupCode(normalized);
    CloudSync.backupCode = normalized;
    CloudSync.logEvent('backup: merged ${freshRecords.length} records, '
        '${freshProfiles.length} profiles, $freshGoals goals from code');
    notifyListeners();
    return freshRecords.length;
  }

  // Ends the account session. Local data is deliberately kept — wiping
  // is only ever via the explicit wipe button.
  Future<void> signOut() async {
    await AuthService.instance.signOut();
    CloudSync.logEvent('auth: signed out (local data kept)');
    notifyListeners();
  }

  Future<bool> setAccountName(String name) async {
    final ok = await AuthService.instance.setDisplayName(name);
    if (ok) {
      CloudSync.logEvent('auth: display name updated');
      notifyListeners();
    }
    return ok;
  }

  Future<String?> uploadAccountAvatar(Uint8List bytes) async {
    final url = await AuthService.instance.uploadAvatar(bytes);
    if (url != null) notifyListeners();
    return url;
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
    CloudSync.logEvent('profile: active -> $id');
    notifyListeners();
  }

  Future<void> addProfile(Profile profile) async {
    profiles = [...profiles, profile];
    await _store.saveProfiles(profiles);
    CloudSync.logEvent('profile: added "${profile.name}"');
    await setActiveProfile(profile.id);
    await _saveBackupBlob();
  }

  Future<void> updateActiveProfile(Profile Function(Profile) fn) async {
    profiles = profiles
        .map((p) => p.id == activeProfileId ? fn(p) : p)
        .toList();
    await _store.saveProfiles(profiles);
    // Profile edits (name, age, gender, height) must reach the cloud
    // backup too — previously only addProfile saved the blob.
    await _saveBackupBlob();
    CloudSync.logEvent('profile: edited');
    notifyListeners();
  }

  Future<void> removeProfile(String id) async {
    if (profiles.length <= 1) return;
    profiles = profiles.where((p) => p.id != id).toList();
    records = records.where((r) => r.profileId != id).toList();
    await _store.saveProfiles(profiles);
    await _store.saveRecords(records);
    CloudSync.logEvent('profile: removed $id');
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
    CloudSync.logEvent('record: saved ${r.weightKg.toStringAsFixed(1)} kg '
        '(bmi ${r.bmi.toStringAsFixed(1)})');
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
    CloudSync.logEvent('settings: units -> ${v ? 'metric' : 'imperial'}');
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
    CloudSync.logEvent(kg == null
        ? 'goal: cleared for $profileId'
        : 'goal: set ${kg.toStringAsFixed(1)} kg for $profileId');
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
    CloudSync.logEvent('settings: theme -> ${v ? 'dark' : 'light'}');
    notifyListeners();
  }

  Future<void> setLocale(String v) async {
    if (v != 'en' && v != 'id') return;
    locale = v;
    await _store.saveLocale(v);
    CloudSync.logEvent('settings: locale -> $v');
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
        'locale': locale,
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
    final loc = s['locale'] as String?;
    locale = (loc == 'en' || loc == 'id') ? loc! : 'id';
    await _store.saveLocale(locale);
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
          locale: locale,
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

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../models/bmi_record.dart';
import '../detak/detak_state.dart';
import 'secure_store.dart';

// Local storage (SharedPreferences). This is the source of truth —
// the app works fully offline or before Supabase is even configured.
class LocalStore {
  static const _kProfiles = 'raga.profiles';
  static const _kActiveProfile = 'raga.active_profile';
  static const _kRecords = 'raga.records';
  static const _kMetric = 'raga.metric_units';
  static const _kActivity = 'raga.activity';
  static const _kReminder = 'raga.weekly_reminder';
  static const _kReminderDay = 'raga.reminder_weekday';
  static const _kReminderDays = 'raga.reminder_weekdays';
  static const _kReminderHour = 'raga.reminder_hour';
  static const _kReminderMin = 'raga.reminder_minute';
  static const _kDarkMode = 'raga.dark_mode';
  static const _kGoals = 'raga.goal_weights';
  static const _kDevMode = 'raga.dev_mode';
  static const _kOnboardingDone = 'raga.onboarding_done';
  static const _kMilestonesSeen = 'raga.milestones_seen';
  static const _kLocale = 'raga.locale';
  static const _kDetak = 'raga.detak';

  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  static Future<LocalStore> load() async =>
      LocalStore(await SharedPreferences.getInstance());

  List<Profile> get profiles {
    final raw = _prefs.getString(_kProfiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfiles(List<Profile> v) =>
      _prefs.setString(_kProfiles, jsonEncode(v.map((e) => e.toJson()).toList()));

  String? get activeProfileId => _prefs.getString(_kActiveProfile);
  Future<void> saveActiveProfileId(String id) =>
      _prefs.setString(_kActiveProfile, id);

  List<BmiRecord> get records {
    final raw = _prefs.getString(_kRecords);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => BmiRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecords(List<BmiRecord> v) =>
      _prefs.setString(_kRecords, jsonEncode(v.map((e) => e.toJson()).toList()));

  bool get metricUnits => _prefs.getBool(_kMetric) ?? true;
  Future<void> saveMetricUnits(bool v) => _prefs.setBool(_kMetric, v);

  String get activity => _prefs.getString(_kActivity) ?? 'Light';
  Future<void> saveActivity(String v) => _prefs.setString(_kActivity, v);

  bool get weeklyReminder => _prefs.getBool(_kReminder) ?? false;
  Future<void> saveWeeklyReminder(bool v) => _prefs.setBool(_kReminder, v);

  // Reminder schedule: weekday 1 (Mon) .. 7 (Sun), 24h time.
  int get reminderHour => _prefs.getInt(_kReminderHour) ?? 9;
  int get reminderMinute => _prefs.getInt(_kReminderMin) ?? 0;

  /// Days of week (1=Mon..7=Sun) the weigh-in nudge fires. Migrates the
  /// old single-weekday setting on first read.
  List<int> get reminderWeekdays {
    final raw = _prefs.getString(_kReminderDays);
    if (raw != null) {
      try {
        final days = (jsonDecode(raw) as List)
            .map((e) => (e as num).toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList();
        if (days.isNotEmpty) return days;
      } catch (_) {}
    }
    return [_prefs.getInt(_kReminderDay) ?? 7];
  }

  Future<void> saveReminderWeekdays(List<int> v) =>
      _prefs.setString(_kReminderDays, jsonEncode(v));

  /// Dark mode is the mockup's look; default on.
  bool get darkMode => _prefs.getBool(_kDarkMode) ?? true;
  Future<void> saveDarkMode(bool v) => _prefs.setBool(_kDarkMode, v);
  Future<void> saveReminderSchedule(
      {required int weekday, required int hour, required int minute}) async {
    await _prefs.setInt(_kReminderDay, weekday);
    await _prefs.setInt(_kReminderHour, hour);
    await _prefs.setInt(_kReminderMin, minute);
  }

  // Target weight per profile, in kg. Missing key = no goal set.
  Map<String, double> get goalWeights {
    final raw = _prefs.getString(_kGoals);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveGoalWeight(String profileId, double? kg) async {
    final m = goalWeights;
    if (kg == null) {
      m.remove(profileId);
    } else {
      m[profileId] = kg;
    }
    await _prefs.setString(_kGoals, jsonEncode(m));
  }

  Future<void> saveGoalWeights(Map<String, double> m) =>
      _prefs.setString(_kGoals, jsonEncode(m));

  // Backup code: the restorable identity for cloud backup. Anonymous
  // sign-ins get a fresh user_id per install, so this code (kept by the
  // user) is what ties a reinstall back to the old rows. Lives in
  // encrypted secure storage, never in plaintext prefs.
  Future<void> saveBackupCode(String code) =>
      SecureStore.writeBackupCode(code);

  bool get devMode => _prefs.getBool(_kDevMode) ?? false;
  Future<void> saveDevMode(bool v) => _prefs.setBool(_kDevMode, v);

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> saveOnboardingDone(bool v) =>
      _prefs.setBool(_kOnboardingDone, v);

  // Milestone weeks already celebrated (so each fires exactly once).
  List<int> get milestonesSeen {
    final raw = _prefs.getString(_kMilestonesSeen);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => (e as num).toInt()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMilestonesSeen(List<int> v) =>
      _prefs.setString(_kMilestonesSeen, jsonEncode(v));

  // UI locale: 'id' (default) or 'en'. Anything else falls back to 'id'
  // so a corrupt value can't leave the app stringless.
  String get locale {
    final v = _prefs.getString(_kLocale);
    return v == 'en' ? 'en' : 'id';
  }

  Future<void> saveLocale(String v) => _prefs.setString(_kLocale, v);

  // Detak companion state. Corrupt JSON falls back to a fresh Detak —
  // the companion must never break the app.
  DetakState get detak {
    final raw = _prefs.getString(_kDetak);
    if (raw == null || raw.isEmpty) return DetakState();
    try {
      return DetakState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DetakState();
    }
  }

  Future<void> saveDetak(DetakState d) =>
      _prefs.setString(_kDetak, jsonEncode(d.toJson()));

  // Factory reset for user DATA: profiles, history, goals, milestones,
  // and the onboarding flag (so a wiped phone onboards again like new).
  // Settings are deliberately kept: units, activity level, reminder
  // schedule, backup code (still needed to restore), and dev mode.
  Future<void> clearAll() async {
    await _prefs.remove(_kProfiles);
    await _prefs.remove(_kActiveProfile);
    await _prefs.remove(_kRecords);
    await _prefs.remove(_kGoals);
    await _prefs.remove(_kMilestonesSeen);
    await _prefs.remove(_kOnboardingDone);
  }
}

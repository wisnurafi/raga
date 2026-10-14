import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../models/bmi_record.dart';

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
  static const _kReminderHour = 'raga.reminder_hour';
  static const _kReminderMin = 'raga.reminder_minute';
  static const _kGoals = 'raga.goal_weights';

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
  int get reminderWeekday => _prefs.getInt(_kReminderDay) ?? 7;
  int get reminderHour => _prefs.getInt(_kReminderHour) ?? 9;
  int get reminderMinute => _prefs.getInt(_kReminderMin) ?? 0;
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

  Future<void> clearAll() async {
    await _prefs.remove(_kProfiles);
    await _prefs.remove(_kActiveProfile);
    await _prefs.remove(_kRecords);
    await _prefs.remove(_kGoals);
  }
}

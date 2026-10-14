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

  Future<void> clearAll() async {
    await _prefs.remove(_kProfiles);
    await _prefs.remove(_kActiveProfile);
    await _prefs.remove(_kRecords);
  }
}

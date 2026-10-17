import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bmi_record.dart';
import '../models/leaderboard_entry.dart';
import '../models/profile.dart';
import '../core/ids.dart';
import 'secure_store.dart';
import '../core/strings.dart';

// Cloud backup state, shown in the UI so it's never a mystery.
enum SyncState {
  // SUPABASE_URL / SUPABASE_ANON_KEY were empty at build time.
  notConfigured,

  // Signed in anonymously, ready to push.
  ready,

  // Last init or push failed. See [CloudSync.lastError].
  error,
}

// Everything a backup-code restore pulls back from the cloud.
class BackupData {
  final List<BmiRecord> records;
  final List<Profile> profiles;
  final Map<String, double> goals;
  final Map<String, dynamic> settings;

  BackupData({
    required this.records,
    required this.profiles,
    required this.goals,
    required this.settings,
  });

  BackupData.empty()
      : records = const [],
        profiles = const [],
        goals = const {},
        settings = const {};

  bool get isEmpty => records.isEmpty && profiles.isEmpty;
}

// Backs records up to Supabase. Uses anonymous sign-in, so each device
// gets its own identity with no login screen. Row-level security in the
// database keeps every user to their own rows.
//
// Anonymous identities don't survive a reinstall (fresh sign-in = fresh
// user_id), so every row is also stamped with a backup code the user
// keeps. On a new install, entering the code pulls everything back
// through the restore_backup() RPC — that's the actual restore path.
//
// Unlike the first version, this one doesn't fail silently:
// - it exposes its status + last error for the UI,
// - it remembers which records made it up, and retries the rest
//   automatically next launch,
// - it keeps a session log for developer mode.
// Outcome of [CloudSync.restampAllRecords]: whether every row ended up
// stamped with the current code, plus the id swaps for rows that had to
// be re-inserted ([healed] maps the old local id to the fresh cloud id).
class RestampResult {
  final bool ok;
  final Map<String, String> healed;
  const RestampResult(this.ok, this.healed);
}

class CloudSync {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _kSyncedIds = 'raga.synced_ids';
  static const _kBackupCode = 'raga.backup_code';

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static SyncState state = SyncState.notConfigured;
  static String lastError = '';
  static SharedPreferences? _prefs;
  static final Set<String> _syncedIds = {};

  // The restorable identity. Generated once per device, kept by the user.
  static String? backupCode;

  static bool get isReady => state == SyncState.ready;

  static String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  // Records saved locally that haven't made it to the cloud yet.
  static int pendingCount(List<BmiRecord> records) =>
      records.where((r) => !_syncedIds.contains(r.id)).length;

  // Session log, surfaced in developer mode.
  static final List<String> _log = [];
  static void logEvent(String msg) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    _log.add('[$t] $msg');
    if (_log.length > 120) _log.removeRange(0, _log.length - 120);
  }

  static String get logText =>
      _log.isEmpty ? 'No sync activity yet this session.' : _log.join('\n');
  static void clearLog() => _log.clear();

  // 16 chars from an unambiguous alphabet (no 0/O/1/I/L) = 80 bits.
  // Brute-forcing someone else's code through the RPC is infeasible.
  static String generateBackupCode() {
    const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final s = List.generate(
        16, (_) => alphabet[r.nextInt(alphabet.length)]).join();
    return '${s.substring(0, 4)}-${s.substring(4, 8)}-'
        '${s.substring(8, 12)}-${s.substring(12, 16)}';
  }

  // Accepts the code with or without dashes, any casing.
  static String normalizeCode(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length != 16) return clean;
    return '${clean.substring(0, 4)}-${clean.substring(4, 8)}-'
        '${clean.substring(8, 12)}-${clean.substring(12, 16)}';
  }

  // Persists [code] as this device's backup code (user-initiated only —
  // see init(): no code is generated until the user asks for one).
  static Future<void> setBackupCode(String code) async {
    backupCode = code;
    await SecureStore.writeBackupCode(code);
    logEvent('backup: code set by user');
  }

  // Server-side restamp: moves every row stamped with [oldCode] to
  // [newCode], including rows owned by a previous auth identity (e.g.
  // after a restore) that RLS would forbid this device from updating
  // directly (42501). The old code is the ownership proof (80-bit,
  // unguessable — knowing it already grants full restore access, so this
  // reveals nothing new). Returns the moved client_ids, or null when the
  // RPC is unavailable (migration not applied) or the call failed.
  static Future<Set<String>?> restampBackupCode({
    required String oldCode,
    required String newCode,
  }) async {
    if (!isReady) return null;
    try {
      final res = await Supabase.instance.client.rpc(
        'restamp_backup_code',
        params: {'p_old_code': oldCode, 'p_new_code': newCode},
      );
      final moved = <String>{};
      if (res is List) {
        for (final e in res) {
          moved.add('$e');
        }
      }
      logEvent('backup: restamp_backup_code moved ${moved.length} rows');
      return moved;
    } catch (e) {
      logEvent('restamp_backup_code failed: ${_short(e)}');
      return null;
    }
  }

  // Re-stamps every local record with the current backup code. Needed when
  // the code is created *after* rows were already synced: those rows were
  // stamped with NULL (or an older code) and would otherwise be invisible
  // to restore_backup(p_code). Rows in [skipIds] were already moved
  // server-side by restampBackupCode and are marked synced without a push.
  //
  // Healer: a row owned by a previous auth identity (e.g. after a restore)
  // can't be updated — RLS rejects it with 42501 — and the RPC can't move
  // it when its stamp is no longer known. Such rows are re-inserted as
  // fresh rows owned by this session under the new code; the orphaned
  // original stays in the cloud, invisible to the code. The returned
  // [RestampResult.healed] map (old id -> new id) lets the caller swap the
  // local identity so future upserts and restores dedupe correctly.
  // Only successfully pushed rows are marked synced, so a failed (e.g.
  // offline) row is retried by syncPending later.
  static Future<RestampResult> restampAllRecords(
    List<BmiRecord> records, {
    Set<String> skipIds = const {},
  }) async {
    if (!isReady || backupCode == null) {
      return const RestampResult(false, {});
    }
    final done = <String>[];
    final healed = <String, String>{};
    var ok = true;
    var lastFailure = '';
    for (final r in records) {
      if (skipIds.contains(r.id)) {
        done.add(r.id);
        continue;
      }
      try {
        await _upsertRecord(r);
        done.add(r.id);
      } on PostgrestException catch (e) {
        if (e.code == '42501') {
          final copy = r.copyWith(id: newId());
          try {
            await _upsertRecord(copy);
            healed[r.id] = copy.id;
            done.add(copy.id);
            logEvent('backup: healed row via re-insert (fresh id)');
          } catch (e2) {
            ok = false;
            lastFailure = _short(e2);
          }
        } else {
          ok = false;
          lastFailure = _short(e);
        }
      } catch (e) {
        ok = false;
        lastFailure = _short(e);
      }
    }
    await markSynced(done);
    if (ok) {
      state = SyncState.ready;
      lastError = '';
    } else {
      state = SyncState.error;
      lastError = lastFailure;
    }
    logEvent('backup: restamped ${done.length}/${records.length} records'
        '${skipIds.isNotEmpty ? ' (${skipIds.length} via RPC)' : ''}'
        '${healed.isNotEmpty ? ' (${healed.length} healed)' : ''}');
    return RestampResult(ok, healed);
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _syncedIds.addAll(_prefs!.getStringList(_kSyncedIds) ?? const []);
    if (!isConfigured) {
      state = SyncState.notConfigured;
      lastError =
          'SUPABASE_URL / SUPABASE_ANON_KEY is empty (check GitHub Secrets and rebuild).';
      logEvent('init: not configured');
      return;
    }
    backupCode = await SecureStore.readBackupCode();
    if (backupCode == null || backupCode!.isEmpty) {
      // One-time migration from plaintext prefs (pre-secure-storage installs).
      final legacy = _prefs!.getString(_kBackupCode);
      if (legacy != null && legacy.isNotEmpty) {
        backupCode = legacy;
        await SecureStore.writeBackupCode(backupCode!);
        logEvent('init: migrated backup code to secure storage');
      } else {
        // No code yet: one is created only when the user explicitly asks
        // for it from the Profile screen, so the DB doesn't fill up with
        // codes nobody will ever use.
        backupCode = null;
        logEvent('init: no backup code yet (on-demand)');
      }
      await _prefs!.remove(_kBackupCode);
    }
    try {
      await Supabase.initialize(url: _url, publishableKey: _anonKey);
      // A persisted Google session must survive cold starts: only fall
      // back to anonymous when there is no session at all. (Previously
      // this signed in anonymously unconditionally, which would have
      // silently replaced a logged-in session on every launch.)
      if (Supabase.instance.client.auth.currentSession == null) {
        // Needs "Allow anonymous sign-ins" turned on in the Supabase dashboard.
        await Supabase.instance.client.auth.signInAnonymously();
      }
      state = SyncState.ready;
      lastError = '';
      logEvent('init: signed in, ready');
    } catch (e) {
      state = SyncState.error;
      lastError = _short(e);
      logEvent('init failed: $lastError');
    }
  }

  // Pushes every local record that hasn't been uploaded yet. Runs at
  // startup, and can be triggered by hand from the Profile screen.
  static Future<void> syncPending(List<BmiRecord> records) async {
    if (!isReady) return;
    var pushed = 0;
    for (final r in records) {
      if (_syncedIds.contains(r.id)) continue;
      if (await pushRecord(r)) pushed++;
    }
    logEvent('syncPending: $pushed pushed, ${pendingCount(records)} left');
  }

  // Pushes one record. Returns false on failure; never throws to the
  // caller, but records the error in [lastError] so the UI can show it.
  static Future<bool> pushRecord(BmiRecord record) async {
    if (!isReady) return false;
    try {
      await _upsertRecord(record);
    } catch (e) {
      state = SyncState.error;
      lastError = e is StateError ? e.message : _short(e);
      logEvent('push failed: $lastError');
      return false;
    }
    _syncedIds.add(record.id);
    await _prefs?.setStringList(_kSyncedIds, _syncedIds.toList());
    // A success clears any earlier transient failure: without this the
    // state stays `error` forever and the UI keeps saying "Couldn't
    // connect" even though uploads are working again.
    state = SyncState.ready;
    lastError = '';
    return true;
  }

  // The actual upsert. Throws on failure (including PostgrestException
  // 42501 for RLS) so callers that need to tell error kinds apart — like
  // the restamp healer below — can catch themselves.
  static Future<void> _upsertRecord(BmiRecord record) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError(
          'Supabase anonymous session is gone (try restarting the app).');
    }
    // onConflict: 'client_id' makes the upsert idempotent: a retry after
    // a crash between a successful upsert and the _syncedIds write
    // updates the existing row instead of inserting a duplicate.
    // Requires migration 20261015_client_id_bmi_records.sql applied.
    await Supabase.instance.client.from('bmi_records').upsert(
        record.toCloudJson(uid, backupCode),
        onConflict: 'client_id');
    // Logged-in mode: the relational `records` table is the
    // cross-device source of truth for history, so it gets the same
    // row. The bmi_records upsert above keeps the backup-code path
    // working in both modes. (isAnonymous distinguishes the modes
    // without importing the auth layer.)
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      // Requires migration 20261016_auth_tables.sql applied.
      await Supabase.instance.client
          .from('records')
          .upsert(record.toUserJson(user.id), onConflict: 'client_id');
    }
  }

  // Marks rows as uploaded without pushing (used after a restore —
  // those rows are already in the cloud).
  static Future<void> markSynced(Iterable<String> ids) async {
    _syncedIds.addAll(ids);
    await _prefs?.setStringList(_kSyncedIds, _syncedIds.toList());
  }

  // How many rows the account holds in the relational `records` table.
  // Used after a returning login to offer a cloud merge.
  static Future<int> cloudUserRecordCount() async {
    final uid = _userId;
    if (!isReady || uid == null) return 0;
    try {
      final rows = await Supabase.instance.client
          .from('records')
          .select('id')
          .eq('user_id', uid);
      return (rows as List).length;
    } catch (e) {
      logEvent('user count failed: ${_short(e)}');
      return 0;
    }
  }

  // Pulls the account's rows from the relational `records` table
  // (logged-in mode). Null on failure (so the caller can tell "failed"
  // apart from "nothing there"), empty list when the account simply has
  // no rows yet.
  static Future<List<BmiRecord>?> fetchUserRecords() async {
    final uid = _userId;
    if (!isReady || uid == null) return null;
    try {
      final rows = await Supabase.instance.client
          .from('records')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((e) =>
              BmiRecord.fromUserJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      lastError = _short(e);
      logEvent('user pull failed: $lastError');
      return null;
    }
  }

  // Saves profiles, goals, and settings next to the backup code, so a
  // restore brings back more than just the weigh-in history.
  static Future<void> saveBackupBlob({
    required List<Profile> profiles,
    required Map<String, double> goalWeights,
    required Map<String, dynamic> settings,
  }) async {
    if (!isReady || backupCode == null) return;
    try {
      await Supabase.instance.client.rpc('save_backup_blob', params: {
        'p_code': backupCode!,
        'p_profiles': profiles.map((p) => p.toJson()).toList(),
        'p_goals': goalWeights,
        'p_settings': settings,
      });
      logEvent('backup blob saved');
    } catch (e) {
      logEvent('blob save failed: ${_short(e)}');
    }
  }

  // Pulls everything tied to a backup code. Returns null on transport
  // errors, or an empty BackupData when the code matches nothing.
  static Future<BackupData?> restoreBackup(String rawCode) async {
    if (!isReady) {
      lastError = 'Cloud backup is not connected.';
      return null;
    }
    final code = normalizeCode(rawCode);
    if (code.isEmpty) {
      return BackupData.empty();
    }
    try {
      final res = await Supabase.instance.client
          .rpc('restore_backup', params: {'p_code': code});
      if (res == null) {
        return BackupData.empty();
      }
      final map = Map<String, dynamic>.from(res as Map);
      final records = ((map['records'] as List?) ?? [])
          .map((e) =>
              BmiRecord.fromCloudJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final profiles = ((map['profiles'] as List?) ?? [])
          .map((e) => Profile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final goals = ((map['goals'] as Map?) ?? {})
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      final settings =
          Map<String, dynamic>.from((map['settings'] as Map?) ?? {});
      logEvent(
          'restore: ${records.length} records, ${profiles.length} profiles');
      return BackupData(
          records: records,
          profiles: profiles,
          goals: goals,
          settings: settings);
    } catch (e) {
      lastError = _short(e);
      logEvent('restore failed: $lastError');
      return null;
    }
  }

  // Error text that's safe to show (no secrets or URLs in it).
  static String _short(Object e) {
    final s = e.toString();
    final oneLine = s.split('\n').first;
    final cleaned = oneLine
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^PostgrestException[^:]*:\s*'), '');
    return cleaned.length > 140 ? '${cleaned.substring(0, 140)}…' : cleaned;
  }

  // The hostname baked into this build (from SUPABASE_URL at build time).
  // Shown in developer mode so a wrong/old value is visible immediately.
  static String get configuredHost {
    if (_url.isEmpty) return '(not set)';
    try {
      final h = Uri.parse(_url).host;
      return h.isEmpty ? '(invalid)' : h;
    } catch (_) {
      return '(invalid)';
    }
  }

  // --- Arena: community leaderboard ---------------------------------
  // The board is served by the get_leaderboard RPC (SECURITY DEFINER),
  // so RLS on `records` stays airtight: only display name, avatar and
  // the computed metric ever leave the server.

  /// One row of the community board.
  /// [value] is % weight lost (metric 'pct_loss') or streak weeks
  /// (metric 'streak').
  static Future<List<LeaderboardEntry>> getLeaderboard(String metric,
      {int limit = 50}) async {
    if (!isReady || _userId == null) return [];
    try {
      final rows = await Supabase.instance.client.rpc('get_leaderboard',
          params: {'p_metric': metric, 'p_limit': limit});
      return (rows as List)
          .map((e) => LeaderboardEntry.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      lastError = _short(e);
      logEvent('leaderboard failed: $lastError');
      return [];
    }
  }

  /// Keeps the streak board fresh: called on every record save while
  /// logged in. Best-effort — a failure just means the board lags.
  static Future<void> pushStreak(int weeks) async {
    final uid = _userId;
    if (!isReady || uid == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'current_streak': weeks}).eq('user_id', uid);
    } catch (e) {
      logEvent('streak push failed: ${_short(e)}');
    }
  }

  // Plain-English hint for the most common setup mistakes, so a cryptic
  // network error points at the actual fix.
  static String? hintFor(String error) {
    if (error.contains('Failed host lookup')) {
      return 'The server address looks wrong or has a typo. Check SUPABASE_URL '
          'in GitHub Secrets, then rebuild the APK and reinstall — the address '
          'is baked into the build.';
    }
    if (error.contains('No host specified in URI eyJ')) {
      return 'SUPABASE_URL seems to hold the API key instead of the URL — '
          'the two secrets may be swapped.';
    }
    return null;
  }

  // One-line status for the UI, in the app locale.
  static String describe(List<BmiRecord> records, {String locale = 'en'}) {
    switch (state) {
      case SyncState.notConfigured:
        return txl(locale, 'sync_not_configured');
      case SyncState.error:
        if (lastError.isNotEmpty) return lastError;
        return txl(locale, 'sync_no_connect');
      case SyncState.ready:
        final n = pendingCount(records);
        if (n == 0) {
          return txl(locale, 'sync_ok');
        }
        // Indonesian has no plural; English needs "1 entry" vs "2 entries".
        if (locale == 'en') {
          return '$n ${n == 1 ? 'entry' : 'entries'} waiting to upload';
        }
        return txl(locale, 'sync_pending', {'n': n});
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bmi_record.dart';

// Cloud backup state, shown in the UI so it's never a mystery.
enum SyncState {
  // SUPABASE_URL / SUPABASE_ANON_KEY were empty at build time.
  notConfigured,

  // Signed in anonymously, ready to push.
  ready,

  // Last init or push failed. See [CloudSync.lastError].
  error,
}

// Backs records up to Supabase. Uses anonymous sign-in, so each device
// gets its own identity with no login screen. Row-level security in the
// database keeps every user to their own rows.
//
// Unlike the first version, this one doesn't fail silently:
// - it exposes its status + last error for the UI,
// - it remembers which records made it up, and retries the rest
//   automatically next launch.
class CloudSync {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _kSyncedIds = 'raga.synced_ids';

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static SyncState state = SyncState.notConfigured;
  static String lastError = '';
  static SharedPreferences? _prefs;
  static final Set<String> _syncedIds = {};

  static bool get isReady => state == SyncState.ready;

  static String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  // Records saved locally that haven't made it to the cloud yet.
  static int pendingCount(List<BmiRecord> records) =>
      records.where((r) => !_syncedIds.contains(r.id)).length;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _syncedIds.addAll(_prefs!.getStringList(_kSyncedIds) ?? const []);
    if (!isConfigured) {
      state = SyncState.notConfigured;
      lastError =
          'SUPABASE_URL / SUPABASE_ANON_KEY is empty (check GitHub Secrets and rebuild).';
      return;
    }
    try {
      await Supabase.initialize(url: _url, publishableKey: _anonKey);
      // Needs "Allow anonymous sign-ins" turned on in the Supabase dashboard.
      await Supabase.instance.client.auth.signInAnonymously();
      state = SyncState.ready;
      lastError = '';
    } catch (e) {
      state = SyncState.error;
      lastError = _short(e);
    }
  }

  // Pushes every local record that hasn't been uploaded yet. Runs at
  // startup, and can be triggered by hand from the Profile screen.
  static Future<void> syncPending(List<BmiRecord> records) async {
    if (!isReady) return;
    for (final r in records) {
      if (_syncedIds.contains(r.id)) continue;
      await pushRecord(r);
    }
  }

  // Pushes one record. Never throws to the caller, but records the
  // error in [lastError] so the UI can show it.
  static Future<void> pushRecord(BmiRecord record) async {
    if (!isReady) return;
    final uid = _userId;
    if (uid == null) {
      state = SyncState.error;
      lastError = 'Supabase anonymous session is gone (try restarting the app).';
      return;
    }
    try {
      await Supabase.instance.client
          .from('bmi_records')
          .upsert(record.toCloudJson(uid));
      _syncedIds.add(record.id);
      await _prefs?.setStringList(_kSyncedIds, _syncedIds.toList());
      lastError = '';
    } catch (e) {
      state = SyncState.error;
      lastError = _short(e);
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
  // Shown in the UI so a wrong/old value is visible immediately.
  static String get configuredHost {
    if (_url.isEmpty) return '(not set)';
    try {
      final h = Uri.parse(_url).host;
      return h.isEmpty ? '(invalid)' : h;
    } catch (_) {
      return '(invalid)';
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

  // One-line status for the UI.
  static String describe(List<BmiRecord> records) {
    switch (state) {
      case SyncState.notConfigured:
        return 'Not set up';
      case SyncState.error:
        return lastError.isEmpty ? "Couldn't connect" : lastError;
      case SyncState.ready:
        final n = pendingCount(records);
        return n == 0
            ? 'Connected — everything is synced'
            : '$n ${n == 1 ? 'entry' : 'entries'} waiting to upload';
    }
  }
}

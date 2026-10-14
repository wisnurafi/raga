import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bmi_record.dart';

/// Status sinkronisasi cloud yang bisa ditampilkan ke pengguna.
enum SyncState {
  /// dart-define SUPABASE_URL / SUPABASE_ANON_KEY kosong.
  notConfigured,

  /// Terhubung dan siap (anon sign-in sukses).
  ready,

  /// Gagal init / gagal push terakhir. Lihat [CloudSync.lastError].
  error,
}

/// Sinkronisasi cloud ke Supabase, memakai *anonymous auth*: tiap perangkat
/// otomatis dapat identitas unik tanpa layar login. RLS di database membatasi
/// tiap user hanya bisa membaca/menulis datanya sendiri.
///
/// Berbeda dari versi lama yang gagal diam-diam, versi ini:
/// - menyimpan status + pesan error terakhir agar bisa ditampilkan di UI,
/// - mencatat id record yang sudah terkirim, dan mengirim ulang yang
///   tertunda saat aplikasi dibuka (retry otomatis).
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

  /// Jumlah record lokal yang belum terkirim ke cloud.
  static int pendingCount(List<BmiRecord> records) =>
      records.where((r) => !_syncedIds.contains(r.id)).length;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _syncedIds.addAll(_prefs!.getStringList(_kSyncedIds) ?? const []);
    if (!isConfigured) {
      state = SyncState.notConfigured;
      lastError =
          'SUPABASE_URL / SUPABASE_ANON_KEY kosong (cek GitHub Secrets & build ulang).';
      return;
    }
    try {
      await Supabase.initialize(url: _url, publishableKey: _anonKey);
      // Butuh "Allow anonymous sign-ins" aktif di dashboard Supabase.
      await Supabase.instance.client.auth.signInAnonymously();
      state = SyncState.ready;
      lastError = '';
    } catch (e) {
      state = SyncState.error;
      lastError = _short(e);
    }
  }

  /// Kirim ulang semua record lokal yang belum terkirim. Dipanggil saat
  /// aplikasi dibuka, dan bisa dipicu manual dari layar Profil.
  static Future<void> syncPending(List<BmiRecord> records) async {
    if (!isReady) return;
    for (final r in records) {
      if (_syncedIds.contains(r.id)) continue;
      await pushRecord(r);
    }
  }

  /// Kirim satu record ke cloud. Tidak melempar error ke pemanggil,
  /// tapi mencatatnya di [lastError] agar bisa ditampilkan.
  static Future<void> pushRecord(BmiRecord record) async {
    if (!isReady) return;
    final uid = _userId;
    if (uid == null) {
      state = SyncState.error;
      lastError = 'Sesi anonim Supabase hilang (coba restart aplikasi).';
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

  /// Pesan error yang aman ditampilkan (tanpa secret / URL).
  static String _short(Object e) {
    final s = e.toString();
    // Potong stack trace & prefix exception yang berisik.
    final oneLine = s.split('\n').first;
    final cleaned = oneLine
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^PostgrestException[^:]*:\s*'), '');
    return cleaned.length > 140 ? '${cleaned.substring(0, 140)}…' : cleaned;
  }

  /// Ringkasan status satu baris untuk UI.
  static String describe(List<BmiRecord> records) {
    switch (state) {
      case SyncState.notConfigured:
        return 'Belum dikonfigurasi';
      case SyncState.error:
        return lastError.isEmpty ? 'Gagal terhubung' : lastError;
      case SyncState.ready:
        final n = pendingCount(records);
        return n == 0 ? 'Terhubung — semua data tersinkron' : '$n data menunggu dikirim';
    }
  }
}

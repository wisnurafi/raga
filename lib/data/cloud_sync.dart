import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bmi_record.dart';

/// Sinkronisasi cloud ke Supabase. Sepenuhnya opsional:
/// - Tanpa `--dart-define` SUPABASE_URL / SUPABASE_ANON_KEY, aplikasi jalan
///   100% lokal dan semua pemanggilan di sini jadi no-op.
/// - Semua error jaringan ditelan diam-diam agar tidak pernah mengganggu UX.
///
/// Memakai *anonymous auth*: tiap perangkat otomatis dapat identitas unik
/// tanpa layar login. RLS di database membatasi tiap user hanya bisa
/// membaca/menulis datanya sendiri.
class CloudSync {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static bool _ready = false;

  static Future<void> init() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(url: _url, publishableKey: _anonKey);
      // Butuh "Allow anonymous sign-ins" aktif di dashboard Supabase.
      await Supabase.instance.client.auth.signInAnonymously();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  /// Kirim satu record ke cloud. Fire-and-forget: kegagalan tidak
  /// melempar error ke pemanggil.
  static Future<void> pushRecord(BmiRecord record) async {
    if (!_ready) return;
    final uid = _userId;
    if (uid == null) return;
    try {
      await Supabase.instance.client
          .from('bmi_records')
          .upsert(record.toCloudJson(uid));
    } catch (_) {
      // Abaikan: data lokal tetap jadi sumber kebenaran.
    }
  }
}

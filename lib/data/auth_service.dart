import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_sync.dart';

// Optional Google account layer. Everything anonymous keeps working
// exactly as before — this only adds an account identity on top, which
// later unlocks account-bound features (leaderboard, Wrapped).
//
// Flow notes:
// - google_sign_in 7.x: singleton, initialize() exactly once (memoized
//   here), authenticate() throws GoogleSignInException(canceled) when
//   the user dismisses the picker.
// - The Supabase session persists automatically, so a Google login
//   survives cold starts — which is why CloudSync.init() no longer
//   signs in anonymously when a session already exists.
// - Sign-out drops back to an anonymous session; local data is
//   deliberately left alone (wiping is only ever via the explicit
//   wipe button).
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // Web OAuth client id from the Google Cloud Console, baked in at build
  // time (--dart-define=GOOGLE_WEB_CLIENT_ID). Empty until Wisnu creates
  // the OAuth client + secret and rebuilds — the sign-in button then
  // fails with a friendly message instead of a native crash.
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  bool _googleReady = false;
  StreamSubscription<AuthState>? _sub;

  String? _userId;
  String? _displayName;
  String? _avatarUrl;
  String? _email;
  bool _leaderboardOptIn = false;

  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;

  /// Community leaderboard participation. Strictly opt-in, default off.
  bool get leaderboardOptIn => _leaderboardOptIn;

  /// Flips the opt-in flag on the profiles row. Returns false when the
  /// write failed (the toggle stays off).
  Future<bool> setLeaderboardOptIn(bool v) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _db
          .from('profiles')
          .update({'leaderboard_opt_in': v}).eq('user_id', uid);
      _leaderboardOptIn = v;
      notifyListeners();
      return true;
    } catch (e) {
      CloudSync.logEvent('auth: opt-in update failed: $e');
      return false;
    }
  }

  /// Display name: the profiles row wins (the user may have edited it),
  /// Google's metadata is the fallback. Null when logged out — the UI
  /// falls back to a localized placeholder.
  String? get displayName => _displayName;

  /// Custom uploaded photo, else the Google avatar. Null when logged out.
  String? get avatarUrl => _avatarUrl;
  String? get email => _email;

  static Future<void> init() async {
    if (!CloudSync.isConfigured) return;
    final self = AuthService.instance;
    self._sub =
        _db.auth.onAuthStateChange.listen((data) async {
      await self._refreshFromUser(data.session?.user);
    });
    await self._refreshFromUser(_db.auth.currentUser);
  }

  Future<void> _refreshFromUser(User? user) async {
    if (user == null || user.isAnonymous) {
      _userId = null;
      _displayName = null;
      _avatarUrl = null;
      _email = null;
      _leaderboardOptIn = false;
      notifyListeners();
      return;
    }
    _userId = user.id;
    _email = user.email;
    final meta = user.userMetadata;
    _displayName =
        (meta?['full_name'] ?? meta?['name'])?.toString();
    _avatarUrl = meta?['avatar_url']?.toString();
    try {
      final row = await _db
          .from('profiles')
          .select('display_name, avatar_url, leaderboard_opt_in')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row != null) {
        final m = Map<String, dynamic>.from(row as Map);
        final dn = (m['display_name'] as String?)?.trim();
        if (dn != null && dn.isNotEmpty) _displayName = dn;
        final av = m['avatar_url'] as String?;
        if (av != null && av.isNotEmpty) _avatarUrl = av;
        _leaderboardOptIn = m['leaderboard_opt_in'] == true;
      }
    } catch (e) {
      CloudSync.logEvent('auth: profile row read failed: $e');
    }
    CloudSync.logEvent('auth: session for $_userId');
    notifyListeners();
  }

  /// google_sign_in demands initialize() exactly once before any other
  /// call — memoized here, and done lazily on first sign-in (never on
  /// the boot path, so it can't hang the splash).
  Future<void> _ensureGoogleInit() async {
    if (_googleReady) return;
    if (_webClientId.isEmpty) {
      throw const AuthException('not-configured');
    }
    await GoogleSignIn.instance
        .initialize(serverClientId: _webClientId);
    _googleReady = true;
  }

  /// Native Google sign-in, then a Supabase session via id token.
  /// Returns the user, or null when the user cancelled the picker.
  /// Throws AuthException('not-configured' | 'no-id-token') for the
  /// known setup failures so the UI can localize them.
  Future<User?> signInWithGoogle() async {
    if (!CloudSync.isConfigured) {
      throw const AuthException('not-configured');
    }
    await _ensureGoogleInit();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('no-id-token');
    }
    String? accessToken;
    try {
      final authz = await account.authorizationClient
          .authorizationForScopes(const []);
      accessToken = authz?.accessToken;
    } catch (_) {
      // The id token alone is enough for Supabase; the access token is
      // a bonus (lets Supabase call Google APIs on our behalf later).
    }
    final res = await _db.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    if (res.user == null) {
      throw const AuthException('no-user');
    }
    // Refresh synchronously: the onAuthStateChange listener fires async
    // and callers (ensureProfileRow) need _userId set immediately.
    await _refreshFromUser(res.user);
    return res.user;
  }

  /// Creates the profiles row on first login; returns true when the row
  /// was just created. Never overwrites a name/photo the user already
  /// edited — existing rows are left alone.
  Future<bool> ensureProfileRow() async {
    final uid = _userId;
    if (uid == null) return false;
    final existing = await _db
        .from('profiles')
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) return false;
    final meta = _db.auth.currentUser?.userMetadata;
    await _db.from('profiles').insert({
      'user_id': uid,
      'display_name':
          ((meta?['full_name'] ?? meta?['name'])?.toString() ?? '')
              .trim(),
      'avatar_url': meta?['avatar_url']?.toString(),
    });
    await _refreshFromUser(_db.auth.currentUser);
    CloudSync.logEvent('auth: profiles row created');
    return true;
  }

  Future<bool> setDisplayName(String name) async {
    final uid = _userId;
    if (uid == null) return false;
    final clean = name.trim();
    if (clean.isEmpty) return false;
    try {
      await _db
          .from('profiles')
          .update({'display_name': clean})
          .eq('user_id', uid);
      _displayName = clean;
      notifyListeners();
      return true;
    } catch (e) {
      CloudSync.logEvent('auth: setDisplayName failed: $e');
      return false;
    }
  }

  /// Uploads a JPEG to `avatars/<uid>/avatar.jpg` (upsert) and stores the
  /// public URL on the profile row. Returns the URL, or null on failure.
  /// The URL carries a cache-busting query param because the path never
  /// changes between uploads.
  Future<String?> uploadAvatar(Uint8List bytes) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final path = '$uid/avatar.jpg';
      await _db.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
      final base = _db.storage.from('avatars').getPublicUrl(path);
      final url = '$base?v=${DateTime.now().millisecondsSinceEpoch}';
      await _db
          .from('profiles')
          .update({'avatar_url': url})
          .eq('user_id', uid);
      _avatarUrl = url;
      notifyListeners();
      CloudSync.logEvent('auth: avatar uploaded');
      return url;
    } catch (e) {
      CloudSync.logEvent('auth: avatar upload failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _db.auth.signOut();
    // Back to anonymous: the backup-code machinery keeps working and the
    // app stays fully usable. Local data is deliberately left alone.
    try {
      await _db.auth.signInAnonymously();
    } catch (e) {
      CloudSync.logEvent('auth: re-anon after sign-out failed: $e');
    }
    await _refreshFromUser(_db.auth.currentUser);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

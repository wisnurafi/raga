import '../core/bmi.dart';
import '../core/ids.dart';

// One BMI result saved to history.
class BmiRecord {
  final String id;
  final String profileId;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final BmiCategory category;
  final DateTime createdAt;

  // Computes the BMI once and derives the category from it. A factory
  // because an initializer list can't reuse the field being initialized.
  factory BmiRecord({
    String? id,
    required String profileId,
    required double heightCm,
    required double weightKg,
    DateTime? createdAt,
  }) {
    final bmi = calcBmi(weightKg: weightKg, heightCm: heightCm);
    return BmiRecord._raw(
      id: id ?? newId(),
      profileId: profileId,
      heightCm: heightCm,
      weightKg: weightKg,
      bmi: bmi,
      category: categoryOf(bmi),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  BmiRecord._raw({
    required this.id,
    required this.profileId,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.category,
    required this.createdAt,
  });

  /// Copy with a new id. Used by the backup restamp healer: a row owned by
  /// a previous auth identity can't be updated (RLS 42501), so it's
  /// re-inserted as a fresh row and the local record adopts the new id.
  BmiRecord copyWith({String? id}) => BmiRecord._raw(
        id: id ?? this.id,
        profileId: profileId,
        heightCm: heightCm,
        weightKg: weightKg,
        bmi: bmi,
        category: category,
        createdAt: createdAt,
      );

  factory BmiRecord.fromJson(Map<String, dynamic> j) {
    final bmi = (j['bmi'] as num).toDouble();
    return BmiRecord._raw(
      id: j['id'] as String,
      profileId: j['profileId'] as String,
      heightCm: (j['heightCm'] as num).toDouble(),
      weightKg: (j['weightKg'] as num).toDouble(),
      bmi: bmi,
      category: categoryOf(bmi),
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'bmi': bmi,
        'createdAt': createdAt.toIso8601String(),
      };

  // Payload for Supabase (column names match the SQL schema in the README).
  // The backup code ties rows to a restorable identity: anonymous sign-ins
  // get a fresh user_id on every install, but the code survives in the
  // user's hands.
  //
  // client_id is the stable upsert key: pushRecord upserts with
  // onConflict: 'client_id', so a retry after a crash between a successful
  // upsert and the _syncedIds write updates the row instead of inserting a
  // duplicate. (Supabase migration 20261015_client_id_bmi_records.sql adds
  // the UNIQUE column — apply it in the dashboard before installing a
  // build with this code, otherwise pushes fail until the column exists.)
  Map<String, dynamic> toCloudJson(String userId, String? backupCode) => {
        'client_id': id,
        'user_id': userId,
        'profile_id': profileId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'category': category.name,
        'created_at': createdAt.toUtc().toIso8601String(), // timestamptz reads offset-less literals as UTC
        'backup_code': backupCode,
      };

  // A row read back through the restore_backup() RPC. The stable
  // client_id becomes the local id when present (rows pushed by recent
  // app versions carry it); older rows fall back to the cloud uuid.
  // Either way the id is stable across restores, so merges can dedupe on
  // it and restored rows are never re-pushed (they're marked synced
  // right after a restore).
  factory BmiRecord.fromCloudJson(Map<String, dynamic> j) {
    final bmi = (j['bmi'] as num).toDouble();
    return BmiRecord._raw(
      id: (j['client_id'] as String?) ?? (j['id'] as String),
      profileId: j['profile_id'] as String,
      heightCm: (j['height_cm'] as num).toDouble(),
      weightKg: (j['weight_kg'] as num).toDouble(),
      bmi: bmi,
      category: categoryOf(bmi),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(), // wall-clock for streak/history grouping
    );
  }

  // Payload for the per-account `records` table (logged-in mode). Same
  // idempotency contract as toCloudJson: pushRecord upserts with
  // onConflict: 'client_id'. Requires migration
  // 20261016_auth_tables.sql applied.
  Map<String, dynamic> toUserJson(String userId) => {
        'client_id': id,
        'user_id': userId,
        'profile_id': profileId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'category': category.name,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  // A row read back from the per-account `records` table. The stable
  // client_id becomes the local id (falling back to the cloud uuid),
  // so a record keeps one identity on every device and merges never
  // duplicate it.
  factory BmiRecord.fromUserJson(Map<String, dynamic> j) {
    final bmi = (j['bmi'] as num).toDouble();
    return BmiRecord._raw(
      id: (j['client_id'] as String?) ?? (j['id'] as String),
      profileId: j['profile_id'] as String,
      heightCm: (j['height_cm'] as num).toDouble(),
      weightKg: (j['weight_kg'] as num).toDouble(),
      bmi: bmi,
      category: categoryOf(bmi),
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(), // wall-clock for streak/history grouping
    );
  }
}

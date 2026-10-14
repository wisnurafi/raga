import 'dart:math';
import '../core/bmi.dart';

// One BMI result saved to history.
class BmiRecord {
  final String id;
  final String profileId;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final BmiCategory category;
  final DateTime createdAt;

  BmiRecord({
    String? id,
    required this.profileId,
    required this.heightCm,
    required this.weightKg,
    DateTime? createdAt,
  })  : id = id ?? _newId(),
        bmi = calcBmi(weightKg: weightKg, heightCm: heightCm),
        category = categoryOf(calcBmi(weightKg: weightKg, heightCm: heightCm)),
        createdAt = createdAt ?? DateTime.now();

  BmiRecord._raw({
    required this.id,
    required this.profileId,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.category,
    required this.createdAt,
  });

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

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
  Map<String, dynamic> toCloudJson(String userId, String? backupCode) => {
        'user_id': userId,
        'profile_id': profileId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'category': category.name,
        'created_at': createdAt.toIso8601String(),
        'backup_code': backupCode,
      };

  // A row read back through the restore_backup() RPC. The cloud uuid
  // becomes the local id, so restored rows are never re-pushed.
  factory BmiRecord.fromCloudJson(Map<String, dynamic> j) {
    final bmi = (j['bmi'] as num).toDouble();
    return BmiRecord._raw(
      id: j['id'] as String,
      profileId: j['profile_id'] as String,
      heightCm: (j['height_cm'] as num).toDouble(),
      weightKg: (j['weight_kg'] as num).toDouble(),
      bmi: bmi,
      category: categoryOf(bmi),
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

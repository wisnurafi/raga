import 'dart:math';
import '../core/bmi.dart';

/// Satu hasil perhitungan BMI yang tersimpan di riwayat.
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

  /// Payload untuk Supabase (nama kolom mengikuti schema SQL di README).
  Map<String, dynamic> toCloudJson(String userId) => {
        'user_id': userId,
        'profile_id': profileId,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bmi,
        'category': category.name,
        'created_at': createdAt.toIso8601String(),
      };
}

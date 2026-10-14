import 'dart:math';

// A user profile. One device can hold several (family members, etc.)
// — picked via the chips on the main screen.
class Profile {
  final String id;
  final String name;
  final bool isMale;
  final int age;
  final double heightCm;
  final double weightKg;

  Profile({
    String? id,
    required this.name,
    this.isMale = true,
    this.age = 21,
    this.heightCm = 170,
    this.weightKg = 65,
  }) : id = id ?? _newId();

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Profile copyWith({
    String? name,
    bool? isMale,
    int? age,
    double? heightCm,
    double? weightKg,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      isMale: isMale ?? this.isMale,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        isMale: j['isMale'] as bool? ?? true,
        age: (j['age'] as num?)?.toInt() ?? 21,
        heightCm: (j['heightCm'] as num?)?.toDouble() ?? 170,
        weightKg: (j['weightKg'] as num?)?.toDouble() ?? 65,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isMale': isMale,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
      };
}

import 'avatar_manifest.dart';

// Per-profile avatar data models. Level/XP are always DERIVED from the
// XP ledger — never stored as raw numbers that could drift.

/// What the user's avatar looks like. Values are manifest ids: skin and
/// shirt keys from the palettes, a hair style id, a hairColor key, and
/// optional accessory / frame item ids.
class AvatarConfig {
  final String skin;
  final String hair;
  final String hairColor;
  final String shirt;
  final String? accessory;
  final String? frame;

  const AvatarConfig({
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.shirt,
    required this.accessory,
    required this.frame,
  });

  /// A fresh profile starts exactly here — no extra onboarding steps.
  factory AvatarConfig.defaults(AvatarManifest manifest) {
    final d = manifest.defaults;
    return AvatarConfig(
      skin: d.skin,
      hair: d.hair,
      hairColor: d.hairColor,
      shirt: d.shirt,
      accessory: d.accessory,
      frame: d.frame,
    );
  }

  /// Template variables for resolving manifest asset paths
  /// (see [AvatarItem.resolveAssets]).
  Map<String, String> get templateVars => {'hairColor': hairColor};

  AvatarConfig copyWith({
    String? skin,
    String? hair,
    String? hairColor,
    String? shirt,
    String? accessory,
    String? frame,
    bool clearAccessory = false,
    bool clearFrame = false,
  }) {
    return AvatarConfig(
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      hairColor: hairColor ?? this.hairColor,
      shirt: shirt ?? this.shirt,
      accessory: clearAccessory ? null : (accessory ?? this.accessory),
      frame: clearFrame ? null : (frame ?? this.frame),
    );
  }

  Map<String, dynamic> toJson() => {
        'skin': skin,
        'hair': hair,
        'hairColor': hairColor,
        'shirt': shirt,
        'accessory': accessory,
        'frame': frame,
      };

  factory AvatarConfig.fromJson(Map<String, dynamic> j) => AvatarConfig(
        skin: j['skin'] as String,
        hair: j['hair'] as String,
        hairColor: j['hairColor'] as String,
        shirt: j['shirt'] as String,
        accessory: j['accessory'] as String?,
        frame: j['frame'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      skin == other.skin &&
      hair == other.hair &&
      hairColor == other.hairColor &&
      shirt == other.shirt &&
      accessory == other.accessory &&
      frame == other.frame;

  @override
  int get hashCode => Object.hash(
      skin, hair, hairColor, shirt, accessory, frame);
}

/// One XP grant in a profile's ledger.
///
/// Uniqueness is (profileId, type, key): storing the same event twice
/// must never grant XP twice. Key conventions (owned by the progress
/// service): daily_record/scheduled_weigh use the calendar day
/// 'yyyy-MM-dd'; streak_milestone uses `<days>-<streakStartDay>`;
/// profile_setup_complete uses 'setup'; goal_set/goal_reached use the
/// target weight value; weekly_wrapped_viewed uses the ISO week key.
class XpEvent {
  final String profileId;
  final String type;
  final String key;
  final int amount;
  final DateTime date;

  const XpEvent({
    required this.profileId,
    required this.type,
    required this.key,
    required this.amount,
    required this.date,
  });

  /// The idempotency identity of this grant.
  String get uid => '$profileId|$type|$key';

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'type': type,
        'key': key,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory XpEvent.fromJson(Map<String, dynamic> j) => XpEvent(
        profileId: j['profileId'] as String,
        type: j['type'] as String,
        key: j['key'] as String,
        amount: (j['amount'] as num).toInt(),
        date: DateTime.parse(j['date'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is XpEvent &&
      profileId == other.profileId &&
      type == other.type &&
      key == other.key &&
      amount == other.amount &&
      date == other.date;

  @override
  int get hashCode =>
      Object.hash(profileId, type, key, amount, date);
}

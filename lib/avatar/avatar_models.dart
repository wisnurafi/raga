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

/// All avatar data of one profile. Level and XP are always derived from
/// [ledger] — never stored as raw numbers. Everything here is namespaced
/// per profile: profile A can never affect profile B.
class AvatarProfileState {
  static const schemaVersion = 1;

  final AvatarConfig config;
  final List<XpEvent> ledger;
  final Set<String> unlockedItemIds;
  final Set<String> unlockSeenIds;
  final int bestStreak;
  final bool goalReached;
  final double? goalBaselineKg;

  const AvatarProfileState({
    required this.config,
    required this.ledger,
    required this.unlockedItemIds,
    required this.unlockSeenIds,
    required this.bestStreak,
    required this.goalReached,
    required this.goalBaselineKg,
  });

  /// A fresh profile: manifest defaults, empty ledger, the always-open
  /// items already marked seen (so a new profile doesn't drown in
  /// unlock notifications on day one).
  factory AvatarProfileState.initial(AvatarManifest manifest) {
    final open = <String>{
      for (final item in manifest.items)
        if (item.unlock == null) item.id,
    };
    return AvatarProfileState(
      config: AvatarConfig.defaults(manifest),
      ledger: const [],
      unlockedItemIds: open,
      unlockSeenIds: Set.of(open),
      bestStreak: 0,
      goalReached: false,
      goalBaselineKg: null,
    );
  }

  int get totalXp => ledger.fold(0, (a, e) => a + e.amount);

  bool hasEvent(String type, String key) =>
      ledger.any((e) => e.type == type && e.key == key);

  AvatarProfileState copyWith({
    AvatarConfig? config,
    List<XpEvent>? ledger,
    Set<String>? unlockedItemIds,
    Set<String>? unlockSeenIds,
    int? bestStreak,
    bool? goalReached,
    double? goalBaselineKg,
    bool clearGoalBaseline = false,
  }) {
    return AvatarProfileState(
      config: config ?? this.config,
      ledger: ledger ?? this.ledger,
      unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
      unlockSeenIds: unlockSeenIds ?? this.unlockSeenIds,
      bestStreak: bestStreak ?? this.bestStreak,
      goalReached: goalReached ?? this.goalReached,
      goalBaselineKg:
          clearGoalBaseline ? null : (goalBaselineKg ?? this.goalBaselineKg),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'config': config.toJson(),
        'ledger': ledger.map((e) => e.toJson()).toList(),
        'unlockedItemIds': unlockedItemIds.toList(),
        'unlockSeenIds': unlockSeenIds.toList(),
        'bestStreak': bestStreak,
        'goalReached': goalReached,
        'goalBaselineKg': goalBaselineKg,
      };

  factory AvatarProfileState.fromJson(Map<String, dynamic> j) {
    // schemaVersion is read by the storage layer for migrations; unknown
    // future versions must not crash old code paths that just need the
    // config — but this factory is strict: callers migrate first.
    final version = (j['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version != schemaVersion) {
      throw FormatException(
          'AvatarProfileState: unsupported schemaVersion $version');
    }
    return AvatarProfileState(
      config: AvatarConfig.fromJson(j['config'] as Map<String, dynamic>),
      ledger: ((j['ledger'] as List?) ?? const [])
          .map((e) => XpEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedItemIds: ((j['unlockedItemIds'] as List?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      unlockSeenIds: ((j['unlockSeenIds'] as List?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      bestStreak: (j['bestStreak'] as num?)?.toInt() ?? 0,
      goalReached: j['goalReached'] as bool? ?? false,
      goalBaselineKg: (j['goalBaselineKg'] as num?)?.toDouble(),
    );
  }
}

import 'detak_assets.dart';

/// A single logged Detak reaction (shown in "Reaksi terbaru").
/// The message is stored as a strings key so it follows locale changes;
/// [args] fills the key's {placeholders} at display time.
class DetakReaction {
  final DetakMood mood;
  final String messageKey;
  final Map<String, String> args;
  final DateTime ts;

  const DetakReaction({
    required this.mood,
    required this.messageKey,
    this.args = const {},
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'key': messageKey,
        'args': args,
        'ts': ts.toIso8601String(),
      };

  factory DetakReaction.fromJson(Map<String, dynamic> j) => DetakReaction(
        mood: DetakMood.values.byName(j['mood'] as String),
        messageKey: j['key'] as String,
        args: Map<String, String>.from(j['args'] as Map? ?? {}),
        ts: DateTime.parse(j['ts'] as String),
      );
}

/// Persistent companion state. Stored in LocalStore under 'raga.detak'.
class DetakState {
  String name;
  DetakColor color;
  DetakAccessory accessory;
  int level;
  int xpInLevel;
  DateTime? lastOpenDay;
  DateTime? lastLogDay;
  DateTime? lastGreetDay;
  final List<DetakReaction> reactions;
  bool notifFlavor;
  bool calmMode;
  final Map<String, List<String>> questsDone; // 'yyyy-MM-dd' -> ['log','trend']
  final Map<String, int> lastVariant; // message group -> last variant index
  /// Quest completion clock time ("07:12"), keyed by '$day:$quest'.
  final Map<String, String> questDoneAt;

  DetakState({
    this.name = 'Detak',
    this.color = DetakColor.lavender,
    this.accessory = DetakAccessory.none,
    this.level = 1,
    this.xpInLevel = 0,
    this.lastOpenDay,
    this.lastLogDay,
    this.lastGreetDay,
    List<DetakReaction>? reactions,
    this.notifFlavor = true,
    this.calmMode = false,
    Map<String, List<String>>? questsDone,
    Map<String, int>? lastVariant,
    Map<String, String>? questDoneAt,
  })  : reactions = reactions ?? [],
        questsDone = questsDone ?? {},
        lastVariant = lastVariant ?? {},
        questDoneAt = questDoneAt ?? {};

  DetakStage get stage => detakStageForLevel(level);
  int get xpNeeded => detakXpForLevel(level);
  double get progress =>
      xpNeeded <= 0 ? 0 : (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  int get xpRemaining => (xpNeeded - xpInLevel).clamp(0, xpNeeded);

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isQuestDone(DateTime day, String quest) =>
      questsDone[dayKey(day)]?.contains(quest) ?? false;

  void markQuest(DateTime day, String quest) {
    final k = dayKey(day);
    final list = questsDone.putIfAbsent(k, () => []);
    if (!list.contains(quest)) {
      list.add(quest);
      _stampQuest(day, quest);
    }
    // keep the map small: drop entries older than 8 days
    final cutoff = dayKey(day.subtract(const Duration(days: 8)));
    questsDone.removeWhere((key, _) => key.compareTo(cutoff) < 0);
  }

  /// Adds XP, carrying over across level-ups. Returns levels gained.
  int addXp(int n) {
    var gained = 0;
    xpInLevel += n;
    while (xpInLevel >= detakXpForLevel(level)) {
      xpInLevel -= detakXpForLevel(level);
      level++;
      gained++;
    }
    return gained;
  }

  void logReaction(
      DetakMood mood, String messageKey, DateTime ts,
      [Map<String, String> args = const {}]) {
    reactions.insert(
        0, DetakReaction(mood: mood, messageKey: messageKey, args: args, ts: ts));
    if (reactions.length > 20) reactions.removeRange(20, reactions.length);
  }

  String? questTime(DateTime day, String quest) =>
      questDoneAt['${dayKey(day)}:$quest'];

  void _stampQuest(DateTime day, String quest) {
    questDoneAt['${dayKey(day)}:$quest'] =
        '${day.hour.toString().padLeft(2, '0')}:'
        '${day.minute.toString().padLeft(2, '0')}';
    // keep small: drop stamps older than 8 days
    final cutoff = '${dayKey(day.subtract(const Duration(days: 8)))}:';
    questDoneAt.removeWhere((key, _) => key.compareTo(cutoff) < 0);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.name,
        'accessory': accessory.name,
        'level': level,
        'xpInLevel': xpInLevel,
        'lastOpenDay': lastOpenDay?.toIso8601String(),
        'lastLogDay': lastLogDay?.toIso8601String(),
        'lastGreetDay': lastGreetDay?.toIso8601String(),
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'notifFlavor': notifFlavor,
        'calmMode': calmMode,
        'questsDone': questsDone,
        'lastVariant': lastVariant,
        'questDoneAt': questDoneAt,
      };

  factory DetakState.fromJson(Map<String, dynamic> j) {
    DetakColor color = DetakColor.lavender;
    try {
      color = DetakColor.values.byName(j['color'] as String? ?? 'lavender');
    } catch (_) {}
    DetakAccessory accessory = DetakAccessory.none;
    try {
      accessory =
          DetakAccessory.values.byName(j['accessory'] as String? ?? 'none');
    } catch (_) {}
    final reactions = <DetakReaction>[];
    for (final r in (j['reactions'] as List? ?? [])) {
      try {
        reactions.add(
            DetakReaction.fromJson(Map<String, dynamic>.from(r as Map)));
      } catch (_) {}
    }
    final questsDone = <String, List<String>>{};
    for (final e in (Map<String, dynamic>.from(j['questsDone'] as Map? ?? {}))
        .entries) {
      questsDone[e.key] =
          (e.value as List).map((e) => e as String).toList();
    }
    DateTime? dt(String? s) => s == null ? null : DateTime.tryParse(s);
    return DetakState(
      name: (j['name'] as String?) ?? 'Detak',
      color: color,
      accessory: accessory,
      level: (j['level'] as num?)?.toInt() ?? 1,
      xpInLevel: (j['xpInLevel'] as num?)?.toInt() ?? 0,
      lastOpenDay: dt(j['lastOpenDay'] as String?),
      lastLogDay: dt(j['lastLogDay'] as String?),
      lastGreetDay: dt(j['lastGreetDay'] as String?),
      reactions: reactions,
      notifFlavor: (j['notifFlavor'] as bool?) ?? true,
      calmMode: (j['calmMode'] as bool?) ?? false,
      questsDone: questsDone,
      lastVariant:
          Map<String, int>.from(j['lastVariant'] as Map? ?? {}),
      questDoneAt:
          Map<String, String>.from(j['questDoneAt'] as Map? ?? {}),
    );
  }
}

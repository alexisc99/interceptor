import 'package:hive_flutter/hive_flutter.dart';

enum ChallengeType {
  math,
  puzzle,
  action,
  delay,
  mirror;

  String get storageValue => name;

  static ChallengeType fromStorage(String? value) {
    return ChallengeType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ChallengeType.math,
    );
  }

  /// Whether this type needs a runtime permission it might not have.
  bool get requiresCameraPermission => this == ChallengeType.mirror;
}

class TargetAppConfig {
  final String packageName;
  final String appName;
  final int graceMinutes;

  /// The challenge types eligible to be drawn when this app is opened. Never
  /// empty — one is picked at random (among those the user has granted any
  /// permission they require) each time the challenge triggers.
  final Set<ChallengeType> challengeTypes;

  /// When this app was first targeted. Used as the reference point for the
  /// "time saved" comparison (usage the week before vs the weeks since).
  final DateTime addedAt;

  TargetAppConfig({
    required this.packageName,
    required this.appName,
    this.graceMinutes = 5,
    Set<ChallengeType>? challengeTypes,
    DateTime? addedAt,
  })  : challengeTypes = (challengeTypes == null || challengeTypes.isEmpty)
            ? const {ChallengeType.math}
            : challengeTypes,
        addedAt = addedAt ?? DateTime.now();

  /// Note: addedAt is deliberately not editable — it always reflects when
  /// the app was first added, regardless of later config changes.
  TargetAppConfig copyWith({int? graceMinutes, Set<ChallengeType>? challengeTypes}) {
    return TargetAppConfig(
      packageName: packageName,
      appName: appName,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      challengeTypes: challengeTypes ?? this.challengeTypes,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'graceMinutes': graceMinutes,
        'challengeTypes': challengeTypes.map((t) => t.storageValue).toList(),
        'addedAt': addedAt.millisecondsSinceEpoch,
      };

  factory TargetAppConfig.fromMap(String packageName, Map map) {
    final addedAtMs = map['addedAt'] as int?;
    return TargetAppConfig(
      packageName: packageName,
      appName: map['appName'] as String? ?? packageName,
      graceMinutes: map['graceMinutes'] as int? ?? 5,
      challengeTypes: _readChallengeTypes(map),
      addedAt: addedAtMs != null ? DateTime.fromMillisecondsSinceEpoch(addedAtMs) : DateTime.now(),
    );
  }

  /// Reads the new plural `challengeTypes` list, falling back to the old
  /// singular `challengeType` string for configs saved before multi-select
  /// support was added.
  static Set<ChallengeType> _readChallengeTypes(Map map) {
    final list = map['challengeTypes'] as List?;
    if (list != null && list.isNotEmpty) {
      return list.map((v) => ChallengeType.fromStorage(v as String?)).toSet();
    }
    final legacy = map['challengeType'] as String?;
    if (legacy != null) return {ChallengeType.fromStorage(legacy)};
    return const {ChallengeType.math};
  }
}

/// Local (Hive-backed) store of which apps are targeted and their config.
/// This is the source of truth on the Dart side; changes must be pushed to
/// the native side via [InterceptionChannel] so the accessibility service
/// (which runs independently of any Flutter engine) can see them.
class AppConfigRepository {
  static const boxName = 'target_apps';

  static Future<void> init() => Hive.openBox(boxName);

  /// Re-reads the box from disk. The challenge overlay runs in its own
  /// Flutter engine/isolate (a separate ChallengeActivity) that can keep an
  /// already-open Box cached in memory across triggers if the Android
  /// process survives between them — so an edit made in the main engine
  /// (e.g. changing an app's selected challenge types) wouldn't be picked
  /// up there until the process happened to restart. Called at the start
  /// of every challenge trigger instead.
  static Future<void> reload() async {
    if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).close();
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  List<TargetAppConfig> getAll() {
    return _box.keys
        .map((key) => TargetAppConfig.fromMap(
              key as String,
              Map<String, dynamic>.from(_box.get(key) as Map),
            ))
        .toList()
      ..sort((a, b) => a.appName.compareTo(b.appName));
  }

  bool isTargeted(String packageName) => _box.containsKey(packageName);

  Future<void> upsert(TargetAppConfig config) => _box.put(config.packageName, config.toMap());

  Future<void> remove(String packageName) => _box.delete(packageName);
}
